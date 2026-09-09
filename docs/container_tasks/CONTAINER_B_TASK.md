# Container B Task - People And Animation

Owner lane: people, walk realism, arm motion, bone axes, skeleton/pose safety.

## Current assignment from Container A

Improve confidence around the settlers' walking animation without replacing the current people system.

Start with analysis, then do a small patch only if it is clearly isolated.

## Round 0.8.20 instruction from Container A

After the `Living World` patch lands, verify people against the new world and hunt loop:

1. Watch settlers in AUTO while they walk between Idol, hearth, stockpile, hide yard, homes, resource sources and hunt targets.
2. Check that `ŁOWY`, meat cargo and hides delivery do not break arm swing or cargo posture.
3. If movement still looks stupid, tune only the smallest safe part of `apply_bone_pose()`, `pose_walk_arm()` or `pose_walk_leg()`.
4. Do not touch terrain, resource balance, HUD or asset imports.

Report whether the new obstacles/palisade/hide yard cause pathing or animation issues.

## Round 0.8.25 urgent instruction from Container A

The user says the people are central to the game and still look stupid/wooden when the whole scene is judged on Android. Base is now `0.8.25 Grounded Settlement Pass`.

Your job now:

1. Pull latest `main` and verify the current people in AUTO with the new terrain, shadows and clothing layers.
2. Check whether the walk reads as a human shifting weight, or still as a rigid mannequin sliding around.
3. If code changes are needed, touch only people/pose code: `apply_living_pose()`, `apply_bone_pose()`, `pose_walk_arm()`, `pose_walk_leg()`, spacing and turn smoothing if directly related.
4. Do not touch terrain, UI, assets, resource balance, or Android workflow.
5. Report with a clear yes/no: is the walk acceptable for the current model, or does Container A need a deeper animation pass next?

Specific things to watch:

- feet contact and bobbing rhythm after shadows were added,
- arm swing still moving front/back, not around its own axis,
- root rotation when settlers turn near hearth/stockpile/bridges,
- whether root gear hides the silhouette or creates new visual junk.

## Round 0.8.26 instruction from Container A

Base is now `0.8.26 Earth and Shelter Polish`. The world is visually heavier: object shadows, darker roofs, more grit/twigs/rocks and a busier Idol plaza.

Your job now:

1. Pull latest `main`.
2. Watch whether settlers remain readable while moving through the busier center.
3. If they still look like rigid mannequins, make one minimal people-only animation patch and document exactly which pose axis/rhythm changed.
4. Check if new ground clutter visually hides feet or makes the walk look worse from the default camera.
5. Do not touch visual terrain, roofs, UI, assets, resources or Android workflow.

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

## Round 0.8.27 instruction from Container A

Base is now `0.8.27 Resource Infrastructure`. The world has new resource sources and new work targets: forest sources, fish sources, stone deposits, iron/coal/copper deposits, lumber camps, hunter huts, fisher huts, quarries and mines.

Your job now:

1. Pull latest `main`.
2. Watch settlers in AUTO after the new buildings are queued and completed.
3. Verify movement and poses for `DRWAL`, `RYBY` and `GÓRNIK`, especially when workers turn near huts, river edges, deposits and stockpile.
4. Check that added obstacles do not cause sliding, crowd clumps or jitter around work points.
5. If patching, touch only people/pose/path-safety code and keep the current people model.

Report whether the current model can support the new resource economy after small animation tweaks, or whether Container A must schedule a deeper human animation pass.

## 30 minute check

While active or waiting, every 30 minutes check this file and `WORKFLOW_FIRST.md` for new Container A instructions.

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
