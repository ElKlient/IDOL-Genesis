# Container C Task - Assets And Environment

Owner lane: model packs, selected assets, settlement environment, mobile-safe visual quality.

## Current assignment from Container A

Find the best lightweight path to improve the world visually without killing Android performance.

Read first:

1. `WORKFLOW_FIRST.md`
2. `docs/CONTAINER_HANDOFF_PROMPT.md`
3. `docs/container_logs/CONTAINER_A_LOG.md`
4. `assets/third_party_model_packs/README.md`
5. `scripts/main.gd`
6. `project.godot`

Focus areas:

- `make_terrain_layers()`
- `make_world_details()`
- `make_ancient_settlement_scene()`
- `make_hide_rack_at()`
- `make_tool_yard()`
- `make_wild_deer()`
- vendor source under `assets/third_party_model_packs/`

## 35 minute check

While active or waiting, every 35 minutes check this file and `WORKFLOW_FIRST.md` for new Container A instructions.

## Subagents allowed

You may spawn subagents such as:

- C1: inventory available GLB/GLTF packs and license notes.
- C2: estimate mobile risk and propose asset budget.
- C3: map which procedural props should later be replaced by real assets.

Subagents do not push. Container C owns the log and any commit.

## Write scope

Preferred first writes:

- `docs/container_logs/CONTAINER_C_LOG.md`
- `docs/assets/ENVIRONMENT_ASSET_PLAN.md` if useful.

Do not import whole model packs into active gameplay. Promote only selected assets into normal game folders after checking size, license and Android cost.

Do not touch people animation or gameplay balance.

## Required report to Container A

Include:

1. What asset/world areas were checked.
2. Which files/functions matter.
3. Candidate assets to use now/later.
4. Any changed files and commit SHA.
5. Android/import/performance risks.
6. Clear recommendation: integrate / reject / wait / test on Android.
