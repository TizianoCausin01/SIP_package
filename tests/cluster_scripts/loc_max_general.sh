#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --ntasks=5 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/epiasini/sissa/tiziano/SIP_package
fn=${1}
cg1=${2}
cg2=${3}
cg3=${4}
win1=${5}
win2=${6}
win3=${7}
module load openmpi # hdf5
export JULIA_NUM_THREADS=1

heap_size_hint=10G

time mpiexec --bind-to core -np $SLURM_NTASKS julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/loc_max_xor_cluster.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3

