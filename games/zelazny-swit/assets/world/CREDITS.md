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
render pass. Plants use bounded opaque triangles merged into existing scenery
material batches. Seven drifting forge embers share one MultiMesh draw call.
Distant ridges have their own matte vertex color and scene fog, without tiled
rock maps or shadow passes. No screen blur, glow, or new shadow-casting light is added.

Authoring (not needed on the phone):

```bash
python assets/world/build_materials.py
```
