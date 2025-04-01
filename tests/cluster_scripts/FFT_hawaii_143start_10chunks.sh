#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=02:00:00
#SBATCH --ntasks=1 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=FFT_hawaii_143start_10chunks
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

fn=hawaii
start_chunk=143
n_chunks=10
/leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/video_merge_for_FFT.sh $fn $start_chunk $n_chunks
