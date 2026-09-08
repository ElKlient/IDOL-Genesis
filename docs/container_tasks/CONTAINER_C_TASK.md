# Container C Task - Assets And Environment

Owner lane: model packs, selected assets, settlement environment, mobile-safe visual quality.

## Current assignment from Container A

Find the best lightweight path to improve the world visually without killing Android performance.

## Round 0.8.20 instruction from Container A

After the `Living World` patch lands, do the first real asset promotion plan:

1. Choose only 4-6 tiny GLB assets from the Container C shortlist.
2. Prefer resource wood, resource stone, workbench, bedroll, canoe/paddle, campfire or fence.
3. Create a plan for a normal game asset folder, not direct use from `.gdignore` vendor source.
4. Estimate import/FPS risk for Android.
5. Do not replace the current people model or add animated animals yet.

If you implement, promote only a tiny set and keep procedural fallbacks in `scripts/main.gd`.

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

## 30 minute check

While active or waiting, every 30 minutes check this file and `WORKFLOW_FIRST.md` for new Container A instructions.

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
