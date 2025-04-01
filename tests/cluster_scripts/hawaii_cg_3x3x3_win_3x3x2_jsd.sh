#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=15:00:00
#SBATCH --ntasks=1 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=hawaii_cg_3x3x3_win_3x3x2_jsd
#SBATCH --mail-type=ALL
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

cd /leonardo/home/userexternal/tcausin0/SIP_package
fn=hawaii
cg1=3
cg2=3
cg3=3
win1=3
win2=3
win3=2
module load openmpi
time julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/cluster_sh_ent_jsd_grid.jl $fn $cg1 $cg2 $cg3 $win1 $win2 $win3
