#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=5:00:00
#SBATCH --ntasks=32 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=1917_temp_matching
#SBATCH --mail-type=ALL
#SBATCH --mail-user=tcausin@sissa.it
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
module load openmpi
export JULIA_NUM_THREADS=1
time mpiexec --bind-to none -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/template_matching_parallel_cluster.jl 1917movie 3 3 3 2 2 2 
