#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=00:30:00
#SBATCH --ntasks=1 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=FFT_emerald_lake_99start_5chunks
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

fn=emerald_lake
start_chunk=99
n_chunks=5
/leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/video_merge_for_FFT.sh $fn $start_chunk $n_chunks
