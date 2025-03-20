# ${1}=file_name, ${2}=the chunk we'll start with, ${3}=num of chunks to merge
path2data=/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data
mkdir -p ${path2data}/${1}_FFT
vid_dir=${path2data}/${1}_FFT
split_dir=${path2data}/${1}_split
fdigits_vid_num=$(printf "%03d" "${2}")
ls ${split_dir}/${1}${fdigits_vid_num}.mp4 | awk '{print "file \x27" $0 "\x27"}' > ${vid_dir}/vid_names_start${2}_${3}chunks_FFT.txt
for (( i=${2}+1; i<${2}+${3}; i++ )); do
	fdigits_vid_num=$(printf "%03d" "${i}")
        ls ${split_dir}/${1}${fdigits_vid_num}.mp4 | awk '{print "file \x27" $0 "\x27"}' >> ${vid_dir}/vid_names_start${2}_${3}chunks_FFT.txt
done
name_vid=${vid_dir}/${1}_start${2}_${3}chunks_FFT.mp4
ffmpeg -f concat -safe 0 -i ${vid_dir}/vid_names_start${2}_${3}chunks_FFT.txt -c copy $name_vid
fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 $name_vid)
fps=$(echo "scale=2; $fps" | bc -l)
julia FFT_cluster.jl ${1} ${2} ${3} ${fps}
