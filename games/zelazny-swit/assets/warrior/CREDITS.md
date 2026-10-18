# Warrior assets — 0.2.0

## CC0 human base and hair

The skinned human body, eyes, eyebrows and source hairstyle derive from
**Universal Base Characters — Standard**, by **Quaternius**, licensed under
**CC0 1.0 Universal**. The author's original notice is retained verbatim in
`QUATERNIUS-LICENSE.txt`.

- Official pack: https://quaternius.com/packs/universalbasecharacters.html
- Official download: https://quaternius.itch.io/universal-base-characters
- License: https://creativecommons.org/publicdomain/zero/1.0/
- Source body: `Base Characters/Godot - UE/Superhero_Male_FullBody.gltf`
- Source hair: `Hairstyles/Origin at 0/glTF (Godot)/Hair_SimpleParted.gltf`
- Verified from the author's pages and free Standard archive on 2026-10-18.
- Standard archive SHA-256:
  `fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40`
- Source body BIN SHA-256:
  `459003f9745853ae562a85506a2b94dd56515c1f37728f9fa3d2ce1a3e4cd92f`

The source BIN was compared byte for byte with the official download. The
free Standard pack contains the Superhero Male/Female bases and a selection
of hairstyles. Paid Regular/Teen bodies and paid Blender source files are
not included or required by this project.

The exported warrior changes the bind pose, skinning, hidden-body geometry,
scale, facing and materials. Fingers close around the grip. The original
parted-hair geometry and normal map are retained; its color atlas is darkened
to black, and the eyebrows use a dark material. The modified body and hair
retain their CC0 dedication.

## Original equipment and material atlas

The three equipment families — **Karmazynowa Straż**, **Jadeitowa Brama** and
**Popielny Żar** — have original modelled armour, cloth panels, fittings,
insignia and weapon designs prepared for Żelazny Świt. `weapons.glb` contains
the starter sword and three original equipped swords. The original project
additions are not automatically covered by Quaternius's CC0 notice. No model,
texture, costume, animation or map was extracted from Metin2.

`build_warrior_hd.py` builds the current skinned body and equipment variants;
`build_weapons_hd.py` builds the current swords. `equipment_materials.py`
generates the original PBR atlas used by both. Standard glTF materials use
base color, tangent-space normals, occlusion, roughness, metallic and emission
textures. Different equipment regions share a material through UV atlas
coordinates. The blade has its own material using the shared atlas images
and a separate emission mask, so an upgrade can illuminate the blade without
illuminating the wearer or leather grip.

The exported GLBs intentionally reference canonical local PNGs instead of
embedding duplicate equipment images. Keep all five files beside both GLBs:

| File | Purpose |
| --- | --- |
| `equipment_color.png` | sRGB base color |
| `equipment_normal.png` | Non-color tangent-space normal, OpenGL +Y |
| `equipment_orm.png` | Non-color R = occlusion, G = roughness, B = metallic |
| `equipment_emission.png` | Jade and ember accents |
| `equipment_blade_emission.png` | Restrained honing/engraving mask for blade upgrades |

Skin, eye and hair maps remain embedded. `externalize_atlas_images()` in
`equipment_materials.py` rewrites only the named equipment images to relative
PNG URIs and compacts their former binary buffer views. It preserves the
embedded human-source images, geometry, accessors and skin data.

`equipment_material_stats.json` records atlas roles, channels and image hashes.
`warrior_stats.json` and `warrior_rig.json` are generated alongside the model.
The old `build_warrior.py` and `build_weapons.py` are retained as the historical
0.1.8 authoring pipeline; use the `_hd.py` scripts for the current assets.

## Rebuild the current models

Use Blender 4.5 or later. No Blender add-ons are required; NumPy is included
with Blender. Download and extract the author's free Standard archive. Run
the following from this directory, substituting the actual extraction paths:

```bash
blender --background --factory-startup --python-exit-code 1 \
  --python equipment_materials.py

blender --background --factory-startup --python-exit-code 1 \
  --python build_warrior_hd.py -- \
  --source "/path/Universal Base Characters[Standard]/Base Characters/Godot - UE/Superhero_Male_FullBody.gltf" \
  --hair "/path/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Hair_SimpleParted.gltf"

blender --background --factory-startup --python-exit-code 1 \
  --python build_weapons_hd.py
```

Keep each source glTF beside its BIN and referenced PNG files. The upstream
body glTF references `T_Hair_1_Normal_png.png` and `T_Eye_Normal_png.png`;
if those names are absent, copy the pack's corresponding `T_Hair_1_Normal.png`
and `T_Eye_Normal.png` files under the referenced names before importing.

The body generator requires `--source` and `--hair`. Its optional `--render`
and `--preview-dir /path/to/previews` flags render the actual generated model.
The sword generator accepts an optional `--render /path/to/previews` after
Blender's `--` separator. Preview lights and cameras are authoring tools;
they are not required to load the exported equipment in Godot.

## Render the seven actual item icons

After both GLBs and the five atlas PNGs are final, run from this directory:

```bash
blender --background --factory-startup --threads 2 --python-exit-code 1 \
  --python render_item_icons.py -- --samples 48 --size 256
```

The default output is `icons/weapon_0.png` through `icons/weapon_3.png` and
`icons/armor_1.png` through `icons/armor_3.png`. These are transparent renders
of the actual equipment GLBs, not concept illustrations or separately painted
replacement items. Armour icons omit the head and separate limb pieces and
crop long cloth to keep the cuirass, shoulders and waist readable at inventory
size; the source GLB is not modified.

The renderer supports `--warrior`, `--weapons` and `--output` paths,
`--samples`, `--size`, `--armor-min-z`, and an optional selection such as
`--only weapon_3,armor_2`. Its final `ITEM_ICON_RENDER_STATS` output records
source GLB hashes, shared atlas hashes and icon render metadata. It checks
that the source assets did not change during rendering.

## Offline runtime

Blender, the source archive and these authoring scripts are not required on
the phone. Godot loads the committed GLB and PNG files locally. The game does
not fetch character packs, textures, animations or plugins during play.
The original world-material pipeline is documented separately in
`../world/CREDITS.md`; it creates eight albedo/normal pairs used by the village.
