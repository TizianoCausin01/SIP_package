#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=00:40:00
#SBATCH --ntasks=8 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --account=Sis24_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=first_job
#SBATCH --mail-type=ALL
#SBATCH --mail-user=tcausin@sissa.it
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
module load openmpi
time mpiexec -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_master_worker_pattern_test.jl # e.g. mpiexec -np 10 time julia /home/tcausin/SIP_package/tests/server_master_worker_pattern_test.jl
