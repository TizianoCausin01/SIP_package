# %%
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime, time

# %%
data = np.array([3769, 2277, 1692, 1463, 1306, 1002, 914])
nprocs = range(2, 9)
plt.plot(nprocs, data, "bo-", markersize=3)

for x, y in zip(nprocs, data):
    plt.text(x, y + 50, f"{y}", ha="center", va="bottom")
plt.xlabel("number of processes")
plt.ylabel("seconds")
plt.title("wall-time as function of processors - 10mins video")
plt.show()

# %% data from 10mins
data_mw = [
    time(0, 0, 0),
    time(1, 50, 23),
    time(0, 56, 0),
    time(0, 43, 56),
    time(0, 34, 7),
    time(0, 24, 41),
    time(0, 24, 30),
    time(0, 24, 29),
]

data_normal = times = [
    time(1, 2, 39),  # np 2: 1:02:39
    time(0, 37, 57),  # np 3: 37:57
    time(0, 28, 12),  # np 4: 28:12
    time(0, 24, 23),  # np 5: 24:23
    time(0, 21, 46),  # np 6: 21:46
    time(0, 16, 42),  # np 7: 16:42
    time(0, 15, 14),  # np 8: 15:14
    time(0, 0, 0),
]


# %%
def time_to_seconds(t):
    return t.hour * 3600 + t.minute * 60 + t.second


# %%
data_sec_mw = [time_to_seconds(t) for t in data_mw]
data_sec_normal = [time_to_seconds(t) for t in data_normal]
# %%
x = np.arange(2, 10)
# %%
plt.plot(x[1:], data_sec_mw[1:])
plt.plot(x[:-1], data_sec_normal[:-1])
plt.legend(["master-worker pattern", "normal parallel processing"])
plt.xlabel("number of processes")
plt.ylabel("seconds")
plt.title("wall-time as function of processors - 10mins video")
plt.show()

# %%


from datetime import timedelta

data_30_mw = [
    timedelta(hours=25, minutes=1, seconds=53),  # np 3: 25:01:53
    timedelta(hours=12, minutes=59, seconds=14),  # np 4: 12:59:14
    timedelta(hours=8, minutes=48, seconds=3),  # np 5: 8:48:03
    timedelta(hours=6, minutes=57, seconds=9),  # np 6: 6:57:09
    timedelta(hours=5, minutes=41, seconds=57),  # np 7: 5:41:57
    timedelta(hours=4, minutes=21, seconds=26),  # np 8: 4:21:26
]
data_30_sec_mw = [t.total_seconds() for t in data_30_mw]
# %%
x = np.arange(3, 9)
plt.plot(x, data_30_sec_mw)
plt.xlabel("number of processes")
plt.ylabel("seconds")
plt.title("wall-time as function of processors - ukraine video (30')")
plt.show()
# %%
