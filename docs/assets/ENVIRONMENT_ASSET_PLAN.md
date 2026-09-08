# Environment Asset Plan - Container C

Status: proposed lightweight integration path.
Scope: environment/assets only. Preserve current people model, AI, walking, work loops, gameplay balance, and retargeter.

## Goal

Improve the stone-age / early-medieval settlement visually while keeping Android import time, package size, draw cost, and workflow risk low.

## Current Constraints

- Godot 4.x Android project using the existing procedural world in `scripts/main.gd`.
- Vendor packs live under `assets/third_party_model_packs/` and are protected by `.gdignore`.
- Do not import full model packs into the active project.
- Promote only selected assets into normal game folders after size/license checks.
- Keep procedural fallbacks until imported assets are verified on Android.

## Phase 1 - Safe Kenney GLB Props

Create `assets/environment/kenney_survival/` and copy only the selected `.glb` files. Expected source payload is well under 200 KB for the first pass, before Godot import artifacts.

| World Need | Candidate Asset | Suggested Integration Point |
| --- | --- | --- |
| Wood stockpile | `kenney_survival_kit_glb/models/resource-wood.glb` | Existing stockpile/wood detail helpers |
| Stone stockpile | `kenney_survival_kit_glb/models/resource-stone.glb` | Existing stone source/stockpile details |
| Tool yard | `tool-axe.glb`, `tool-pickaxe.glb`, `tool-hammer.glb` | `make_tool_yard()` |
| Work area | `workbench.glb` | Existing workshop/work area helper |
| Sleeping area | `bedroll.glb` or `bedroll-packed.glb` | Around shelter/home props |
| Fire pit | `campfire-pit.glb` or `campfire_logs.glb` | Existing hearth, keep procedural flame/light |
| River camp | `canoe.glb`, `canoe_paddle.glb` | Riverbank detail helper |
| Small palisade/fence | `fence.glb` or Nature `fence_simple*.glb` | Sparse settlement edge dressing |

Rules for Phase 1:

- Use one preload table or helper, not scattered hardcoded loads.
- Keep scale/rotation corrections close to the spawn helper.
- Add collision/obstacles only for large blockers.
- Limit repeated instances until Container D confirms Android performance.
- If an asset fails import or appears oversized, fall back to the existing procedural prop.

## Phase 2 - Single KayKit Building Test

Only after Container D confirms import/build health, promote one KayKit building as a controlled test.

| World Need | Candidate Asset Group | Notes |
| --- | --- | --- |
| Granary/spichlerz | `gltf/buildings/neutral/building_grain.gltf` + matching `.bin` + `hexagons_medieval.png` | Good first test: thematically useful and isolated. |
| Well | One `building_well_*.gltf` + dependencies | Good second test if granary scale/materials work. |
| Home shell | One `building_home_A_*.gltf` + dependencies | Later, because shelters affect the core settlement silhouette. |

Rules for KayKit:

- Copy `.gltf`, the matching `.bin`, and the local atlas texture into a dedicated folder such as `assets/environment/kaykit_medieval/grain/`.
- Use one or two instances first.
- Keep the existing procedural settlement as fallback.
- Do not replace the terrain with KayKit hex terrain in this pass.

## Later Or Rejected For Now

- Kenney Mini Characters: reject for now. Container B owns people/animation, and the current human model must be preserved.
- Full KayKit hex terrain/rivers: wait. This would become a terrain rewrite and risks AI/path/camera behavior.
- Blacksmith/steel props: wait until the later steel progression is ready.
- External deer/wildlife packs: wait until Android performance and animation ownership are stable.

## Main.gd Touch Points

Likely safe functions to update in a later implementation pass:

- `make_world_details()`
- `make_ancient_settlement_scene()`
- `make_hide_rack_at()`
- `make_tool_yard()`
- existing campfire/hearth helpers
- existing stockpile/resource detail helpers
- existing riverbank detail helpers

Avoid changing:

- people mesh/skeleton/animation code
- retargeter logic
- AI task selection
- resource balance
- navigation assumptions unless a promoted prop needs a small blocker

## Required Gates

For documentation-only updates:

- `git diff --check`

For any asset or code integration:

- `git diff --check`
- Godot editor import:
  `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit`
- Godot runtime:
  `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit`
- Android smoke test or Container D confirmation before scaling instance counts.

## Recommendation To Container A

Integrate this plan now as the Container C asset direction. Wait for Container D's import/performance pass and Container B's animation stabilization before promoting real assets into active scenes. The first actual implementation pass should be limited to the Phase 1 Kenney GLB set with procedural fallbacks left in place.
