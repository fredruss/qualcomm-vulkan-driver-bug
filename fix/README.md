# Workaround: Vulkan queue global priority HIGH

An engine patch for Godot 4.7.2. It is not a pull request: an AI agent wrote it. It is here for developers who
ship on affected phones now.

The patch adds the project setting `rendering/rendering_device/vulkan/high_queue_priority` (default `false`). When
it is `true`, Godot creates the Vulkan device queues with global priority HIGH (`VK_KHR_global_priority`, else
`VK_EXT_global_priority`). If the driver refuses, Godot uses the default priority and logs one line.

## Result (this project, same phone, GPU composition on)

| Build | Hole frames | One-frame faults | Composed frames in 20 s | Missed compositor deadlines | App fps on screen |
|---|---|---|---|---|---|
| Stock | 158 of 6082 | 317 small, 232 giant | 1193 | 0 | 61 |
| Patch, setting on | 0 of 2084 | 0 | 975 | 571 | 49 |

The faults are gone. The cost: under GPU composition, the compositor misses deadlines, because the project now
holds the GPU ahead of it. This project is a worst case (no frame cap, GPU busy 100 %). In a game with a 30 fps
cap, the same patch gave 0 faults in 5353 frames and no measured frame rate cost. Without GPU composition the
compositor does not use the GPU, so there is no cost.

The test build was a .NET 4.7.2 template with this patch. It also held a second patch (CPU skinning) that was off.

## Use

1. Build the Android templates from `4.7.2-stable` with the patch:

   ```sh
   git clone -b 4.7.2-stable https://github.com/godotengine/godot.git && cd godot
   git apply /path/to/godot-4.7.2-vulkan-queue-priority.patch
   python3 misc/scripts/install_swappy_android.py
   scons platform=android target=template_debug arch=arm64 production=yes
   scons platform=android target=template_release arch=arm64 production=yes
   cd platform/android/java && ./gradlew generateGodotTemplates
   ```

2. In the export preset, set `custom_template/debug` and `custom_template/release` to the APKs in `bin/`.
3. In `project.godot`, under `[rendering]`: `rendering_device/vulkan/high_queue_priority.android=true`.
4. Check the log with `--verbose`: `Vulkan: Created the device queues with high global priority.`
