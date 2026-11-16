# Adreno 730: one-frame render faults under GPU composition (Godot 4.7.2, Mobile renderer)

A minimal project for a Godot issue. On a Qualcomm Adreno 730 phone, the Mobile renderer shows single-frame
faults when Android composes the screen with the GPU. The Compatibility renderer does not.

## Device

- Samsung Galaxy S22 Ultra (SM-S908E), Adreno 730, Qualcomm Vulkan driver 512.615.98, Android 16
- Godot 4.7.2-stable (official editor and export templates), Mobile renderer

## What shows

For one frame, then the picture is correct again:

1. One skinned mesh is drawn giant.
2. Parts of the picture are wrong: block-shaped wrong sun shadows, a tree crown or its shadow absent, grey patches.

Expected: no fault frames.

## Condition

Android GPU composition (SurfaceFlinger draws with the GPU). Any of these turns it on:

- Developer options > "Disable HW overlays" (it turns off again at each restart)
- A screen recorder (the phone's own, or scrcpy)
- An overlay window

Without GPU composition there are no faults. The rate grows with the GPU time per frame, so the scene keeps the
GPU busy: 12 animated skinned characters, 6000 grass and 300 tree instances with vertex wind, a sun with shadows,
and `rendering/scaling_3d/scale.mobile=2.0`.

## Steps

1. Open the project in Godot 4.7.2 and export the preset "Android Vulkan" (debug).
2. Install it on the phone and turn on "Disable HW overlays".
3. Start the app and watch the crowd for 1 to 2 minutes. The camera holds still. The counter in the top-left
   corner shows the frame number.

The preset "Android Compatibility" is the same project with `gl_compatibility` (custom feature `compat`), as a control.

## Results (this project)

| Build | GPU composition | Frames | Small faults | Giant faults |
|---|---|---|---|---|
| Vulkan | on | | | |
| Vulkan | off | | | |
| Compatibility | on | | | |

## Count the faults

`tools/` needs `adb`, `scrcpy`, `ffmpeg` and Python 3 with `numpy`.

```sh
tools/record.sh export/vulkan.apk org.fredruss.adrenoflicker /abs/out/run1 90
python3 tools/scan_still.py /abs/out/run1.mp4 /abs/out/run1.scan
python3 tools/tally.py /abs/out/run1.scan
```

A fault frame differs from both of its neighbours while the neighbours agree. `tally.py` counts
small (300 < n < 20000 changed pixels) and giant (n >= 20000) faults. Show one with its neighbours:

```sh
ffmpeg -i run1.mp4 -vf "select='between(n,F-1,F+1)'" -fps_mode passthrough f_%d.png
```

## Earlier measurements (in the game this was found in)

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

## Evidence

From the game, on this phone, with "Disable HW overlays" on:

- `evidence/big_flash_*_stock_engine.*`: fault 1 (giant skinned mesh). A 4.7.2 build with log lines only and no
  rendering change.
- `evidence/shadow_fault_*_low_priority.*`: fault 2 (wrong shadow blocks). A 4.7.2 build with the Vulkan queue
  global priority set to LOW, which makes the fault more frequent. Stock 4.7.2 shows the same, less often.

Each PNG holds the fault frame between its two neighbours.

## AI use

An AI agent (Claude) helped in the diagnosis and wrote this project, the scripts in `tools/` and this README.
I ran every measurement on my own phone and checked the results.

## License

MIT (`LICENSE`). The models in `assets/` are KayKit by Kay Lousberg, CC0 (`assets/KayKit-CC0-License.txt`).
