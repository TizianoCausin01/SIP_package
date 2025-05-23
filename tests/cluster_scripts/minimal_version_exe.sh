#!/bin/bash
cd /leonardo/home/userexternal/tcausin0/SIP_package
fn=oregon
module load openmpi
julia --version
julia /leonardo/home/userexternal/tcausin0/SIP_package/tests/cluster_scripts/minimal_version.jl $fn 
