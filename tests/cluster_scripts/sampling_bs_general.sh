#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --ntasks=32 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

# cd /leonardo/home/userexternal/epiasini/sissa/tiziano/SIP_package
fn=${1}
cg1=${2}
cg2=${3}
cg3=${4}
win1=${5}
win2=${6}
win3=${7}
mergers_num=${8}
block_size=${9}

module load openmpi # hdf5
export JULIA_NUM_THREADS=1

heap_size_hint=10G

time mpiexec --bind-to core --map-by core -np $SLURM_NTASKS stdbuf -o0 -e0 julia --project --heap-size-hint=$heap_size_hint /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_block_scrambling.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3 $mergers_num $block_size 
