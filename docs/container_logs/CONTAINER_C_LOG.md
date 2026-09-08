# Container C Log - IDOL Genesis

Status: completed asset/environment review pass.
Repo: `ElKlient/IDOL-Genesis`
Branch: `main`
Base checked: `b0dafbf Add container A workflow log`
Version in game: `IDOL -- GENESIS 0.8.18 ANCIENT SETTLEMENT`

## Role

Container C owns asset and environment scouting for this pass:

- inspect existing model packs,
- choose light GLB/glTF candidates for Android,
- propose safe world replacements,
- preserve current people, AI, walk cycle, work loop, and retargeter.

## Files Read First

- `WORKFLOW_FIRST.md`
- `docs/CONTAINER_HANDOFF_PROMPT.md`
- `docs/container_logs/CONTAINER_A_LOG.md`
- `scripts/main.gd`
- `scripts/retargeter.gd`

Also read for environment context:

- `project.godot`
- `main.tscn`
- `docs/CONTAINER_HANDOFF_WALK_AND_IMPORT.md`
- `docs/NEXT_DEVELOPMENT_COORDINATION.md`
- `assets/third_party_model_packs/README.md`
- local license files in `assets/third_party_model_packs/`

## Asset Pack Findings

All included third-party packs are documented locally as CC0:

- Kenney Nature Kit GLB: 329 GLB files, about 3.6 MB.
- Kenney Survival Kit GLB: 80 GLB files, about 1.5 MB.
- Kenney Mini Characters GLB: character models around 240-273 KB each.
- KayKit Medieval Hexagon Pack: 221 glTF files plus `.bin` files and 16 KB texture atlases per category, about 13 MB total.

Important workflow finding:

- `assets/third_party_model_packs/` contains `.gdignore`, so Godot should not load promoted gameplay assets directly from that vendor folder.
- Promote only selected files into normal game asset folders, for example `assets/environment/kenney_survival/` or `assets/environment/kaykit_medieval/`.
- For Kenney GLB, copy only the chosen `.glb`.
- For KayKit glTF, copy the chosen `.gltf`, its matching `.bin`, and the local `hexagons_medieval.png` from the same category folder.
- Do not stage generated `.import`, `.godot/`, or random `*.gd.uid` files for this asset review.

## Commit From This Pass

- `Document container C asset review`

## Recommended First Promotion Set

These are low-risk because they replace or improve existing static/procedural props without touching people or AI.

| Current world part | Recommended asset | Why | Integration note |
| --- | --- | --- | --- |
| Stockpile wood | `kenney_survival_kit_glb/models/resource-wood.glb` | Single-file GLB, 8 KB, better than box sticks. | Add near `make_stockpile()` or `add_stick_source()` after promotion. |
| Stockpile stone | `kenney_survival_kit_glb/models/resource-stone.glb` / `resource-stone-large.glb` | Single-file GLB, 8-16 KB, good resource readability. | Use a few instances, keep procedural small stones for scatter. |
| Tool yard | `kenney_survival_kit_glb/models/tool-axe.glb`, `tool-pickaxe.glb`, `tool-hammer.glb` | Single-file GLB, 8-12 KB, matches stone-age tool readability if scaled down. | Do not change settler skeleton or hand attachments in this pass. |
| Workshop | `kenney_survival_kit_glb/models/workbench.glb` | About 26 KB, clear crafting prop. | Use as a hero prop in `make_workshop()` or `make_tool_yard()`. |
| Camp / homes | `kenney_survival_kit_glb/models/bedroll.glb`, `bedroll-packed.glb`, `tent-canvas-half.glb` | 16-20 KB, makes living area more believable. | Add only a few around homes; do not replace houses yet. |
| River edge | `kenney_nature_kit_glb/models/canoe.glb`, `canoe_paddle.glb` | 16 KB + 4 KB, strong visual story near river. | Add in `make_river_camp_details()`. |
| Fire pit | `kenney_survival_kit_glb/models/campfire-pit.glb` or Kenney Nature `campfire_logs.glb` | 12-28 KB, better base for fire. | Keep existing light/flame cones for cheap animation/readability. |
| Fence/palisade | `kenney_survival_kit_glb/models/fence.glb` or Nature `fence_simple*.glb` | 8-16 KB, better settlement boundary. | Add obstacles only where they block walk paths. |

