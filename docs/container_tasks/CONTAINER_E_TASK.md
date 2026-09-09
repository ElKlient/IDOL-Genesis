# Container E Task - Settlement Gameplay

Owner lane: settlement gameplay, resources, buildings, tasks, UI, life/social systems.

## Current assignment from Container A

Expand gameplay carefully after stability and people/world work are understood. Start by mapping current systems and proposing one safe next gameplay vertical.

## Round 0.8.20 instruction from Container A

After the `Living World` patch lands, review the hunt/hides loop:

1. Check `stock.meat`, `stock.hides`, `wildlife`, `assign_hunt(v)`, `finish_hunt(v)`, `choose_work(v)`, `job_duration(v)` and `deposit_carry(v)`.
2. Decide whether hides should become clothing warmth/comfort, workshop material, or a later tanning chain using the existing hide yard.
3. Keep the next gameplay change small: no expanded hunting system until D confirms Android stability and B confirms people still move well.
4. Do not add a new big UI panel. Use concise HUD/status text only.

Report one recommended next gameplay vertical for Container A to approve.

## Round 0.8.25 urgent instruction from Container A

Base is now `0.8.25 Grounded Settlement Pass`. The user's current complaint is mainly visual/presentation: the game still reads too much like a debug prototype instead of a living settlement.

Your job now:

1. Pull latest `main` and inspect `make_ui()`, HUD/status text and settlement command flow.
2. Design one small UI/game-presentation improvement that makes the Android screen less debug-heavy while preserving all current controls.
3. Preferred patch: a settlement presentation/readability cleanup, not a new big panel or feature system.
4. Keep terrain, asset imports, people animation and Android workflow out of your patch.
5. Report whether Container A should next approve a simplified HUD mode, contextual command grouping, or a stronger settlement objective presentation.

Watch especially:

- top-left HUD density,
- selected-person panel dominance,
- bottom chat panel position over the world,
- command grid readability with lighter panel opacity from 0.8.25.

## Round 0.8.26 instruction from Container A

Base is now `0.8.26 Earth and Shelter Polish`. The world got more visual detail, so the next presentation risk is that the HUD still makes the screen feel like a debug prototype.

Your job now:

1. Pull latest `main`.
2. Propose or implement one small presentation patch: compact HUD mode, cleaner selected-person panel, or command grouping.
3. Preserve all existing touch controls and commands.
4. Do not touch terrain, art assets, people animation, Android workflow or resource balance.
5. Report whether Container A should approve a bigger UI pass after visual work stabilizes.

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

## Round 0.8.27 instruction from Container A

Base is now `0.8.27 Resource Infrastructure`. Container A implemented the first resource economy vertical: wood, fish, iron, coal, copper, resource sources, new buildings, worker jobs, build menu and HUD.

Your job now:

1. Pull latest `main`.
2. Review the resource loop for balance and player clarity: costs, capacities, AUTO priorities, chapter goals and HUD readability.
3. Design or implement the next small gameplay patch for manual building placement: select building, show legal resource-adjacent locations, confirm/cancel.
4. Preserve current touch controls and do not add a giant management screen.
5. Do not touch terrain art, people animation, asset imports or Android workflow.

Focus functions:

- `building_cost(kind)`
- `pick_build_pos(kind)`
- `queue_build_plan(kind)`
- `is_build_pos_clear_for_kind(p, kind)`
- `make_ui()`
- `set_order(s)`
- `chapter_goal()`
- `choose_work(v)`

## Round 0.8.28 instruction from Container A

Base is now `0.8.28 RTS Forest Optimization`. The world has larger forest masses and less random small clutter, so the next gameplay work must preserve readability around resources and building placement.

Your job now:

1. Pull latest `main`.
2. Review whether forest sources, deposits, fish spots and build buttons remain readable under the current HUD.
3. Prepare the next small manual-placement patch only after confirming the new forest masses do not hide legal/illegal building feedback.
4. Keep touch controls compact and avoid adding a large management screen.
5. Do not touch terrain art, people animation, asset imports or Android workflow.

Report whether manual placement should start with ghost previews near resource sources or with a simpler "let them choose" build mode first.

## 30 minute check

While active or waiting, every 30 minutes check this file and `WORKFLOW_FIRST.md` for new Container A instructions.

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
