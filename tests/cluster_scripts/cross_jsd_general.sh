#!/bin/bash

#SBATCH --nodes=2
#SBATCH --time=24:00:00
#SBATCH --ntasks=6 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=0G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --mail-type=ALL
#SBATCH --ntasks-per-node=3
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
fn1=${1}
fn2=${2}
cg1=${3}
cg2=${4}
cg3=${5}
win1=${6}
win2=${7}
win3=${8}
module load openmpi
time mpiexec --bind-to core --map-by node -np $SLURM_NTASKS stdbuf -o0 -e0 julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cross_jsd_par.jl $fn1 $fn2 $cg1 $cg2 $cg3 $win1 $win2 $win3
