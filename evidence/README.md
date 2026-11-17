# Evidence

Each PNG shows the glitch frame between its two neighbours. Each MP4 is the clip around it.

From this project, official Godot 4.7.2, "Disable HW overlays" on:

- `repro_grey_holes.*`: ground and grass missing.
- `repro_giant_mesh.*`: one skinned mesh drawn giant (run with a 30 fps cap).

From the game where I found the bug, same phone:

- `big_flash_*_stock_engine.*`: giant skinned mesh. Godot 4.7.2 with extra log lines only, no rendering change.
- `shadow_fault_*_low_priority.*`: wrong shadows. Godot 4.7.2 patched to use queue global priority LOW, which
  makes the glitch more frequent.

Glitch rate in the game (12 skinned characters, static camera, "Disable HW overlays" on):

| Setting | Glitch frames |
|---|---|
| 3D scale 2.0 (22 fps) | 2.5 % |
| 3D scale 1.0 / 0.5 (30 fps) | 0.07 % / 0.23 % |
| Terrain only, no skinned meshes, trees or grass | 0 of 1783 |
| Queue global priority LOW (patched engine) | 11.7 % |
| Queue global priority HIGH (patched engine) | 0.2 to 0.5 % |
