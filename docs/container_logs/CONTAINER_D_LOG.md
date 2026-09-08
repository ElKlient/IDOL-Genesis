# Container D Log - IDOL Genesis

Status: Android/build/performance pass.
Repo: `ElKlient/IDOL-Genesis`
Branch: `main`
Base first checked: `b0dafbf Add container A workflow log`
Base before D commit: `dacb80d Document container C asset review`
Version after latest merge: `IDOL -- GENESIS 0.8.20 LIVING WORLD` with Android performance settings layered on top.

## Role

Container D owns Android/build/performance concerns for this pass:

- check Godot import/runtime workflow,
- reduce phone-side texture and render pressure,
- inspect heavy assets and cache policy,
- preserve current people, AI, walking, work loop, and retargeter.

## Files Read First

- `WORKFLOW_FIRST.md`
- `docs/CONTAINER_HANDOFF_PROMPT.md`
- `docs/container_logs/CONTAINER_A_LOG.md`
- `scripts/main.gd`
- `scripts/retargeter.gd`

Also read for workflow/build context:

- `docs/CONTAINER_HANDOFF_WALK_AND_IMPORT.md`
- `docs/NEXT_DEVELOPMENT_COORDINATION.md`
- `project.godot`
- `main.tscn`
- `assets/third_party_model_packs/README.md`

## Findings

- The safe current checkout in this container is `/workspace/scratch/fca424588312/IDOL-Genesis`.
- The older `/workspace/scratch/3a13918d6208/IDOL-Genesis` checkout is a stale `0.6.7 Armory` branch state and should not be used as a new base.
- No active `.codex/coordination/project.yaml` marker was found in the current checkout.
- Container C created local commit `dacb80d Document container C asset review` while this pass was running. D work is built on top of that commit and does not overwrite C files.
- `export_presets.cfg` is not present yet, so Android export settings are not reproducible from the repo.
- `assets/third_party_model_packs/` has `.gdignore`; vendor packs should stay excluded from Godot import unless selected files are promoted elsewhere.
- No `.godot/`, `.import`, `*.import`, or committed `*.gd.uid` files were present before this pass in the clean checkout.
- The known Godot path from earlier handoffs, `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64`, is not available in this container anymore.
- After the required `/workspace/scratch` search, Godot 4.7.2 was available at `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64` and was used for final import/runtime checks.

## Changes Made

- `project.godot`
  - initially bumped project name to `IDOL Genesis 0.8.19 Android Performance`;
  - after merging Container E, preserved the latest gameplay name `IDOL Genesis 0.8.19 Hunt and Hides`;
  - after merging Container A's `0.8.20 Living World`, preserved `IDOL Genesis 0.8.20 Living World`;
  - enabled `textures/vram_compression/import_etc2_astc=true` for mobile texture import/export.
- `.gitignore`
  - added `*.gd.uid` so generated Godot UID files do not pollute normal container commits.
- `scripts/main.gd`
  - initially bumped HUD version string to `IDOL -- GENESIS 0.8.19 ANDROID PERFORMANCE`;
  - after merging Container E, preserved the latest gameplay HUD title `IDOL -- GENESIS 0.8.19 HUNT AND HIDES`;
  - after merging Container A's `0.8.20 Living World`, preserved the latest HUD title `IDOL -- GENESIS 0.8.20 LIVING WORLD`;
  - added `is_mobile_runtime()` and `world_count()` helpers;
  - reduced decorative world density on Android via `MOBILE_WORLD_DENSITY=.72`;
  - disabled directional sun shadows on Android by default with `MOBILE_SHADOWS=false`.
- `main.tscn`
  - renamed the root scene node to `IDOL0819`.
- `assets/characters/*.png` and `assets/village/*.png`
  - downscaled 31 source PNG textures from 2048x2048 to 1024x1024.

## Asset Size Result

Before this pass:

- `assets`: about 115 MB
- `assets/characters`: about 34 MB
- `assets/village`: about 53 MB

After this pass:

- `assets`: about 55 MB
- `assets/characters`: about 12 MB
- `assets/village`: about 15 MB
- `assets/third_party_model_packs`: about 22 MB, still vendor-excluded by `.gdignore`
- `assets/animations`: about 7.8 MB, currently not loaded at runtime because `USE_RETARGETED_ANIMATIONS=false`

