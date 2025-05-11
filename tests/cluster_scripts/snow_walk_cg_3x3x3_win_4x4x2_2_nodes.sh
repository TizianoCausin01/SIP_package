#!/bin/bash

#SBATCH --nodes=3
#SBATCH --time=24:00:00
#SBATCH --ntasks=45 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=0
#SBATCH --ntasks-per-node=15
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=snow_walk_cg_3x3x3_win_4x4x2_2_nodes
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
fn=snow_walk
cg1=3
cg2=3
cg3=3
win1=4
win2=4
win3=2
n_mergers=15
module load openmpi
export JULIA_NUM_THREADS=1

time mpiexec --bind-to core --map-by node -np $SLURM_NTASKS stdbuf -o0 -e0 julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_merge_and_converge_real.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3 $n_mergers

