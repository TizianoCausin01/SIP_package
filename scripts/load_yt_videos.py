# https://pypi.org/project/pytubefix/
from pytubefix import YouTube
from pytubefix.cli import on_progress

# %%
url = "https://youtu.be/ap7CZI070as?si=iZSCsAQML3PJ9cF3"
data_dir = (
    "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/"
)

yt = YouTube(url, on_progress_callback=on_progress)
print(yt.title)

video_stream = yt.streams.filter(only_video=True).get_highest_resolution()
ys.download(output_path=data_dir, filename="test.mp4")


# %%
