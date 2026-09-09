# Container Tasks - IDOL Genesis

This folder is the task board used by Container A for helper containers B, C, D and E.

## Polling rule

If a helper container is active, paused, or waiting for more work, it must check for new Container A instructions every 30 minutes.

Minimum check:

1. Pull or fetch the newest `main`.
2. Read `WORKFLOW_FIRST.md`.
3. Read its own task file in this folder.
4. Read its own log under `docs/container_logs/`.
5. If Container A changed the task, continue from the new instruction.

Do not invent background automation if the host cannot actually run it. If the container cannot wake itself, it must say so in its final/status message and tell the user to resume it.

## Subagent rule

Helper containers may spawn their own subagents, but only inside their lane:

- B: people, walk, arms, bones, retarget/pose safety.
- C: assets, environment, model packs, mobile-safe visuals.
- D: Android, Godot import/runtime, Termux, performance/build workflow.
- E: settlement gameplay, resources, buildings, UI, life/social systems.

Subagents should do narrow analysis, verification, or a small disjoint patch. The parent container owns the final decision, log, commit and push. Do not let multiple subagents push to `main` independently.

## Reporting rule

After every analysis pass or code pass, each helper writes a log:

- B: `docs/container_logs/CONTAINER_B_LOG.md`
- C: `docs/container_logs/CONTAINER_C_LOG.md`
- D: `docs/container_logs/CONTAINER_D_LOG.md`
- E: `docs/container_logs/CONTAINER_E_LOG.md`

Every report must include: scope checked, important files/functions, changed files or no-code status, commit SHA if pushed, risks/tests, and what Container A should integrate/reject/wait on.

## Urgent visual sprint - 0.8.25

Container A updated the project to `0.8.25 Grounded Settlement Pass` after the user reported that the game still looks too artificial on Android screenshots.

All helper containers must pull latest `main` and treat `0.8.25` as the new base:

- B: verify whether people still look wooden after grounded shadows/clothing; improve walk only inside the people/pose lane.
- C: push the world toward real settlement assets and better environment mass; avoid broad pack imports.
- D: validate Android/Godot import/runtime/performance after the added terrain mesh and visual density.
- E: reduce the debug feel of HUD/game presentation without breaking the current touch controls.

Do not keep working from the old `0.8.20` assignment without first reading your own updated task file.

## Active visual sprint - 0.8.26

Container A pushed the next visual pass as `0.8.26 Earth and Shelter Polish`.

All helper containers must treat `0.8.26` as the newest base:

- B: judge people/walk after the heavier world pass; report whether the current model still needs deeper animation work.
- C: stop at the visible art problem: replace or improve the worst toy-looking environment pieces, especially trees/roof treatment/ground clutter.
- D: validate node count/import/runtime on Android path after the extra cinders, grit, twigs and object shadows.
- E: prepare one compact HUD/presentation patch so the screen reads as a game, not a debug board.

If you are active, pull now and update your log with whether you are continuing, blocked, or handing off.

## Active gameplay sprint - 0.8.27

Container A pushed the resource infrastructure pass as `0.8.27 Resource Infrastructure`.

All helper containers must treat `0.8.27` as the newest base:

- B: verify settlers around new work routes and buildings: forest camps, fish huts, quarries, mines and resource deposits.
- C: improve the worst remaining placeholder-looking resource/building visuals using existing active assets or small procedural changes.
- D: validate Android/Godot import/runtime and node density after the new deposits, huts and resource landmarks.
- E: continue the settlement economy: manual placement UX, building requirements, simple resource progression and clearer objectives.

If you are active, pull now and log whether your lane needs a patch, Android test, or Container A decision.

## Active visual/performance sprint - 0.8.28

Container A pushed the RTS forest optimization pass as `0.8.28 RTS Forest Optimization`.

All helper containers must treat `0.8.28` as the newest base:

- B: verify settlers around the new forest masses, especially path turns near blocking forest clusters and nonblocking wood-source clusters.
- C: inspect the existing Kenney pine/tree assets and decide whether the next patch should promote a small set into active assets or keep the procedural MultiMesh forest.
- D: validate Android/Godot import/runtime and scene density after the tree clustering, mobile density cut and prop reduction.
- E: check gameplay readability: build/resource UI should still be clear now that forest masses take more visual space.

If you are active, pull now and log whether your lane needs a patch, Android test, asset promotion, or Container A decision.
