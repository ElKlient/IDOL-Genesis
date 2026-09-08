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
