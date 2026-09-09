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

## Round 0.8.25 urgent instruction from Container A

The user rejected the current look as still too artificial. Base is now `0.8.25 Grounded Settlement Pass`, with organic ground patches, continuous river, terrain mesh, horizon mass and grounded people shadows.

Your job now:

1. Pull latest `main` and inspect the active environment assets already promoted under `assets/environment/`.
2. Find the fastest mobile-safe replacement for the toy-looking parts: trees, roofs, ground clutter, stockpile, fences, river props or house details.
3. Prefer one small implemented patch over another broad plan. Promote only selected assets that directly improve the first Android screenshot.
4. Keep people animation, resource balance and UI out of your patch.
5. If no asset is good enough, write a concrete rejection report naming which visible objects must remain procedural for now and what asset would be needed.

Priority visual targets:

- less plastic/red roof treatment,
- less repetitive round trees,
- stronger dirt/stone/wood clutter near the Idol plaza,
- better background edge so the map no longer reads as a toy board.

## Round 0.8.26 instruction from Container A

Base is now `0.8.26 Earth and Shelter Polish`. Container A muted roofs, added object shadows, grit, twigs, stones and rougher tree silhouettes.

Your job now:

1. Pull latest `main` and inspect the first viewport composition from the code.
2. Pick the single worst remaining toy-looking category: trees, huts/roofs, fences, river edges, stockpile or ground clutter.
3. Prefer a small implemented patch using existing active assets or safe procedural mesh changes.
4. Do not add a broad new asset pack and do not touch people, gameplay balance, UI layout or Android commands.
5. If implementing trees, keep mobile count controlled through `world_count()` and avoid expensive materials.

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

## Round 0.8.27 instruction from Container A

Base is now `0.8.27 Resource Infrastructure`. Container A added visible deposits and first-pass resource buildings, but some may still look procedural.

Your job now:

1. Pull latest `main` and inspect the new resource visuals in `scripts/main.gd`.
2. Pick the worst remaining placeholder category: mineral deposits, forest sources, fish huts, lumber camp, quarry, mine or hunter hut.
3. Prefer a small mobile-safe implemented patch using existing active assets from `assets/environment/` or simple mesh polish.
4. Do not import a broad new pack and do not touch people animation, economy balance, UI commands or Android workflow.
5. If no asset is good enough, write a concrete asset plan naming exactly which object should be replaced later.

Focus functions:

- `make_resource_landmarks()`
- `add_mineral_deposit()`
- `add_forest_source()`
- `add_fish_source()`
- `make_lumber_camp()`
- `make_hunter_hut()`
- `make_fisher_hut()`
- `make_quarry()`
- `make_mine()`

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
