# Workaround: high Vulkan queue priority

A Godot 4.7.2 patch for developers who ship on affected phones. It was written with an AI assistant, so it is not
proposed as a PR.

It adds the project setting `rendering/rendering_device/vulkan/high_queue_priority` (default `false`). When
enabled, Godot creates its Vulkan queues with global priority HIGH (`VK_KHR_global_priority` or
`VK_EXT_global_priority`). If the driver refuses, Godot falls back to the default priority and logs it.

## Result

This project, same phone, "Disable HW overlays" on:

| Build | Glitch frames | App fps | Missed compositor frames (20 s) |
|---|---|---|---|
| Stock | 158 of 6082 with missing ground, 549 in total | 61 | 0 of 1193 |
| Patched, setting on | 0 of 2084 | 49 | 571 of 975 |

The glitches are gone, but with GPU composition the compositor now misses frames, because the app runs ahead of it
on the GPU. This project is a worst case, with the GPU always busy. In my game, capped at 30 fps, the patch gave 0
glitches in 5353 frames and no measurable cost. Without GPU composition, the compositor doesn't use the GPU and
there is no cost.

The tested template also contained a second patch (CPU skinning), disabled.

## Use

1. Build the Android export templates with the patch:

   ```sh
   git clone -b 4.7.2-stable https://github.com/godotengine/godot.git && cd godot
   git apply /path/to/godot-4.7.2-vulkan-queue-priority.patch
   python3 misc/scripts/install_swappy_android.py
   scons platform=android target=template_debug arch=arm64 production=yes
   scons platform=android target=template_release arch=arm64 production=yes
   cd platform/android/java && ./gradlew generateGodotTemplates
   ```

2. In the export preset, set `custom_template/debug` and `custom_template/release` to the APKs in `bin/`.
3. In `project.godot`, under `[rendering]`, add `rendering_device/vulkan/high_queue_priority.android=true`.
4. Run with `--verbose` and check for `Vulkan: Created the device queues with high global priority.`
