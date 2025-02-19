
 !
 ! this is the parameter file for static compilation of the solver
 !
 ! mesh statistics:
 ! ---------------
 !
 !
 ! number of chunks =            1
 !
 ! these statistics do not include the central cube
 !
 ! number of processors =            1
 !
 ! maximum number of points per region =      5070605
 !
 ! on NEC SX, make sure "loopcnt=" parameter
 ! in Makefile is greater than max vector length =     15211815
 !
 ! total elements per slice =        87552
 ! total points per slice =      5843195
 !
 ! the time step of the solver will be DT =    1.90265458E-02  (s)
 ! the (approximate) minimum period resolved will be =    1.51111114      (s)
 !
 ! total for full 1-chunk mesh:
 ! ---------------------------
 !
 ! exact total number of spectral elements in entire mesh = 
 !    87552.000000000000     
 ! approximate total number of points in entire mesh = 
 !    5843195.0000000000     
 ! approximate total number of degrees of freedom in entire mesh = 
 !    16086711.000000000     
 !
 ! position of the mesh chunk at the surface:
 ! -----------------------------------------
 !
 ! angular size in first direction in degrees =    1.00000000    
 ! angular size in second direction in degrees =    1.00000000    
 !
 ! longitude of center in degrees =   -152.000000    
 ! latitude of center in degrees =    64.0000000    
 !
 ! angle of rotation of the first chunk =    0.00000000    
 !
 ! corner            1
 ! longitude in degrees =   -153.12042216468953     
 ! latitude in degrees =    63.648219876409556     
 !
 ! corner            2
 ! longitude in degrees =   -150.87957783531047     
 ! latitude in degrees =    63.648219876409541     
 !
 ! corner            3
 ! longitude in degrees =   -153.16123648212053     
 ! latitude in degrees =    64.643904238474434     
 !
 ! corner            4
 ! longitude in degrees =   -150.83876351787947     
 ! latitude in degrees =    64.643904238474420     
 !
 ! resolution of the mesh at the surface:
 ! -------------------------------------
 !
 ! spectral elements along a great circle =        11520
 ! GLL points along a great circle =        46080
 ! average distance between points in degrees =    7.81250000E-03
 ! average distance between points in km =   0.868710339    
 ! average size of a spectral element in km =    3.47484136    
 !

 ! approximate static memory needed by the solver:
 ! ----------------------------------------------
 !
 ! (lower bound, usually the real amount used is 5% to 10% higher)
 !
 ! (you can get a more precise estimate of the size used per MPI process
 !  by typing "size -d bin/xspecfem3D"
 !  after compiling the code with the DATA/Par_file you plan to use)
 !
 ! size of static arrays per slice =    3668.0663119999999       MB
 !                                 =    3498.1406326293945       MiB
 !                                 =    3.6680663120000001       GB
 !                                 =    3.4161529615521431       GiB
 !
 ! (should be below to 80% or 90% of the memory installed per core)
 ! (if significantly more, the job will not run by lack of memory )
 ! (note that if significantly less, you waste a significant amount
 !  of memory per processor core)
 ! (but that can be perfectly acceptable if you can afford it and
 !  want faster results by using more cores)
 !
 ! size of static arrays for all slices =    3668.0663119999999       MB
 !                                      =    3498.1406326293945       MiB
 !                                      =    3.6680663120000001       GB
 !                                      =    3.4161529615521431       GiB
 !                                      =    3.6680663119999998E-003  TB
 !                                      =    3.3360868765157647E-003  TiB
 !

 integer, parameter :: NEX_XI_VAL =           32
 integer, parameter :: NEX_ETA_VAL =           32

 integer, parameter :: NSPEC_CRUST_MANTLE =        76416
 integer, parameter :: NSPEC_OUTER_CORE =        10432
 integer, parameter :: NSPEC_INNER_CORE =          704

 integer, parameter :: NGLOB_CRUST_MANTLE =      5070605
 integer, parameter :: NGLOB_OUTER_CORE =       721437
 integer, parameter :: NGLOB_INNER_CORE =        51153

 integer, parameter :: NSPECMAX_ANISO_IC =            1

 integer, parameter :: NSPECMAX_ISO_MANTLE =        76416
 integer, parameter :: NSPECMAX_TISO_MANTLE =        76416
 integer, parameter :: NSPECMAX_ANISO_MANTLE =            1

 integer, parameter :: NSPEC_CRUST_MANTLE_ATTENUATION =            1
 integer, parameter :: NSPEC_INNER_CORE_ATTENUATION =            1

 integer, parameter :: NSPEC_CRUST_MANTLE_STR_OR_ATT =        76416
 integer, parameter :: NSPEC_INNER_CORE_STR_OR_ATT =          704

 integer, parameter :: NSPEC_CRUST_MANTLE_STR_AND_ATT =            1
 integer, parameter :: NSPEC_INNER_CORE_STR_AND_ATT =            1

 integer, parameter :: NSPEC_CRUST_MANTLE_STRAIN_ONLY =        76416
 integer, parameter :: NSPEC_INNER_CORE_STRAIN_ONLY =          704

 integer, parameter :: NSPEC_CRUST_MANTLE_ADJOINT =        76416
 integer, parameter :: NSPEC_OUTER_CORE_ADJOINT =        10432
 integer, parameter :: NSPEC_INNER_CORE_ADJOINT =          704
 integer, parameter :: NGLOB_CRUST_MANTLE_ADJOINT =      5070605
 integer, parameter :: NGLOB_OUTER_CORE_ADJOINT =       721437
 integer, parameter :: NGLOB_INNER_CORE_ADJOINT =        51153
 integer, parameter :: NSPEC_OUTER_CORE_ROT_ADJOINT =            1

 integer, parameter :: NSPEC_CRUST_MANTLE_STACEY =        76416
 integer, parameter :: NSPEC_OUTER_CORE_STACEY =        10432

 integer, parameter :: NGLOB_CRUST_MANTLE_OCEANS =            1

 logical, parameter :: TRANSVERSE_ISOTROPY_VAL = .true.

 logical, parameter :: ANISOTROPIC_3D_MANTLE_VAL = .false.

 logical, parameter :: ANISOTROPIC_INNER_CORE_VAL = .false.

 logical, parameter :: ATTENUATION_VAL = .false.

 logical, parameter :: ATTENUATION_3D_VAL = .false.

 logical, parameter :: ELLIPTICITY_VAL = .false.

 logical, parameter :: GRAVITY_VAL = .false.

 logical, parameter :: OCEANS_VAL = .false.

 integer, parameter :: NX_BATHY_VAL =         5400
 integer, parameter :: NY_BATHY_VAL =         2700

 logical, parameter :: ROTATION_VAL = .false.
 logical, parameter :: EXACT_MASS_MATRIX_FOR_ROTATION_VAL = .false.

 integer, parameter :: NSPEC_OUTER_CORE_ROTATION =            1

 logical, parameter :: PARTIAL_PHYS_DISPERSION_ONLY_VAL = .false.

 integer, parameter :: NPROC_XI_VAL =            1
 integer, parameter :: NPROC_ETA_VAL =            1
 integer, parameter :: NCHUNKS_VAL =            1
 integer, parameter :: NPROCTOT_VAL =            1

 integer, parameter :: ATT1_VAL =            1
 integer, parameter :: ATT2_VAL =            1
 integer, parameter :: ATT3_VAL =            1
 integer, parameter :: ATT4_VAL =            1
 integer, parameter :: ATT5_VAL =            1

 integer, parameter :: NSPEC2DMAX_XMIN_XMAX_CM =         5296
 integer, parameter :: NSPEC2DMAX_YMIN_YMAX_CM =         5296
 integer, parameter :: NSPEC2D_BOTTOM_CM =           64
 integer, parameter :: NSPEC2D_TOP_CM =         1024
 integer, parameter :: NSPEC2DMAX_XMIN_XMAX_IC =          176
 integer, parameter :: NSPEC2DMAX_YMIN_YMAX_IC =          176
 integer, parameter :: NSPEC2D_BOTTOM_IC =           16
 integer, parameter :: NSPEC2D_TOP_IC =           16
 integer, parameter :: NSPEC2DMAX_XMIN_XMAX_OC =         1624
 integer, parameter :: NSPEC2DMAX_YMIN_YMAX_OC =         1624
 integer, parameter :: NSPEC2D_BOTTOM_OC =           16
 integer, parameter :: NSPEC2D_TOP_OC =           64
 integer, parameter :: NSPEC2D_MOHO =            1
 integer, parameter :: NSPEC2D_400 =            1
 integer, parameter :: NSPEC2D_670 =            1
 integer, parameter :: NSPEC2D_CMB =            1
 integer, parameter :: NSPEC2D_ICB =            1

 logical, parameter :: USE_DEVILLE_PRODUCTS_VAL = .true.
 integer, parameter :: NSPEC_CRUST_MANTLE_3DMOVIE = 1
 integer, parameter :: NGLOB_CRUST_MANTLE_3DMOVIE = 1

 integer, parameter :: NSPEC_OUTER_CORE_3DMOVIE = 1
 integer, parameter :: NM_KL_REG_PTS_VAL = 1

 integer, parameter :: NGLOB_XY_CM =      5070605
 integer, parameter :: NGLOB_XY_IC =            1

 logical, parameter :: ATTENUATION_1D_WITH_3D_STORAGE_VAL = .true.

 logical, parameter :: FORCE_VECTORIZATION_VAL = .false.

 logical, parameter :: UNDO_ATTENUATION_VAL = .false.
 integer, parameter :: NT_DUMP_ATTENUATION_VAL =            8

 double precision, parameter :: ANGULAR_WIDTH_ETA_IN_DEGREES_VAL =     1.000000
 double precision, parameter :: ANGULAR_WIDTH_XI_IN_DEGREES_VAL =     1.000000
 double precision, parameter :: CENTER_LATITUDE_IN_DEGREES_VAL =    64.000000
 double precision, parameter :: CENTER_LONGITUDE_IN_DEGREES_VAL =  -152.000000
 double precision, parameter :: GAMMA_ROTATION_AZIMUTH_VAL =     0.000000

