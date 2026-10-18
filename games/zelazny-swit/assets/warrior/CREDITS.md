# Warrior assets

The skinned human body, eyes, eyebrows and source hairstyle derive from
**Universal Base Characters — Standard**, by **Quaternius**, licensed under
**CC0 1.0 Universal**. The author's original notice is retained in
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
of hairstyles; paid Regular/Teen bodies and paid Blender source files are
not included in this project.

The exported warrior includes changes to the bind pose, skinning, hidden-body
geometry, scale, facing and materials. The fingers are closed around the grip.
The original parted-hair geometry and normal map are retained; its color atlas
is darkened to black, and the eyebrows use a dark material. The body and hair
retain their CC0 dedication. The armor designs are original additions created
for Żelazny Świt and follow the project license.
The four swords in `weapons.glb` are original project meshes. They do not use
models, textures or costume designs extracted from Metin2.

`build_warrior.py` and `build_weapons.py` retain the Blender generation
workflow. The game uses their exported GLB files directly; Blender and the
source asset archive are not required on the phone.

To regenerate with Blender 4.5 or later, download and extract the author's free
Standard archive. From this directory, substitute its extraction path below:

```bash
blender --background --factory-startup --python build_warrior.py -- \
  --source "/path/Universal Base Characters[Standard]/Base Characters/Godot - UE/Superhero_Male_FullBody.gltf" \
  --hair "/path/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Hair_SimpleParted.gltf"
blender --background --factory-startup --python build_weapons.py
```

Keep each source glTF beside its BIN and referenced PNG files. The upstream
body glTF references `T_Hair_1_Normal_png.png` and `T_Eye_Normal_png.png`;
if those names are absent, copy the pack's corresponding `T_Hair_1_Normal.png`
and `T_Eye_Normal.png` files under the referenced names before importing.
