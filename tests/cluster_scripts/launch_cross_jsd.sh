#!/bin/bash
cg1=${2}
cg2=${3}
cg3=${4}
win1=${5}
win2=${6}
win3=${7}
read -a files <<< "$1"    # reads the first argin and creates an array called files
len_files=$(("${#files[@]}"-1)) # -1 bc it starts from 0, (( to evaluate a math expression
for idx_1 in $(seq 0 ${len_files}); do
    fn1=${files[idx_1]}
    for idx_2 in $(seq 0 $((idx_1-1))); do
        fn2=${files[idx_2]}
        sbatch --job-name=${fn1}_vs_${fn2}_cg_${2}x${3}x${4}_win_${5}x${6}x${7}_cross_jsd ./cross_jsd_general.sh $fn1 $fn2 $cg1 $cg2 $cg3 $win1 $win2 $win3
    done
done
