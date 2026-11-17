# Tools

Scripts to record the phone screen and count glitch frames. They need `adb`, `scrcpy`, `ffmpeg` and Python 3
with `numpy`.

```sh
tools/record.sh export/vulkan.apk org.fredruss.adrenoflicker /abs/out/run1 90
python3 tools/holes.py /abs/out/run1.mp4
python3 tools/scan_still.py /abs/out/run1.mp4 /abs/out/run1.scan && python3 tools/tally.py /abs/out/run1.scan
```

- `record.sh` installs and starts the app, waits 15 s, records with scrcpy and saves the Godot log.
- `holes.py` counts frames where the clear colour shows in the lower half of the picture (missing ground).
- `scan_still.py` and `tally.py` count frames that differ from both neighbours while the neighbours match:
  small (300 to 20000 changed pixels) and giant (more). The wind and animations give some false positives.

To see frame `F` next to its neighbours:

```sh
ffmpeg -i run1.mp4 -vf "select='between(n,F-1,F+1)',tile=3x1" -fps_mode passthrough -frames:v 1 f.png
```
