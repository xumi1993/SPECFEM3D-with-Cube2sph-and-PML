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

 subroutine read_parameters()

! reads and checks user input parameters

  use generate_databases_par

  implicit none

  logical :: BROADCAST_AFTER_READ

! reads Par_file
  BROADCAST_AFTER_READ = .true.
  call read_parameter_file(myrank,BROADCAST_AFTER_READ)

! check that the code is running with the requested nb of processes
  if (sizeprocs /= NPROC) then
    if (myrank == 0) then
      write(IMAIN,*) 'error: number of processors supposed to run on: ',NPROC
      write(IMAIN,*) 'error: number of MPI processors actually run on: ',sizeprocs
      print *
      print *, 'error generate_databases: number of processors supposed to run on: ',NPROC
      print *, 'error generate_databases: number of MPI processors actually run on: ',sizeprocs
      print *
      if (NPROC > 1 .and. sizeprocs == 1) then
        print *,'this might be the serial version, please check if you have compiled all executables with MPI support...'
        print *
      endif
    endif
    call exit_MPI(myrank,'wrong number of MPI processes')
  endif

! there would be a problem with absorbing boundaries for different NGLLX,NGLLY,NGLLZ values
! just to be sure for now..
  if (STACEY_ABSORBING_CONDITIONS) then
    if (NGLLX /= NGLLY .and. NGLLY /= NGLLZ) &
      call exit_MPI(myrank,'must have NGLLX = NGLLY = NGLLZ for external meshes')
  endif

! info about external mesh simulation
  if (myrank == 0) then
    write(IMAIN,*) 'This is process ',myrank
    write(IMAIN,*) 'There are ',sizeprocs,' MPI processes'
    write(IMAIN,*) 'Processes are numbered from 0 to ',sizeprocs-1
    write(IMAIN,*)
    write(IMAIN,*) 'There is a total of ',NPROC,' slices'
    write(IMAIN,*)
    write(IMAIN,*) 'NGLLX = ',NGLLX
    write(IMAIN,*) 'NGLLY = ',NGLLY
    write(IMAIN,*) 'NGLLZ = ',NGLLZ

    write(IMAIN,*)
    write(IMAIN,*) 'Shape functions defined by NGNOD = ',NGNOD,' control nodes'
    write(IMAIN,*) 'Surface shape functions defined by NGNOD2D = ',NGNOD2D,' control nodes'
    write(IMAIN,*) 'Beware! Curvature (i.e. HEX27 elements) is not handled by our internal mesher'
    write(IMAIN,*)

! check that the constants.h file is correct
    if (NGNOD /= 8 .and. NGNOD /= 27) then
       stop 'elements should have 8 or 27 control nodes, please modify NGNOD in Par_file'
    endif

    write(IMAIN,'(a)',advance='no') ' velocity model: '

    select case (IMODEL)
    case (IMODEL_DEFAULT )
    write(IMAIN,'(a)',advance='yes') '  default '
    case (IMODEL_GLL )
    write(IMAIN,'(a)',advance='yes') '  gll'
    case (IMODEL_1D_PREM )
    write(IMAIN,'(a)',advance='yes') '  1d_prem'
    case (IMODEL_1D_CASCADIA )
    write(IMAIN,'(a)',advance='yes') '  1d_cascadia'
    case (IMODEL_1D_SOCAL )
    write(IMAIN,'(a)',advance='yes') '  1d_socal'
    case (IMODEL_SALTON_TROUGH )
    write(IMAIN,'(a)',advance='yes') '  salton_trough'
    case (IMODEL_TOMO )
    write(IMAIN,'(a)',advance='yes') '  tomo'
    case (IMODEL_USER_EXTERNAL )
    write(IMAIN,'(a)',advance='yes') '  external'
    case (IMODEL_IPATI )
    write(IMAIN,'(a)',advance='yes') '  ipati'
    case (IMODEL_IPATI_WATER )
    write(IMAIN,'(a)',advance='yes') '  ipati_water'
    case (IMODEL_SEP)
    write(IMAIN,'(a)',advance='yes') '  SEP'
    case (IMODEL_COUPLED)
    write(IMAIN,'(a)',advance='yes') '  model coupled with injection method'
    end select

    write(IMAIN,*)
  endif

