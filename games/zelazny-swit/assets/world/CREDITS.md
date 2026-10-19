# World materials

`build_materials.py` creates the original tileable maps in this directory using
NumPy and Pillow. No downloaded textures, extracted game assets, or runtime
plugins are required. The hand-built village is original project content.

Eight shared material families: packed earth, grass, stone, plaster, timber,
ceramic roof, woven cloth and hand-laid paving. Albedo sources are 512 × 512;
normal maps are reduced once to 256 × 256 in the material cache. Both receive
mipmaps to keep detail stable in motion. Runtime materials are shared across
all merged scenery and the two vendors.

The opaque pond shader uses two slow wave terms and restrained highlights.
It does not read the screen, depth buffer, or reflections, and needs no extra
render pass. Grass and ferns use opaque triangles in one wind-driven surface.
Pine sprays use the original `pine_spray.png` alpha-scissor texture in one
shared surface with actual mipmaps. Seven forge embers share one MultiMesh.
Distant ridges have their own matte vertex color and scene fog, without tiled
rock maps or shadow passes. No screen blur, glow, or new shadow-casting light is added.

Authoring (not needed on the phone):

```bash
python assets/world/build_materials.py
python assets/world/build_terrain_mask.py
python assets/world/build_pine_spray.py
```

Since 0.2.2 `build_materials.py` invokes `build_courtyard.py` for the current
irregular weathered cobbles. `terrain_control.png` is a 512-square RGBA data
map: earth/paving/colour variation/contact shade. It blends six existing
colour/normal resources on one opaque plane. The 256x512 needle atlas and
the control map have one shared mip chain each. Both are original generated
project content. No external texture licence or runtime authoring dependency
is introduced. Low quality hides the added meadow and skips terrain normals.
