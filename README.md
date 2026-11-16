# Adreno 730: one-frame render faults under GPU composition (Godot 4.7.2, Mobile renderer)

A minimal project for a Godot issue. On a Qualcomm Adreno 730 phone, the Mobile renderer shows single-frame
faults when Android composes the screen with the GPU. The Compatibility renderer does not.

## Device

- Samsung Galaxy S22 Ultra (SM-S908E), Adreno 730, Qualcomm Vulkan driver 512.615.98, Android 16
- Godot 4.7.2-stable (official editor and export templates), Mobile renderer

## What shows

For one frame, then the picture is correct again:

1. Parts of the picture are absent: the grass and the ground are missing and the clear colour (grey) shows.
2. Parts of the picture are wrong: wrong sun shadows on the grass.
3. One skinned mesh is drawn giant (stretched spikes across the screen).

Expected: no fault frames.

## Condition

Android GPU composition (SurfaceFlinger draws with the GPU). Any of these turns it on:

- Developer options > "Disable HW overlays" (it turns off again at each restart)
- A screen recorder (the phone's own, or scrcpy)
- An overlay window

The rate grows with the GPU time per frame. The scene keeps the GPU busy: 12 animated skinned characters,
6000 grass and 300 tree instances with vertex wind, a sun with shadows, and on mobile 3D scale 2.0, MSAA 2x and
no frame rate cap.

## Steps

1. Open the project in Godot 4.7.2 and export the preset "Android Vulkan" (debug).
2. Install it on the phone and turn on "Disable HW overlays".
3. Start the app and watch for 1 to 2 minutes. The camera holds still. The top-left counter shows the frame number.

The preset "Android Compatibility" is the same project on `gl_compatibility` (custom feature `compat`), as a control.

## Results

90 s per run, no input, recorded with scrcpy (which also forces GPU composition). Project settings unless stated.

| Build | GPU composition | fps | Recorded frames | Hole frames (`holes.py`) | One-frame faults (`tally.py`) |
|---|---|---|---|---|---|
| Vulkan | on | 71 | 6082 | 158 (2.6 %) | 317 small, 232 giant |
| Vulkan, 30 fps cap, no MSAA | on | 30 | 2691 | 0 | 1 small |
| Vulkan, 30 fps cap | on | 30 | 2695 | 0 | 1 giant |
| Compatibility | on | 40 | 3723 | 0 | 0 |
| Vulkan | off | 71 | not recorded | no clear fault seen by eye | |

A recording turns on GPU composition, so the last row is an eye test only.

## Count the faults

`tools/` needs `adb`, `scrcpy`, `ffmpeg` and Python 3 with `numpy`.

```sh
tools/record.sh export/vulkan.apk org.fredruss.adrenoflicker /abs/out/run1 90
python3 tools/holes.py /abs/out/run1.mp4
python3 tools/scan_still.py /abs/out/run1.mp4 /abs/out/run1.scan && python3 tools/tally.py /abs/out/run1.scan
```

- `holes.py` counts frames with the clear colour in the lower half of the picture. It is the strict count.
- `scan_still.py` and `tally.py` count frames that differ from both neighbours while the neighbours agree: small
  (300 < n < 20000 changed pixels) and giant (n >= 20000). Wind and animation give some false positives.

Show a frame `F` with its neighbours:

```sh
ffmpeg -i run1.mp4 -vf "select='between(n,F-1,F+1)',tile=3x1" -fps_mode passthrough -frames:v 1 f.png
```

## Evidence

From this project, official 4.7.2, "Disable HW overlays" on. Each PNG is the fault frame between its two neighbours.

- `evidence/repro_grey_holes.*`: grass and ground absent for one frame.
- `evidence/repro_giant_mesh.*`: one skinned mesh drawn giant for one frame.

From the game this was found in, on the same phone:

- `evidence/big_flash_*_stock_engine.*`: giant skinned mesh. A 4.7.2 build with log lines only, no rendering change.
- `evidence/shadow_fault_*_low_priority.*`: wrong shadow blocks. A 4.7.2 build with the Vulkan queue global
  priority set to LOW, which makes the fault more frequent.

## Earlier measurements (in the game)

Same phone, a game scene with 12 skinned creatures, static camera, "Disable HW overlays" on:

| Setting | Fault frames |
|---|---|
| 3D scale 2.0, 22 fps | 2.5 % |
| 3D scale 1.0 / 0.5, 30 fps | 0.07 % / 0.23 % |
| Terrain only (no skinned meshes, trees, grass) | 0 of 1783 |
| Vulkan queue global priority LOW (`VK_EXT_global_priority`, engine change) | 11.7 % |
| Vulkan queue global priority HIGH (engine change) | 0.2 to 0.5 % |

The priority result suggests that the compositor's GPU context preempts the game in a frame, and that part of the
preempted work is lost.

## AI use

An AI agent (Claude) helped in the diagnosis and wrote this project, the scripts in `tools/` and this README.
I ran every measurement on my own phone and checked the results.

## License

MIT (`LICENSE`). The models in `assets/` are KayKit by Kay Lousberg, CC0 (`assets/KayKit-CC0-License.txt`).