## Verification

- Re-read latest GitHub instructions from `origin/main` after Container A added task files.
- Read `docs/container_tasks/CONTAINER_D_TASK.md` and followed the D lane: Android/Godot import/runtime/performance/cache workflow only.
- Merged latest `origin/main` after Container B and C updates. Merge commit before this log update: `ccc604c Merge remote-tracking branch 'origin/main'`.
- `git diff --check`: passed before and after the merge.
- Local D commits created:
  - `e38b58b Optimize Android texture and world performance`
  - `2aa695b Record container D push blocker`
  - `e044739 Ignore generated Godot UID files`
- First `git push origin main`: blocked by missing HTTPS credentials in this container (`could not read Username for 'https://github.com'`).
- First Git Data API upload created commit `9422c78`, but `update_ref` was rejected as non-fast-forward because remote `main` moved during the binary upload. The ref was not forced.
- Re-fetched and merged `e53361a IDOL Genesis 0.8.19 Hunt and Hides` from Container E. For overlapping gameplay files, E's hunting/meat/hides changes were kept and D's Android settings were reapplied/confirmed.
- After the E merge, `project.godot` still has `textures/vram_compression/import_etc2_astc=true`, and `scripts/main.gd` still has `MOBILE_WORLD_DENSITY`, `MOBILE_SHADOWS`, `is_mobile_runtime()`, `world_count()`, Android sun-shadow disable, and mobile-scaled decoration loops.
- After the E merge, repeated Godot checks with the fallback binary:
  - editor import passed, exit `0`;
  - runtime passed, exit `0`.
- Re-fetched and merged `2c2c9cc IDOL Genesis 0.8.20 Living World` from Container A. A's palisade/gate/hide-yard/world-depth additions were preserved, and D's Android settings remained present.
- After the `0.8.20 Living World` merge, repeated Godot checks with the fallback binary:
  - `git diff --check`: passed;
  - editor import passed, exit `0`;
  - runtime passed, exit `0`;
  - `timeout 8s ... --headless --path .`: ran without runtime errors until expected exit `124`.
- Final Git Data API push succeeded without force:
  - remote commit: `7e2d5bc902b9d180e4e4dc4ade4aec32a9d41974`;
  - parent: `2c2c9ccfc96993774b8aa9a9a10753f12cf0dbc5`;
  - local source HEAD for the pushed tree: `99bfa02fa998b2edcc8e82f2d4e2dd385d2d6a12`.
- Old Godot path requested by handoff:
  - `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit`
  - result: binary not present in this container.
- Required fallback search:
  - `find /workspace/scratch -maxdepth 5 -type f -iname '*godot*'`
  - result: found `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64`.
- Godot editor import with fallback binary:
  - `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit`
  - result: passed, exit `0`; Godot reimported 10 changed/downscaled PNG textures.
- Godot runtime with fallback binary:
  - `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit`
  - result: passed, exit `0`.
- After Godot checks, `git status --short --branch` remained clean apart from local commits ahead of `origin/main`; no untracked import/cache files were left visible to Git.

## Blockers / Risks

- D code/performance changes are on GitHub in `7e2d5bc902b9d180e4e4dc4ade4aec32a9d41974`. Plain HTTPS `git push` from this container is still blocked by missing credentials, so further container writes may need the GitHub connector/Git Data API path.
- The old shared Godot path is missing in this container, but the local fallback Godot 4.7.2 binary passed editor import and runtime.
- Real FPS and gray-screen confirmation still need an Android-side test after pulling this commit on the phone.
- Downscaled 1024px textures are the right mobile direction, but visual quality should be checked on the phone after import.
- `export_presets.cfg` should be added in a later Android export pass once signing/export choices are known.
- This host cannot wake itself every 30 minutes after the turn ends; if Container D is paused, the user needs to resume it for the next polling check.

## Termux Command For User

Paste this in Termux on the phone after the commit is pushed:

```bash
cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline
```

Do not add `rm -rf .godot` for a normal update. Do not use `git stash -u` for a normal update.
