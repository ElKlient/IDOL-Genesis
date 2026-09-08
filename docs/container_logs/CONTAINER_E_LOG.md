# Container E Log - IDOL Genesis

Status: gameplay container for settlement systems.
Repo: `ElKlient/IDOL-Genesis`
Branch target: `main`
Base: `dd49fd3 Add Container C environment asset plan`

## Role

Container E owns gameplay around settlement resources, people tasks, food, families, wildlife and UI. This pass did not take over people animation, retargeting, Android build/performance or external asset selection.

## Scope Completed

- Added first lightweight hunting loop to `scripts/main.gd`.
- Kept existing humans, their models, procedural walk, AI movement, work loop and `scripts/retargeter.gd`.
- Reused the procedural deer already placed by `0.8.18 Ancient Settlement`; no new heavy assets were imported.
- Re-read `WORKFLOW_FIRST.md`, `docs/CONTAINER_HANDOFF_PROMPT.md`, `docs/container_tasks/README.md` and `docs/container_tasks/CONTAINER_E_TASK.md` after the user reminded the container to follow GitHub instructions.
- Reapplied this pass on top of latest `origin/main` after Container B/C log and asset-plan updates, so B's walking changes and C's environment planning are preserved.
- Added `meat` and `hides` as settlement resources.
- Added `ŁOWY` as an Idol order and AUTO fallback when food is low.
- Let meat feed hungry settlers better than berries.
- Let families use combined food from berries and meat for child support.
- Expanded HUD/person info to show meat, hides, wildlife count and hunting skill.

## Main Files Touched

- `scripts/main.gd`
- `project.godot`
- `main.tscn`
- `README.txt`
- `WORKFLOW_FIRST.md`
- `docs/CONTAINER_HANDOFF_PROMPT.md`
- `docs/container_logs/CONTAINER_E_LOG.md`

## Notes For Next Containers

- Gameplay entry points for this pass: `wildlife`, `food_units()`, `feed_person(...)`, `assign_hunt(...)`, `finish_hunt(...)`, `update_wildlife(...)`.
- Deer use cheap procedural meshes and a simple `alive/recover/reserved_by` state.
- `ŁOWY` is intentionally limited in AUTO to avoid pulling the whole settlement away from building and gathering.
- Skins are stored as `hides` for the next civil building/crafting pass, for example a tannery, warmer homes or clothing.
- Do not move this into retargeter or animation work; the human pose change here only maps `ŁOWY` to the existing gather/work stance.

## Recommendation To Container A

- Integrate after D/B/C priority checks if Android testing has no new blocker.
- Reject or tune later only if hunting pulls too many workers away from construction, food pressure feels too high, or the wider HUD is too cramped on the user's phone.
- Next safe E vertical: use `hides` for a tannery/drying-rack building or clothing warmth bonus instead of adding another raw resource immediately.

## Verification

- `git diff --check` passed.
- Expected Godot path from older handoff did not exist in this runtime:
  `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64`.
- Found working Godot binary:
  `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64`.
- Editor import passed:
  `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit`.
- Runtime load passed:
  `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit`.
- Short startup passed without runtime errors:
  `timeout 8s /workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path .`.
  Exit code `124` was expected because the running game was intentionally stopped by `timeout`.
- Godot generated `scripts/main.gd.uid` and `scripts/retargeter.gd.uid`; they were deleted and not staged.

## Termux Command For User

```bash
cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline
```
