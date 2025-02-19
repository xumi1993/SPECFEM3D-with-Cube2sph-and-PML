# Cube2sph

Accurate and flexible continental-scale seismic wave simulations based on SPECFEM3D

- mesh truncated at customized depth
- implementation of curvilinear PML based on auxiliary differential equations


## Installation
```
bash quick_installation
```

## Steps
1. Preparing parameter files (`DATA/Par_file`, `DATA/meshfem3D_files/Mesh_Par_file`) and model files (e.g., interface files, tomographic files)

2. Running the internal mesher (or an external mesher) to generate a cube-shaped mesh. In order to properly output the mesh files, the internal mesher needs to be run in serial (NPROCS=1).

3. Running the partitioner to partition the mesh to each processor.

4. Generating database for the cube-shaped mesh. This database is not used by the solver. This step aims to output the GLL model files and PML parameter files that are used in the next step.

5. Performing the "cubed sphere" transformation to generate a new mesh with curvature. This program reads the `proc*_Database` files of the cube-shaped mesh, and outputs the `proc*_Database` files of the deformed mesh. In this step, the users also have the option to do some SPECFEM3D\_GLOBE-style node stretching, and replace the GLL model with some pre-defined model (currently, we offer PREM, IASP91, S40RTS, and IRIS EMC NetCDF models) by properly setting the `Cube2sph_model_par` file. If curvilinear PML is used, this step also outputs PML-related files.

6. Generating database for the deformed mesh. This will be the database used by the solver.

7. Performing rotation for source and receivers files.

8. Launching the SPECFEM3D solver.

9. Performing rotation for the seismograms.

Examples provided in `utils/cube2sph/cube2sph_examples` directory:
- `pml_prem`: PML with PREM-onecrust model on a 20\*20 degrees domain
- `stacey_prem`: Stacey boundary condition with PML-onecrust model on a 20\*20 degrees domain
- `alaska_example`: mesh with surface and Moho topography and 3D tomographic model on a 22\*22 degrees domain
- `northeast_china`: example for wavefield injection using Cube2sph-AxiSEM coupling (under development)
