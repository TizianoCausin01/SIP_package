#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --ntasks=32 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=15G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=1917movie_cg_3x3x3_win_3x3x3
#SBATCH --mail-type=ALL
#SBATCH --mail-user=tcausin@sissa.it
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
fn=1917movie
cg1=3
cg2=3
cg3=3
win1=3
win2=3
win3=3
module load openmpi
export JULIA_NUM_THREADS=1

#time mpiexec --bind-to core --map-by core -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_master_worker_pattern_test.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3

time mpiexec --bind-to core -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/loc_max_parallel_cluster.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3

#time mpiexec --bind-to core -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/template_matching_parallel_cluster.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3
