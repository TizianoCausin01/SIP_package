#!/bin/bash

#SBATCH --nodes=2
#SBATCH --time=24:00:00
#SBATCH --ntasks=6 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=0
#SBATCH --ntasks-per-node=3
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --mail-type=ALL
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x_2nodes.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
fn=${1}
cg1=${2}
cg2=${3}
cg3=${4}
win1=${5}
win2=${6}
win3=${7}
scrambling_cond=${8}
module load openmpi
time mpiexec --bind-to core --map-by node -np $SLURM_NTASKS stdbuf -o0 -e0 julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_jsd_scrambling.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3 $scrambling_cond $9 ${10}
