# Container E Task - Settlement Gameplay

Owner lane: settlement gameplay, resources, buildings, tasks, UI, life/social systems.

## Current assignment from Container A

Expand gameplay carefully after stability and people/world work are understood. Start by mapping current systems and proposing one safe next gameplay vertical.

Read first:

1. `WORKFLOW_FIRST.md`
2. `docs/CONTAINER_HANDOFF_PROMPT.md`
3. `docs/container_logs/CONTAINER_A_LOG.md`
4. `scripts/main.gd`
5. `project.godot`

Focus functions:

- `choose_work(v)`
- `job_duration(v)`
- `finish_job(v)`
- `make_build_site(p, kind)`
- `update_build_sites()`
- `make_house()`
- `make_granary()`
- `make_workshop()`
- `make_ui()`
- `set_order(s)`
- `update_settler_chat(d)`

## 35 minute check

While active or waiting, every 35 minutes check this file and `WORKFLOW_FIRST.md` for new Container A instructions.

## Subagents allowed

You may spawn subagents such as:

- E1: map resource economy and building costs.
- E2: design one next gameplay loop, for example food pressure, storage, or simple roles.
- E3: inspect UI/HUD impact for Android touch.

Subagents do not push. Container E owns the log and any commit.

## Write scope

Preferred first writes:

- `docs/container_logs/CONTAINER_E_LOG.md`
- `docs/gameplay/SETTLEMENT_GAMEPLAY_PLAN.md` if useful.

If implementing, keep the first change small and reversible. Avoid broad rewrites of `scripts/main.gd`.

Do not touch people animation, asset import policy, or Android workflow.

## Required report to Container A

Include:

1. What gameplay systems were checked.
2. Which files/functions matter.
3. Proposed next gameplay vertical.
4. Any changed files and commit SHA.
5. Risks for balance, UI and Android performance.
6. Clear recommendation: integrate / reject / wait / test on Android.