! check that reals are either 4 or 8 bytes
  if (CUSTOM_REAL /= SIZE_REAL .and. CUSTOM_REAL /= SIZE_DOUBLE) &
    call exit_MPI(myrank,'wrong size of CUSTOM_REAL for reals')

  ! for noise simulations, we need to save movies at the surface (where the noise is generated)
  ! and thus we force MOVIE_SURFACE to be .true., in order to use variables defined for surface movies later
  if (NOISE_TOMOGRAPHY /= 0) then
    MOVIE_TYPE = 1
    MOVIE_SURFACE = .true.
    USE_HIGHRES_FOR_MOVIES = .true.     ! we need to save surface movie everywhere, i.e. at all GLL points on the surface
  endif

  !! TL: read adepml_stage file
  if (PML_CONDITIONS .and. USE_ADE_PML) then
    open(unit=17, file="adepml_stage", action="read")
    read(17,*) CALC_ADEPML_DAMPING
    read(17,*) SET_ADEPML_GLOB
    close(17)
  endif

  if (myrank == 0) then

    write(IMAIN,*)
    if (SUPPRESS_UTM_PROJECTION) then
      write(IMAIN,*) 'suppressing UTM projection'
    else
      write(IMAIN,*) 'using UTM projection in region ',UTM_PROJECTION_ZONE
    endif
    write(IMAIN,*)

    if (ATTENUATION) then
      write(IMAIN,*) 'incorporating attenuation using ',N_SLS,' standard linear solids'
      if (USE_OLSEN_ATTENUATION) then
        write(IMAIN,*) '  using attenuation from Olsen et al.'
      else
        write(IMAIN,*) '  not using attenuation from Olsen et al.'
      endif
    else
      write(IMAIN,*) 'no attenuation'
    endif
    write(IMAIN,*)

    if (ANISOTROPY) then
      write(IMAIN,*) 'incorporating anisotropy'
    else
      write(IMAIN,*) 'no anisotropy'
    endif
    write(IMAIN,*)

    if (APPROXIMATE_OCEAN_LOAD) then
      write(IMAIN,*) 'incorporating the oceans using equivalent load'
      if (TOPOGRAPHY) write(IMAIN,*) ' with elevation from topography file'
    else
      write(IMAIN,*) 'no oceans'
    endif
    write(IMAIN,*)

    if (STACEY_ABSORBING_CONDITIONS) then
      write(IMAIN,*) 'incorporating Stacey absorbing conditions'
    else
      if (PML_CONDITIONS) then
        write(IMAIN,*) 'incorporating absorbing conditions of perfectly matched layer'
      else
        write(IMAIN,*) 'no absorbing condition'
      endif
    endif
    write(IMAIN,*)

    if (USE_FORCE_POINT_SOURCE) then
       write(IMAIN,*) 'using a FORCESOLUTION source instead of a CMTSOLUTION source'
    else
       write(IMAIN,*) 'using a CMTSOLUTION source'
    endif
    if (USE_RICKER_TIME_FUNCTION) then
       write(IMAIN,*) '  with a Ricker source time function'
    else
       if (USE_FORCE_POINT_SOURCE) then
          write(IMAIN,*) '  with a quasi-Heaviside source time function'
       else
          write(IMAIN,*) '  with a Gaussian source time function'
       endif
    endif
    write(IMAIN,*)

    call flush_IMAIN()
  endif

! makes sure processes are synchronized
  call synchronize_all()

  end subroutine read_parameters

!
!-------------------------------------------------------------------------------------------------
!

  subroutine read_topography()

! reads in topography files

  use generate_databases_par
  implicit none

  if (APPROXIMATE_OCEAN_LOAD .and. TOPOGRAPHY) then

    ! values given in constants.h
    NX_TOPO = NX_TOPO_FILE
    NY_TOPO = NY_TOPO_FILE

    allocate(itopo_bathy(NX_TOPO,NY_TOPO),stat=ier)
    if (ier /= 0) call exit_MPI_without_rank('error allocating array 615')
    if (ier /= 0) stop 'error allocating array itopo_bathy'

    call read_topo_bathy_file(itopo_bathy,NX_TOPO,NY_TOPO)

    if (myrank == 0) then
      write(IMAIN,*)
      write(IMAIN,*) 'regional topography file read ranges in m from ',minval(itopo_bathy),' to ',maxval(itopo_bathy)
      write(IMAIN,*)
      call flush_IMAIN()
    endif
  else
    NX_TOPO = 1
    NY_TOPO = 1
    allocate(itopo_bathy(NX_TOPO,NY_TOPO),stat=ier)
    if (ier /= 0) call exit_MPI_without_rank('error allocating array 616')
    if (ier /= 0) stop 'error allocating dummy array itopo_bathy'

  endif

  end subroutine read_topography

