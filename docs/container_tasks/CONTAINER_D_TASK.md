# Container D Task - Android, Godot And Build Safety

Owner lane: Android, Termux workflow, Godot import/runtime, gray screen, performance/build checks.

## Current assignment from Container A

Protect the project from broken Android/Godot workflow before visual/gameplay work piles up.

## Round 0.8.20 instruction from Container A

After the `Living World` patch lands, validate it before bigger art/gameplay work:

1. Pull newest `main`.
2. Run `git diff --check`.
3. Run Godot headless editor import.
4. Run Godot headless runtime.
5. On Android/Termux workflow, confirm the user command still updates the same project folder.
6. Watch for gray screen, slow import, `.gd.uid`, local texture rewrites, and FPS drop from new static props.

If anything fails, write the exact command/output in `docs/container_logs/CONTAINER_D_LOG.md` and mark integration blocked.

## Round 0.8.25 urgent instruction from Container A

Base is now `0.8.25 Grounded Settlement Pass`. Container A added a custom terrain mesh, more edge mass, people shadows and lighter UI opacity. The user also complained earlier that opening the project on Android/Godot can require waiting for files to load.

Your job now:

1. Pull latest `main` and validate `0.8.25` with the required Godot commands below.
2. Check whether the custom `ArrayMesh` terrain and extra visual density create import/runtime errors or obvious startup slowdown.
3. Inspect repo status after Godot import for accidental cache/UID/import churn and document anything generated.
4. Re-check the Termux update command stays simple and does not force `.godot` deletion.
5. Try to find a reliable local screenshot/movie workflow only if it does not require destabilizing the project. If `--headless --write-movie` still crashes, document that exact limitation.

Do not touch people animation, terrain art direction, gameplay balance, or HUD design unless fixing a direct runtime break.

## Round 0.8.26 instruction from Container A

Base is now `0.8.26 Earth and Shelter Polish`. The patch adds more small static nodes: grit, twigs, roof strips, extra tree branches and object shadows.

Your job now:

1. Pull latest `main`.
2. Run the required Godot import/runtime checks and report timings if easy to capture.
3. Inspect whether the added node density is acceptable for Android or needs batching/reduction.
4. Verify no generated cache/import/UID files are accidentally staged.
5. Keep the user Termux command simple: no `.godot` deletion and no `git stash -u` for normal updates.

Read first:

1. `WORKFLOW_FIRST.md`
2. `docs/CONTAINER_HANDOFF_PROMPT.md`
3. `docs/container_logs/CONTAINER_A_LOG.md`
4. `project.godot`
5. `main.tscn`
6. `scripts/main.gd`

Known Termux path for the user:

```bash
/storage/emulated/0/IDOL-Genesis/IDOL-Genesis
```

Known container Godot binary:

```bash
/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64
```

## Round 0.8.27 instruction from Container A

Base is now `0.8.27 Resource Infrastructure`. The patch adds new procedural and GLB-backed resource buildings, mineral deposits, fish sources, forest sources and a denser command/HUD state.

Your job now:

1. Pull latest `main`.
2. Run `git diff --check`, Godot headless editor import and Godot headless runtime.
3. Inspect whether the new resource landmarks and huts create unacceptable node count/import/runtime cost.
4. Verify no `.godot/`, `.import/`, `*.gd.uid` or generated cache files are staged by accident.
5. Reconfirm the user Termux update command stays simple: no `.godot` deletion and no `git stash -u`.

If startup looks slower, report whether it is from one-time import or from actual scene/runtime density.

## 30 minute check

While active or waiting, every 30 minutes check this file and `WORKFLOW_FIRST.md` for new Container A instructions.

## Subagents allowed

You may spawn subagents such as:

- D1: verify Godot binary/import/runtime commands.
- D2: inspect repo for cache/import files that should not be committed.
- D3: prepare Android/Termux user command and troubleshooting checklist.

Subagents do not push. Container D owns the log and any commit.

## Write scope

Preferred first writes:

- `docs/container_logs/CONTAINER_D_LOG.md`
- `docs/android/ANDROID_GODOT_WORKFLOW.md` if useful.
- A small verification script only if it is truly helpful and documented.

Do not touch people animation, terrain visuals, or gameplay balance unless the bug is directly caused by Android/runtime.

## Required checks

At minimum, document results for:

```bash
git diff --check
GODOT_BIN="$(command -v godot || command -v godot4 || find /workspace/scratch -maxdepth 5 -type f -iname 'Godot_v*-stable_linux.x86_64' | head -n 1)"
"$GODOT_BIN" --headless --editor --path . --quit
"$GODOT_BIN" --headless --path . --quit
```

If the binary is missing, first search `/workspace/scratch` before claiming Godot is unavailable.

## Required report to Container A

Include:

1. What runtime/build/import workflow was checked.
2. Exact commands and results.
3. Whether code/docs changed.
4. Commit SHA if pushed.
5. Gray screen/import/cache risks.
6. Clear recommendation: integrate / reject / wait / test on Android.
