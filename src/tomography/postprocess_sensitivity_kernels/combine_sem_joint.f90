!=====================================================================
!
!               S p e c f e m 3 D  V e r s i o n  3 . 0
!               ---------------------------------------
!
!     Main historical authors: Dimitri Komatitsch and Jeroen Tromp
!                              CNRS, France
!                       and Princeton University, USA
!                 (there are currently many more authors!)
!                           (c) October 2017
!
! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along
! with this program; if not, write to the Free Software Foundation, Inc.,
! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
!
!=====================================================================

! XCOMBINE_SEM
!
! USAGE
!   mpirun -np NPROC bin/xcombine_sem KERNEL_NAMES INPUT_FILE OUTPUT_DIR
!
!
! COMMAND LINE ARGUMENTS
!   KERNEL_NAMES           - one or more kernel names separated by commas
!   INPUT_FILE             - text file containing list of kernel directories
!   OUTPUT_PATH            - directory to which summed kernels are written
!
!
! DESCRIPTION
!   For each name in KERNEL_NAMES, sums kernels from directories specified in
!   INPUT_FILE. Writes the resulting sums to OUTPUT_DIR.
!
!   INPUT_FILE is a text file containing a list of absolute or relative paths to
!   kernel directories, one directory per line.
!
!   KERNEL_NAMES is comma-delimited list of kernel names,
!   e.g.'alpha_kernel,beta_kernel,rho_kernel'.
!
!   This program's primary use case is to sum kernels. It can be used though on
!   any scalar field of dimension (NGLLX,NGLLY,NGLLZ,NSPEC).
!
!   This is a parrallel program -- it must be invoked with mpirun or other
!   appropriate utility.  Operations are performed in embarassingly-parallel fashion.