## KayKit Candidates For Later

KayKit is still light enough if used sparingly, but it is less plug-and-play because glTF files need their `.bin` and texture atlas copied together.

| Use | Candidate | Approx real payload | Recommendation |
| --- | --- | --- | --- |
| Granary/spichlerz | `gltf/buildings/neutral/building_grain.gltf` + bin + atlas | about 34 KB | Best KayKit building candidate. |
| House shell | `gltf/buildings/*/building_home_A_*.gltf` | about 76 KB with atlas | Test one neutral-looking color only; avoid all variants. |
| Well | `gltf/buildings/*/building_well_*.gltf` | about 64 KB with atlas | Nice camp center prop after scale check. |
| Scaffold/build site | `gltf/buildings/neutral/building_scaffolding.gltf` | about 184 KB with atlas | Useful but heavier; use one instance only. |
| Blacksmith/iron hint | `gltf/buildings/*/building_blacksmith_*.gltf` | about 144 KB with atlas | Save for later steel chapter, not current stone-age pass. |
| Props | `decoration/props/sack.gltf`, `bucket_*.gltf`, `weaponrack.gltf`, `wheelbarrow.gltf` | about 19-40 KB each with atlas | Good as single scene dressing props. |

Avoid importing KayKit hex terrain/river tiles wholesale in the current map. The existing procedural terrain, paths, and river already work with camera and AI; full hex replacement would be a gameplay/terrain rewrite, not a safe asset pass.

## Do Not Use Now

- Do not use Kenney Mini Characters as villagers in this phase. The user explicitly wants to keep the current human model, AI, walk, and retargeter.
- Do not promote whole packs into active Godot import paths.
- Do not replace procedural people gear or bone-attached visuals while Container B is working on human movement.
- Do not use old `0.6.7 Armory` assets directly; recover only stone-age-friendly ideas such as spears, stone axes, hunting training, or future defense.

## Suggested Next Container C Implementation Pass

1. Create a small normal asset folder such as `assets/environment/kenney_survival/`.
2. Copy 6-10 selected GLB files only:
   - `resource-wood.glb`
   - `resource-stone.glb`
   - `tool-axe.glb`
   - `tool-pickaxe.glb`
   - `workbench.glb`
   - `bedroll.glb`
   - `campfire-pit.glb`
   - `canoe.glb`
   - `canoe_paddle.glb`
   - `fence.glb`
3. Add preloads in `scripts/main.gd` only for promoted files.
4. Use them in `make_stockpile()`, `make_tool_yard()`, `make_workshop()`, and `make_river_camp_details()`.
5. Keep procedural fallback props nearby so the scene still reads if one import fails.
6. Add `add_obstacle(...)` for any new object large enough to block settlers.

## Verification

No gameplay code or active asset imports are part of this Container C pass.

Required checks run:

- `git diff --check`
- Godot 4.7.2 was not present at the old documented path, so the same release was downloaded locally to `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64`.
- Editor import: `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit`
- Runtime: `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit`

Observed results:

- `git diff --check` passed.
- Final clean-clone Godot editor import exited `0`.
- Final clean-clone Godot runtime exited `0`.
- Final clean-clone verification generated only local untracked `scripts/main.gd.uid` and `scripts/retargeter.gd.uid`; Container C did not stage them.
- An earlier dirty checkout also contained non-C changes in `project.godot`, `main.tscn`, and `scripts/main.gd` that looked like an Android performance pass (`0.8.19 ANDROID PERFORMANCE`). Container C did not stage those files.
- In that earlier dirty checkout, Godot reported a transient warning/error while importing `res://assets/village/T_RockTrim_ORM.png` and rewrote/downscaled local PNG textures. The final clean-clone verification did not reproduce that import error.

## Blockers / Risks

- Visual QA of actual promoted GLB scale/orientation still needs a render or Android test once the next pass instantiates them.
- Godot may create generated import files, `*.gd.uid`, or local texture rewrites during verification; do not stage them unless the task explicitly becomes asset import policy.

## Termux Command For User

Paste this in Termux on the phone after the commit is pushed:

```bash
cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline
```
