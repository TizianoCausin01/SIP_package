
function split_vid(file_name, output_name, segment_duration)
    """
    Splits the video in pieces of the specified $segment_duration 
    and then saves them in the specified $output_name
    Inputs :
    - file_name -> complete path to the file
    - output_name -> complete path for the output 
                    (must have %03d to save them in progressive order
                    starting from 000 like in python)
    - segment_duration -> how long should the computed segment be
                            (the last could inevitably be shorter)

    breakdown of cmd
    cmd =`        # backtick to start the command
    ffmpeg        
    -i $file_name # input
    -an           # excludes the audio channel : not needed
    -c:v copy     # codec only video, copy directly from the compressed one (without encoding and decoding)
    -f segment    # format : segment of video
    -segment_time $segment_duration # duration of each segment
    -reset_timestamps 1 # every segment will have independent timestamps starting from 00:00:00
    $output_name  
    `
    """
cmd =`                
    ffmpeg        
    -i $file_name 
    -an           
    -c:v copy     
    -f segment    
    -segment_time $segment_duration 
    -reset_timestamps 1 
    $output_name  
    `
    run(cmd) # runs the command
end # EOF



