#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=01:30:00
#SBATCH --ntasks=5 
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=PCA_cenote_caves_10vids_2frames
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

module load openmpi
fn=cenote_caves
n_chunks=25
vids_x_chunk=2
ratio_denom=50
frame_seq=2
n_comps=30

module load openmpi
export JULIA_NUM_THREADS=1
time mpiexec --bind-to core --map-by core -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/PCA_cluster.jl $fn $n_chunks $vids_x_chunk $ratio_denom $frame_seq $n_comps
