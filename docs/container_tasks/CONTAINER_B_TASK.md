# Container B Task - People And Animation

Owner lane: people, walk realism, arm motion, bone axes, skeleton/pose safety.

## Current assignment from Container A

Improve confidence around the settlers' walking animation without replacing the current people system.

Start with analysis, then do a small patch only if it is clearly isolated.

Read first:

1. `WORKFLOW_FIRST.md`
2. `docs/CONTAINER_HANDOFF_PROMPT.md`
3. `docs/container_logs/CONTAINER_A_LOG.md`
4. `scripts/main.gd`
5. `scripts/retargeter.gd`

Focus functions:

- `make_person()`
- `make_person_body()`
- `apply_living_pose()`
- `apply_bone_pose()`
- `pose_walk_arm()`
- `pose_walk_leg()`

## 35 minute check

While active or waiting, every 35 minutes check this file and `WORKFLOW_FIRST.md` for new Container A instructions.

## Subagents allowed

You may spawn subagents such as:

- B1: audit bone names/axes and identify safest arm swing axis.
- B2: inspect procedural walk math and propose smoothing/weight shift.
- B3: prepare a verification checklist for Godot/Android visual testing.

Subagents do not push. Container B owns the log and any commit.

## Write scope

Preferred first write: `docs/container_logs/CONTAINER_B_LOG.md`.

If implementing, keep changes small and limited to animation/pose functions in `scripts/main.gd` or clearly documented retargeter safety in `scripts/retargeter.gd`.

Do not touch terrain, resources, UI, asset packs, or Android workflow.

## Required report to Container A

Include:

1. What was checked.
2. Which bones/functions matter.
3. Whether code changed.
4. Commit SHA if pushed.
5. Risks and required tests.
6. Clear recommendation: integrate / reject / wait / test on Android.
