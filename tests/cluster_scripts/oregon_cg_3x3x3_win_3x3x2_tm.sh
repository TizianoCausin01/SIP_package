#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --ntasks=32 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=oregon_cg_3x3x3_win_3x3x2_tm
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
fn=oregon
cg1=3
cg2=3
cg3=3
win1=3
win2=3
win3=2
module load openmpi
export JULIA_NUM_THREADS=1

#time mpiexec --bind-to core --map-by core -np $SLURM_NTASKS stdbuf -o0 -e0 julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_master_worker_pattern_test.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3

#time mpiexec --bind-to core -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/loc_max_parallel_cluster.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3
time mpiexec --bind-to core -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/template_matching_parallel_cluster.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3