program combine_sem

  use postprocess_par, only: MAX_STRING_LEN,MAX_KERNEL_PATHS,MAX_KERNEL_NAMES,&
                             IIN,myrank,sizeprocs,NGLOB,NSPEC

  use shared_parameters

  implicit none

  integer, parameter :: NARGS = 4
  integer, parameter :: MAX_DATASETS = 2

  character(len=MAX_STRING_LEN) :: &
    kernel_paths(MAX_KERNEL_PATHS, MAX_DATASETS), &
    meas_paths(MAX_KERNEL_PATHS, MAX_DATASETS), &
    kernel_names(MAX_KERNEL_NAMES), &
    kernel_names_comma_delimited, &
    dir_lists_comma_delimited, &
    meas_lists_comma_delimited
  character(len=MAX_STRING_LEN) :: sline,prname_lp,output_dir,filename,&
                                   fns_dir_list(MAX_KERNEL_NAMES), &
                                   fns_meas_list(MAX_KERNEL_NAMES)
  character(len=MAX_STRING_LEN) :: arg(NARGS)
  integer :: npath(MAX_DATASETS),nmeas_all(MAX_DATASETS),nker,nmeas,nset
  integer :: i,ier,iker,iset,ipath,ndummy
  double precision :: chi_dummy
  logical :: BROADCAST_AFTER_READ

  call init_mpi()
  call world_size(sizeprocs)
  call world_rank(myrank)

  if (myrank == 0) then
    write(*,*) 'Running XCOMBINE_SEM'
    write(*,*)
  endif
  call synchronize_all()

  ! check command line arguments
  if (command_argument_count() /= NARGS) then
    if (myrank == 0) then
      print *, 'USAGE: mpirun -np NPROC bin/xcombine_sem KERNEL_NAMES INPUT_FILE OUTPUT_DIR'
      stop ' Please check command line arguments'
    endif
  endif
  call synchronize_all()

  do i = 1, NARGS
    call get_command_argument(i,arg(i), status=ier)
  enddo

  read(arg(1),'(a)') kernel_names_comma_delimited
  read(arg(2),'(a)') dir_lists_comma_delimited
  read(arg(3),'(a)') meas_lists_comma_delimited
  read(arg(4),'(a)') output_dir

  ! parse names from KERNEL_NAMES
  call parse_kernel_names(kernel_names_comma_delimited,kernel_names,nker)
  call parse_kernel_names(dir_lists_comma_delimited,fns_dir_list,nset)
  call parse_kernel_names(meas_lists_comma_delimited,fns_meas_list,ndummy)
  if (myrank == 0) then
    if (.not. (nset == ndummy)) stop 'inconsist numbers of dir_list and meas_list'
  endif
  ! parse paths from INPUT_FILE
  do iset = 1, nset
  npath(iset)=0
  open(unit = IIN, file = trim(fns_dir_list(iset)), status = 'old',iostat = ier)
  if (ier /= 0) then
     print *,'Error opening ',trim(fns_dir_list(iset)), myrank
     stop 1
  endif
  do while (1 == 1)
     read(IIN,'(a)',iostat=ier) sline
     if (ier /= 0) exit
     npath(iset) = npath(iset)+1
     if (npath(iset) > MAX_KERNEL_PATHS) &
       stop 'Error number of paths exceeds MAX_KERNEL_PATHS'
     kernel_paths(npath(iset), iset) = sline
  enddo
  close(IIN)
  if (myrank == 0) then
    write(*,*) '  set ', iset, ' ' ,npath(iset),' events'
    write(*,*)
  endif
  ndummy = 0
  open(unit = IIN, file = trim(fns_meas_list(iset)), status = 'old',iostat = ier)
  if (ier /= 0) then
     print *,'Error opening ',trim(fns_meas_list(iset)), myrank
     stop 1
  endif
  do while (1 == 1)
     read(IIN,'(a)',iostat=ier) sline
     if (ier /= 0) exit
     ndummy = ndummy+1
     if (ndummy > MAX_KERNEL_PATHS) &
       stop 'Error number of paths exceeds MAX_KERNEL_PATHS'
     meas_paths(ndummy, iset) = sline
  enddo
  close(IIN)
  if (myrank == 0) then
    if (.not. (npath(iset) == ndummy)) &
      stop 'inconsist numbers of kernel paths and measurement paths'
  endif
  nmeas_all(iset) = 0
  do ipath = 1, npath(iset)
    filename = trim(meas_paths(ipath, iset)) // '/sum_chi'
    open(unit=IIN, file=trim(filename), form='formatted', status='old', &
         action='read', iostat=ier)
    read(IIN, *) chi_dummy
    read(IIN, *) nmeas
    close(IIN)
    if (myrank == 0) then
      print *, 'measurement path:', trim(meas_paths(ipath, iset))
      print *, '  nmeas = ', nmeas
    endif
    nmeas_all(iset) = nmeas_all(iset) + nmeas
  enddo
  if (myrank == 0) then
    print *, 'total number of measurements in dataset ', &
             iset, ': ', nmeas_all(iset)
  endif
  enddo

  ! read simulation parameters
  BROADCAST_AFTER_READ = .true.
  call read_parameter_file(myrank,BROADCAST_AFTER_READ)

  ! checks number of MPI processes
  if (sizeprocs /= NPROC) then
    if (myrank == 0) then
      print *
      print *,'Expected number of MPI processes: ', NPROC
      print *,'Actual number of MPI processes: ', sizeprocs
      print *
    endif
    call synchronize_all()
    stop 'Error wrong number of MPI processes'
  endif
  call synchronize_all()

  ! read mesh dimensions
  write(prname_lp,'(a,i6.6,a)') trim(LOCAL_PATH)//'/proc',myrank,'_'//'external_mesh.bin'
  open(unit=27,file=trim(prname_lp), &
          status='old',action='read',form='unformatted',iostat=ier)
  if (ier /= 0) then
    print *,'Error: could not open database '
    print *,'path: ',trim(prname_lp)
    stop 'Error reading external mesh file'
  endif
  read(27) NSPEC
  read(27) NGLOB
  close(27)
  call synchronize_all()

  ! sum kernels
  !if (myrank == 0) then
  !  print *,'summing kernels in: '
  !  print *,kernel_paths(1:npath(nset), 1:nset)
  !  print *
  !endif

  do iker=1,nker
      call combine_sem_array_joint(kernel_names(iker),kernel_paths(:,1:nset),&
                              output_dir,nmeas_all(1:nset), npath(1:nset), nset)
  enddo


  if (myrank == 0) write(*,*) 'done writing all arrays, see directory: ', output_dir
  call finalize_mpi()

