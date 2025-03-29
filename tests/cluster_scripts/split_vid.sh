#!/bin/bash
# $1 = file_name , $2 = chunk_duration , $3 = margins_to_remove

file_name=$1
chunk_duration=$2
margins_to_remove=$3
julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/split_vid_cluster.jl $file_name $chunk_duration
/leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/remove_margins.sh $file_name $margins_to_remove