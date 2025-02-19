program update_model_by_steplength
  use postprocess_par, only: MAX_KERNEL_NAMES
  use specfem_par
  implicit none
  integer, parameter :: NARGS = 7
  character(len=MAX_STRING_LEN) :: kernel_names(MAX_KERNEL_NAMES), &
                                   model_names(MAX_KERNEL_NAMES), &
                                   is_perturbation_str(MAX_KERNEL_NAMES)
  character(len=MAX_STRING_LEN) :: dir_in, dir_out, dir_kernel, &
                                   kernel_names_comma_delimited, &
                                   model_names_comma_delimited, model_name, &
                                   is_perturbation_comma_delimited
  character(len=MAX_STRING_LEN) :: filename
  character(len=MAX_STRING_LEN) :: arg(NARGS)

  integer :: nker, nmod, i, ier, imod
  real(kind=CUSTOM_REAL), dimension(:,:,:,:,:), allocatable :: &
                                   old_mod_array, new_mod_array, ker_array
  real(kind=CUSTOM_REAL) :: step_len
  logical :: BROADCAST_AFTER_READ
  real(kind=CUSTOM_REAL) :: max_val,min_val
  logical :: is_perturbation(MAX_KERNEL_NAMES)

  call init_mpi()
  call world_size(sizeprocs)
  call world_rank(myrank)

  call synchronize_all()

  do i = 1, NARGS
    call get_command_argument(i,arg(i), status=ier)
  enddo

  read(arg(1),'(a)') kernel_names_comma_delimited
  read(arg(2),'(a)') model_names_comma_delimited
  read(arg(3),'(a)') is_perturbation_comma_delimited
  read(arg(4),'(a)') dir_in
  read(arg(5),'(a)') dir_out
  read(arg(6),'(a)') dir_kernel
  read(arg(7),*) max_perturbation

  ! parse names from KERNEL_NAMES
  call parse_kernel_names(kernel_names_comma_delimited,kernel_names,nker)

  call parse_kernel_names(model_names_comma_delimited,model_names,nmod)
  call parse_kernel_names(is_perturbation_comma_delimited,is_perturbation_str,nker)
  do iker = 1, nker
    read(is_perturbation_str(iker), *) is_perturbation(iker)
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

  ! read the value of NSPEC_AB and NGLOB_AB because we need it to define some
  ! array sizes below
  call read_mesh_for_init()

  allocate(old_mod_array(NGLLX,NGLLY,NGLLZ,NSPEC_AB,nmod), stat=ier)
  allocate(new_mod_array(NGLLX,NGLLY,NGLLZ,NSPEC_AB,nmod), stat=ier)
  allocate(ker_array(NGLLX,NGLLY,NGLLZ,NSPEC_AB,nker), stat=ier)

  old_mod_array = 0._CUSTOM_REAL
  new_mod_array = 0._CUSTOM_REAL
  ker_array = 0._CUSTOM_REAL

  call read_kernel_from_path(dir_in,model_names,nmod,old_mod_array)
  if (myrank == 0) print *, 'Old model:'
  do imod = 1, nmod
    call min_all_cr(minval(old_mod_array(:,:,:,:,imod)),min_val)
    call max_all_cr(maxval(old_mod_array(:,:,:,:,imod)),max_val)
    if (myrank == 0) then
      print *, 'field ', trim(model_names(imod))
      print *, 'min:', min_val, 'max:', max_val
    endif
  enddo

  call read_kernel_from_path(dir_kernel,kernel_names,nker,ker_array)
  call max_all_all_cr(maxval(abs(ker_array(:,:,:,:,:))),max_val)
  !step_len = max_perturbation / max_val
  
  do iker = 1, nker
    if (is_perturbation(iker)) then
      new_mod_array(:,:,:,:,iker) = old_mod_array(:,:,:,:,iker) * &
                             exp(ker_array(:,:,:,:,iker) * step_len)
    else
      new_mod_array(:,:,:,:,iker) = old_mod_array(:,:,:,:,iker) + &
                             ker_array(:,:,:,:,iker) * step_len
    endif
  enddo

  if (myrank == 0) print *, 'New model:'
  do imod = 1, nmod
    call min_all_cr(minval(new_mod_array(:,:,:,:,imod)),min_val)
    call max_all_cr(maxval(new_mod_array(:,:,:,:,imod)),max_val)
    if (myrank == 0) then
      print *, 'field ', trim(model_names(imod))
      print *, 'min:', min_val, 'max:', max_val
    endif
  enddo

  if (myrank == 0) print *, 'Model update:'
  do imod = 1, nmod
    if (is_perturbation(imod)) then
      call min_all_cr(minval(new_mod_array(:,:,:,:,imod) / &
                           old_mod_array(:,:,:,:,imod) - 1.0),min_val)
      call max_all_cr(maxval(new_mod_array(:,:,:,:,imod) / &
                           old_mod_array(:,:,:,:,imod) - 1.0),max_val)
    else
      call min_all_cr(minval(new_mod_array(:,:,:,:,imod) - &
                           old_mod_array(:,:,:,:,imod)),min_val)
      call max_all_cr(maxval(new_mod_array(:,:,:,:,imod) - &
                           old_mod_array(:,:,:,:,imod)),max_val)
    endif
    if (myrank == 0) then
      print *, 'field ', trim(model_names(imod))
      print *, 'min:', min_val, 'max:', max_val
    endif
  enddo

  do imod = 1, nmod
    model_name = model_names(imod)
    write(filename,'(a,i6.6,a)') trim(dir_out) // &
                '/proc',myrank,'_'// trim(model_name)//'.bin'
    open(IOUT,file=trim(filename),form='unformatted',action='write',&
              status='unknown', iostat=ier)
    write(IOUT) new_mod_array(:,:,:,:,imod)
    close(IOUT)
  enddo

  deallocate(new_mod_array, old_mod_array, ker_array)

  call finalize_mpi()

end program update_model_by_steplength

subroutine read_kernel_from_path(kernel_path,kernel_names,nker,array)
  use postprocess_par, only: MAX_KERNEL_NAMES, MAX_KERNEL_PATHS
  use specfem_par, only: CUSTOM_REAL, NGLLX, NGLLY, NGLLZ, NSPEC_AB, &
                         MAX_STRING_LEN, IIN, myrank
  implicit none
  integer, intent(in) :: nker
  character(len=MAX_STRING_LEN), intent(in) :: kernel_path
  character(len=MAX_STRING_LEN), intent(in) :: kernel_names(MAX_KERNEL_NAMES)
  real(kind=CUSTOM_REAL), intent(out) :: array(NGLLX,NGLLY,NGLLZ,NSPEC_AB,nker)
  ! local variables
  integer :: iker, ier
  character(len=MAX_STRING_LEN) :: kernel_name, filename

  do iker = 1, nker
    kernel_name = kernel_names(iker)
    write(filename,'(a,i6.6,a)') trim(kernel_path) &
                           //'/proc',myrank,'_'//trim(kernel_name)//'.bin'
    open(IIN,file=trim(filename),status='old',form='unformatted',action='read',iostat=ier)
    if (ier /= 0) then
      write(*,*) '  array not found: ',trim(filename)
      stop 'Error array file not found'
    endif
    read(IIN) array(:,:,:,:,iker)
    close(IIN)
  enddo

end subroutine read_kernel_from_path
