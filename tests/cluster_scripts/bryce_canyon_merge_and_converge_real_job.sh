#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --ntasks=32 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=merge_and_converge_real
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
module load openmpi
export JULIA_NUM_THREADS=1

time mpiexec --bind-to core --map-by core -np $SLURM_NTASKS stdbuf -o0 -e0 julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_merge_and_converge_real.jl bryce_canyon 3 3 3 3 3 2 10
