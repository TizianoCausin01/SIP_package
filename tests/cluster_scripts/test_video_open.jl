using VideoIO

function test_videos(folder::String)
    files = filter(f -> endswith(f, ".mp4"), readdir(folder; join=true))
    for f in files
        println("Testing: $f")
            reader = VideoIO.openvideo(f)
            count = 0
	    ok = 1
	    try
    while !eof(reader)
        frame = VideoIO.read(reader)
        count += 1
    end
catch e
    println("❌ Failed: $e at frame $count")
    ok = false
end
end
end

# Example usage
file_name = ARGS[1]
test_videos("/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(file_name)_split/")
