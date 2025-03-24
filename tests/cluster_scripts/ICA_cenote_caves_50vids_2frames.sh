#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=01:30:00
#SBATCH --ntasks=5 
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=ICA_cenote_caves_10vids_2frames
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

module load openmpi
fn=cenote_caves
n_chunks=25
vids_x_chunk=2
ratio_denom=50
frame_seq=2
n_comps=3

module load openmpi
module load hdf5
export HDF5_LIB="/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-12.2.0/hdf5-1.14.3-flr43qytzge67qvbmjx4mszcm23s4d3b/lib"
export LD_LIBRARY_PATH="$HDF5_LIB:$LD_LIBRARY_PATH"
export JULIA_HDF5_PATH="$HDF5_LIB"
export JULIA_NUM_THREADS=1
time mpiexec --bind-to core --map-by core -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/ICA_cluster.jl $fn $n_chunks $vids_x_chunk $ratio_denom $frame_seq $n_comps
