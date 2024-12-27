# %%
# https://pypi.org/project/pytubefix/  alternative to pytube
from pytubefix import YouTube
from pytubefix.cli import on_progress

# %%


def load_yt_video(cfg):
    """loads a yt video using pytubefix
    https://pypi.org/project/pytubefix/
    and returns the full path to the new file.
    inputs :
    - cfg.url of the video
    - cfg.data_dir where you want your data stored
    - cfg.file_name the name of the file

    outputs :
    - the path to the file
    (the saved file isn't returned
    """
    yt = YouTube(
        cfg.url, on_progress_callback=on_progress
    )  # creates a yt object referring to the video in the URL, dir(yt) to see its attributes. on_progress_callback argument to show the download progress later on
    print(yt.title)
    # print(yt.streams.filter(res=720, progressive=False,only_video=True).first()) # to inspect the characteristics of what you are loading
    yt.streams.filter(res=720, progressive=False, only_video=True).first().download(
        output_path=cfg.path2data, filename=cfg.file_name
    )  # .streams atrtibute provides access to different audio/video formats of the object. .first selects the very first stream among the ones filtered. .download downloads in the output_path with the target file_name
    # video_stream.download(output_path=data_dir, filename=file_name)
    path2file = f"{cfg.path2data}{cfg.file_name}"
    return path2file


# %%
class cfg:
    path2data: str = (
        "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/"
    )
    file_name: str = "test_venice.mp4"
    url: str = "https://youtube.com/shorts/ZcKNP5MGnnY?si=blcRxg3Wkp47F1nG"


# %%
videopath = load_yt_video(cfg)

# %%
print(videopath)
