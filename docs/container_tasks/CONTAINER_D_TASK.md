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
