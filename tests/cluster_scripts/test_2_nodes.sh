#!/bin/bash

#SBATCH --nodes=2
#SBATCH --time=01:00:00
#SBATCH --ntasks=40 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=0
#SBATCH --ntasks-per-node=20
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=test_2_nodes
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
fn=oregon
cg1=3
cg2=3
cg3=3
win1=3
win2=3
win3=3
module load openmpi
export JULIA_NUM_THREADS=1

time mpiexec --bind-to core --map-by ppr:3:node:cyclic -np $SLURM_NTASKS stdbuf -o0 -e0 julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/test_2_nodes.jl 10 # $fn $cg1 $cg2 $cg3 $win1 $win2 $win3

