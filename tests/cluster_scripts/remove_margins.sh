#!/bin/bash
# argin1 = file_name  , argin2 = num of files to rm
data_path=/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/${1}_split
files=($(ls ${data_path}/${1}*.mp4 | sort -V))
for (( i=0; i<$2; i++ )); do
    rm "${files[i]}"             # Remove first N files
    rm "${files[TOTAL-1-i]}"      # Remove last N files
done