end program combine_sem

!
!-------------------------------------------------------------------------------------------------
!

subroutine combine_sem_array_joint(kernel_name,kernel_paths,&
                                   output_dir,nmeas_all,npath,nset)

  use postprocess_par

  implicit none
  integer :: nset
  character(len=MAX_STRING_LEN) :: kernel_name,&
                                   kernel_paths(MAX_KERNEL_PATHS, nset)
  character(len=MAX_STRING_LEN) :: output_dir
  integer :: npath(nset), nmeas_all(nset)

  ! local parameters
  character(len=MAX_STRING_LEN*2) :: filename
  real(kind=CUSTOM_REAL), dimension(:,:,:,:),allocatable :: array,sum_arrays
  double precision :: norm,norm_sum
  integer :: iker,ier,iset

  allocate(array(NGLLX,NGLLY,NGLLZ,NSPEC),stat=ier)
  if (ier /= 0) call my_local_exit_MPI_without_rank('error allocating array 978')
  allocate(sum_arrays(NGLLX,NGLLY,NGLLZ,NSPEC),stat=ier)
  if (ier /= 0) call my_local_exit_MPI_without_rank('error allocating array 979')
  if (ier /= 0) stop 'Error allocating array'

 ! loop over kernel paths
  sum_arrays = 0._CUSTOM_REAL
  do iset = 1, nset
  do iker = 1, npath(iset)
    !if (myrank == 0) then
    !  write(*,*) 'reading in array for: ',trim(kernel_name)
    !  !write(*,*) '    ',iker, ' out of ', npath
    !endif

    ! read array
    array = 0._CUSTOM_REAL
    write(filename,'(a,i6.6,a)') &
      trim(kernel_paths(iker, iset)) //'/proc',myrank,'_'//trim(kernel_name)//'.bin'
    
    if (myrank == 0)then
      write(*,*) 'reading array: ', trim(filename)
    endif
    open(IIN,file=trim(filename),status='old',form='unformatted',action='read',iostat=ier)
    if (ier /= 0) then
      write(*,*) '  array not found: ',trim(filename)
      stop 'Error array file not found'
    endif
    read(IIN) array
    close(IIN)

    ! print array information
    norm = sum( array * array )
    call sum_all_dp(norm, norm_sum)
    if (myrank == 0) then
      print *,'  norm array: ',sqrt(norm_sum)
      print *
    endif

    ! keep track of sum
    sum_arrays = sum_arrays + array / (nmeas_all(iset) * 1.0)

  enddo
  enddo

  ! write sum
  if (myrank == 0) write(*,*) 'writing sum: ',trim(kernel_name)
  write(filename,'(a,i6.6,a)') trim(output_dir)//'/'//'proc',myrank,'_'//trim(kernel_name)//'.bin'
  open(IOUT,file=trim(filename),form='unformatted',status='unknown',action='write',iostat=ier)
  if (ier /= 0) then
    write(*,*) 'Error array not written:',trim(filename)
    stop 'Error array write'
  endif
  write(IOUT) sum_arrays
  close(IOUT)

  if (myrank == 0) write(*,*)
  deallocate(array,sum_arrays)

end subroutine combine_sem_array_joint

!
!-------------------------------------------------------------------------------------------------
!

! version without rank number printed in the error message

  subroutine my_local_exit_MPI_without_rank(error_msg)

  implicit none

  character(len=*) error_msg

! write error message to screen
  write(*,*) error_msg(1:len(error_msg))
  write(*,*) 'Error detected, aborting MPI...'

  stop 'Fatal error'

  end subroutine my_local_exit_MPI_without_rank

