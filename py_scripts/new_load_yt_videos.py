# %%
import yt_dlp


def download_video_only(url, output_path=".", resolution=1080, fps=30):
    """
    Download only the video stream from a YouTube video

    Key Parameters:
    - url: Full YouTube video URL
    - output_path: Directory to save the video
    """
    # dict with parameters to download the video
    ydl_opts = {
        # Select video-only streams, I could select lower resolutions by doing: "format": "bestvideo[quality=3][ext=mp4]"
        "format": f"bestvideo[height<={resolution}][fps<={fps}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]",
        # Output template (can customize filename)
        "outtmpl": output_path,
        # Optional: Limit to specific resolutions if desired
        # 'format': 'bestvideo[height<=1080][ext=mp4]',  # Example: limit to 1080p
    }

    # Create YouTube downloader object
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            # Attempt to download
            ydl.download([url])
            print("Video-only download completed successfully!")

        except Exception as e:
            print(f"Download failed: {e}")


# %%
# using the function
path2data = (
    "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data"
)
file_name = "vid_bolt"
download_video_only(
    "https://youtu.be/HFLuduKmnW0?si=e6AsxtHS3gMiD48n",
    f"{path2data}/{file_name}.mp4",
)
# %%
# yt-dlp --cookies-from-browser chrome --cookies cookies.txt
