#!/bin/bash
cg1=${2}
cg2=${3}
cg3=${4}
win1=${5}
win2=${6}
win3=${7}
scrambling_cond=${8}
read -a files <<< "$1"    # reads the first argin and creates an array called files
for fn in "${files[@]}"; do
    sbatch --job-name=${fn}_cg_${2}x${3}x${4}_win_${5}x${6}x${7}_jsd_${8} ./jsd_scrambling_general.sh $fn $cg1 $cg2 $cg3 $win1 $win2 $win3 ${8} ${9} ${10}
done
