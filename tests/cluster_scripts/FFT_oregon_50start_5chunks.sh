#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=00:30:00
#SBATCH --ntasks=1 # number of processes
#SBATCH --cpus-per-task=1
#SBATCH --mem=480G
#SBATCH --account=Sis25_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=FFT_oregon_50start_5chunks
#SBATCH --output=/leonardo/home/userexternal/tcausin0/output_jobs/%x.%j.out   # file name will be *job_name*.*job_id*

fn=oregon
start_chunk=50
n_chunks=5
/leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/video_merge_for_FFT.sh $fn $start_chunk $n_chunks
