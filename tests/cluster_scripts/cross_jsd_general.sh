#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=15:00:00
#SBATCH --ntasks=1 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --mail-type=ALL
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
time julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cross_jsd.jl $fn1 $fn2 $cg1 $cg2 $cg3 $win1 $win2 $win3
