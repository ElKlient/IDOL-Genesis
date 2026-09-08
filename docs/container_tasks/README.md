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
