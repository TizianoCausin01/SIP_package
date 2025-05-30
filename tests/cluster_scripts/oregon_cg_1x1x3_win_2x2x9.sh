#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=07:00:00
#SBATCH --ntasks=32 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=oregon_cg_1x1x3_win_2x2x9
#SBATCH --mail-type=ALL
#SBATCH --mail-user=tcausin@sissa.it
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
fn=oregon
cg1=1
cg2=1
cg3=3
win1=2
win2=2
win3=9
module load openmpi
export JULIA_NUM_THREADS=1

time mpiexec --bind-to none -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_master_worker_pattern_test.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3

time mpiexec --bind-to none -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/loc_max_parallel_cluster.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3

time mpiexec --bind-to none -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/template_matching_parallel_cluster.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3
