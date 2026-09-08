# Third-Party Model Packs

Downloaded asset packs for IDOL Genesis prototype work. These files are kept separate from custom game assets so they can be reviewed, replaced, or optimized without touching gameplay code.

## Included Packs

| Folder | Source | License | Imported files | Use in IDOL Genesis |
| --- | --- | --- | --- | --- |
| `kenney_nature_kit_glb` | https://opengameart.org/content/nature-kit / https://kenney.nl/assets/nature-kit | CC0 1.0 | 329 GLB models | Trees, rocks, plants, cliffs, crops, bridges, camp objects |
| `kenney_survival_kit_glb` | https://opengameart.org/content/survival-kit / https://kenney.nl/assets/survival-kit | CC0 1.0 | 80 GLB models | Tools, resources, tents, crates, campfires, workbenches |
| `kenney_mini_characters_glb` | https://opengameart.org/content/mini-character-1 / https://kenney.nl/assets/mini-characters | CC0 1.0 | 26 GLB models | Prototype villagers and character-scale testing |
| `kaykit_medieval_hexagon_pack` | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 / https://kaylousberg.itch.io/kaykit-medieval-hexagon | CC0 1.0 | glTF/bin/png atlas files | RTS village buildings, roads, rivers, resource buildings, props |

## Import Notes

- Prefer GLB or glTF files in Godot 4.
- Keep these folders vendor-style and add game-specific edited models elsewhere.
- If a model is promoted into the main scene, create a small wrapper scene under the game's own assets folder instead of editing the third-party source file directly.
- These packs are CC0, but attribution to Kenney/KayKit is still kept here for traceability.

## Container C Promotion Shortlist

`assets/third_party_model_packs/` is vendor source and contains `.gdignore`, so promoted gameplay assets should be copied selectively into normal game asset folders before they are preloaded or instanced in Godot.

Good first-pass Android candidates:

| Use | Candidate | Why |
| --- | --- | --- |
| Stockpile wood | `kenney_survival_kit_glb/models/resource-wood.glb` | Single-file GLB, about 8 KB, clearer than procedural stick boxes. |
| Stockpile stone | `kenney_survival_kit_glb/models/resource-stone.glb` | Single-file GLB, about 8 KB, good for readable resource piles. |
| Tool yard | `kenney_survival_kit_glb/models/tool-axe.glb`, `tool-pickaxe.glb`, `tool-hammer.glb` | 8-12 KB each, useful as static tools without touching human bones. |
| Workshop | `kenney_survival_kit_glb/models/workbench.glb` | About 26 KB, strong visual anchor for crafting. |
| Homes/camp | `kenney_survival_kit_glb/models/bedroll.glb`, `tent-canvas-half.glb` | Small living-area props that fit the early settlement. |
| River | `kenney_nature_kit_glb/models/canoe.glb`, `canoe_paddle.glb` | 16 KB + 4 KB, good storytelling near the river. |
| Fire | `kenney_survival_kit_glb/models/campfire-pit.glb` or `kenney_nature_kit_glb/models/campfire_logs.glb` | Better fire base while keeping existing cheap flame/light code. |
| Fences | `kenney_survival_kit_glb/models/fence.glb` or `kenney_nature_kit_glb/models/fence_simple*.glb` | Cheap palisade/settlement boundary pieces. |

KayKit is best used sparingly for buildings and larger props. Copy each chosen `.gltf` together with its matching `.bin` and the local `hexagons_medieval.png` atlas from the same folder. Best later candidates are `buildings/neutral/building_grain.gltf`, one `building_home_A_*.gltf`, one `building_well_*.gltf`, and small props such as `decoration/props/sack.gltf`, `bucket_*.gltf`, `weaponrack.gltf`, or `wheelbarrow.gltf`.

Do not use Kenney Mini Characters as villagers in the current phase; the active human model, AI, walking, and retargeter must stay in place.
