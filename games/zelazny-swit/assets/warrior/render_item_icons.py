"""Render item icons from the exact playable equipment, using Blender 4.5+.

    blender --background --factory-startup --threads 2 --python-exit-code 1 \
      --python render_item_icons.py -- --samples 48 --size 256

No downloaded illustration or painted replacement is used. The weapon silhouette
and every visible plate, fitting, inlay and material come from the supplied GLB.
Armor icons omit the head, skin and separate gauntlet/boot parts so the cuirass,
shoulders, waist wrap and tassets remain readable at inventory size. This alters
only a disposable render mesh; source GLB and textures are never written.

Use --only weapon_3,armor_2 to rebuild selected icons. Paths default to this
script's directory; --warrior / --weapons / --output make the tool relocatable.
The last ITEM_ICON_RENDER_STATS line contains source hashes and render metadata.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import sys
import time
from urllib.parse import unquote

import bmesh
import bpy
from mathutils import Matrix, Vector


HERE = Path(__file__).resolve().parent


def arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--warrior", type=Path, default=HERE / "warrior.glb")
    parser.add_argument("--weapons", type=Path, default=HERE / "weapons.glb")
    parser.add_argument("--output", type=Path, default=HERE / "icons")
    parser.add_argument("--samples", type=int, default=48)
    parser.add_argument("--size", type=int, default=256)
    parser.add_argument("--only", default="")
    parser.add_argument("--armor-min-z", type=float, default=0.68)
    args = parser.parse_args(argv)
    if not 16 <= args.samples <= 256 or not 64 <= args.size <= 1024:
        parser.error("Samples must be 16..256; icon edge must be 64..1024.")
    if not 0.35 <= args.armor_min_z <= 1.1:
        parser.error("Armor crop must be 0.35..1.1 metres.")
    return args


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def external_images(source: Path) -> list[Path]:
    """Track atlas files too: the HD GLB intentionally shares external maps."""
    data = source.read_bytes()
    if data[:4] != b"glTF":
        raise ValueError(f"Expected a binary glTF equipment file: {source}")
    length, kind = struct.unpack_from("<I4s", data, 12)
    if kind != b"JSON":
        raise ValueError(f"Missing glTF JSON chunk: {source}")
    document = json.loads(data[20 : 20 + length])
    paths = []
    for image in document.get("images", []):
        uri = image.get("uri", "")
        if uri and not uri.startswith("data:"):
            if "://" in uri:
                raise ValueError("Item rendering requires local, offline texture images.")
            path = (source.parent / unquote(uri)).resolve()
            if not path.is_file():
                raise FileNotFoundError(path)
            paths.append(path)
    return paths


def imported_mesh(name: str) -> bpy.types.Object:
    obj = bpy.data.objects.get(name)
    if obj is None or obj.type != "MESH":
        raise RuntimeError(f"Expected actual equipment mesh {name!r} in GLB.")
    return obj


def render_copy(source: bpy.types.Object, *, armor: bool, min_z: float) -> bpy.types.Object:
    """Freeze the imported rest skin into a disposable, world-space render mesh."""
    bpy.context.view_layer.update()
    evaluated = source.evaluated_get(bpy.context.evaluated_depsgraph_get())
    data = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True,
                                         depsgraph=bpy.context.evaluated_depsgraph_get())
    data.transform(source.matrix_world)
    if armor:
        # Keep the wearable central silhouette, excluding detached gauntlets and
        # shin/foot pieces. Skin bone names identify parts without guessing RGB.
        group_names = {group.index: group.name.lower() for group in source.vertex_groups}
        excluded = ("lowerarm", "hand", "calf", "foot", "finger", "thumb")
        discard_vertices = set()
        for vertex in data.vertices:
            excluded_weight = sum(group.weight for group in vertex.groups
                                  if group_names.get(group.group, "").startswith(excluded))
            if excluded_weight > 0.6:
                discard_vertices.add(vertex.index)
        bm = bmesh.new()
        bm.from_mesh(data)
        bm.verts.ensure_lookup_table()
        discard = [face for face in bm.faces
                   if all(vertex.index in discard_vertices for vertex in face.verts)]
        if discard:
            bmesh.ops.delete(bm, geom=discard, context="FACES")
        # A close bust crop includes the articulated waist plates, while the
        # character's long hanging silk does not reduce the chest to a few pixels.
        bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                              plane_co=(0, 0, min_z), plane_no=(0, 0, 1),
                              clear_inner=True, clear_outer=False, dist=0.000001)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(data)
        bm.free()
    data.update()
    obj = bpy.data.objects.new("Actual equipment for icon", data)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def setup_scene(size: int, samples: int) -> bpy.types.Scene:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 6
    scene.cycles.diffuse_bounces = 3
    scene.cycles.glossy_bounces = 4
    scene.cycles.transparent_max_bounces = 4
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.image_settings.compression = 70
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.exposure = 0.1
    world = bpy.data.worlds.new("Neutral studio reflections")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.22, 0.25, 0.29, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    scene.world = world
    return scene


def area_light(name: str, location: Vector, target: Vector, power: float,
               color: tuple[float, float, float], size: float) -> None:
    light = bpy.data.lights.new(name, "AREA")
    light.energy = power
    light.color = color
    light.shape = "DISK"
    light.size = size
    obj = bpy.data.objects.new(name, light)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def studio_camera(obj: bpy.types.Object, armor: bool) -> tuple[float, Vector]:
    vertices = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    if not vertices:
        raise RuntimeError("Item render would have no actual geometry.")
    lower = Vector(tuple(min(v[axis] for v in vertices) for axis in range(3)))
    upper = Vector(tuple(max(v[axis] for v in vertices) for axis in range(3)))
    target = (lower + upper) * 0.5
    # Warrior meshes face +Y in Blender; the weapon's authored broad blade face
    # faces -Y. A very slight three-quarter view reveals the physical bevels.
    direction = Vector((0.17, 1.0, 0.09) if armor else (0.06, -1.0, 0.045)).normalized()
    data = bpy.data.cameras.new("Item orthographic camera")
    camera = bpy.data.objects.new("Item orthographic camera", data)
    bpy.context.scene.collection.objects.link(camera)
    camera.location = target + direction * 5
    camera.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    data.type = "ORTHO"
    bpy.context.view_layer.update()
    inverse = camera.matrix_world.inverted()
    projected = [inverse @ vertex for vertex in vertices]
    width = max(v.x for v in projected) - min(v.x for v in projected)
    height = max(v.y for v in projected) - min(v.y for v in projected)
    # Center projected geometry exactly, including asymmetric saber tips/tassets.
    offset = Vector(((max(v.x for v in projected) + min(v.x for v in projected)) * 0.5,
                     (max(v.y for v in projected) + min(v.y for v in projected)) * 0.5, 0))
    camera.location += camera.matrix_world.to_3x3() @ offset
    data.ortho_scale = max(width, height) * 1.10
    bpy.context.scene.camera = camera
    front = 1.0 if armor else -1.0
    area_light("Broad warm key", target + Vector((-2.8, front * 3.5, 3.6)), target,
               650, (1.0, 0.92, 0.82), 3.2)
    area_light("Cool metal fill", target + Vector((3.0, front * 2.5, 0.9)), target,
               440, (0.72, 0.84, 1.0), 2.8)
    area_light("Fine pale rim", target + Vector((-1.6, -front * 2.4, 2.1)), target,
               900, (0.84, 0.91, 1.0), 2.2)
    return data.ortho_scale, upper - lower


def render_icon(kind: str, tier: int, source: Path, output: Path,
                args: argparse.Namespace) -> dict:
    started = time.monotonic()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    armor = kind == "armor"
    source_object = imported_mesh(f"Armor{tier}" if armor else f"Weapon{tier}Mesh")
    obj = render_copy(source_object, armor=armor, min_z=args.armor_min_z)
    for imported in list(bpy.context.scene.objects):
        if imported != obj:
            imported.hide_render = True
    if not armor:
        # The authored blade points down from its grip. Rotate the whole actual
        # mesh into a consistent lower-left grip / upper-right tip inventory pose.
        obj.data.transform(Matrix.Rotation(math.radians(-145), 4, "Y"))
        obj.data.update()
    scene = setup_scene(args.size, args.samples)
    scale, bounds = studio_camera(obj, armor)
    output.mkdir(parents=True, exist_ok=True)
    destination = output / f"{kind}_{tier}.png"
    scene.render.filepath = str(destination)
    bpy.ops.render.render(write_still=True)
    image = bpy.data.images.load(str(destination), check_existing=False)
    pixels = image.pixels[:]
    alpha = pixels[3::4]
    coverage = sum(value > 0.01 for value in alpha) / len(alpha)
    edge_alpha = max([alpha[x] for x in range(args.size)] +
                     [alpha[(args.size - 1) * args.size + x] for x in range(args.size)] +
                     [alpha[y * args.size] for y in range(args.size)] +
                     [alpha[y * args.size + args.size - 1] for y in range(args.size)])
    if min(alpha) != 0.0 or not 0.04 < coverage < 0.85 or edge_alpha > 0.01:
        raise RuntimeError(f"Icon transparency/framing check failed: {destination.name}; "
                           f"coverage={coverage:.3f}, edge_alpha={edge_alpha:.3f}")
    bpy.data.images.remove(image)
    obj.data.calc_loop_triangles()
    return {"item": f"{kind}_{tier}", "file": destination.name,
            "size": [args.size, args.size], "transparent": True,
            "samples": args.samples, "rendered_triangles": len(obj.data.loop_triangles),
            "bounds_metres": [round(float(value), 5) for value in bounds],
            "orthographic_scale": round(scale, 5),
            "alpha_coverage": round(coverage, 5), "max_border_alpha": edge_alpha,
            "seconds": round(time.monotonic() - started, 3),
            "png_bytes": destination.stat().st_size, "png_sha256": digest(destination)}


def main() -> None:
    args = arguments()
    sources = {"weapon": args.weapons.resolve(), "armor": args.warrior.resolve()}
    for source in sources.values():
        if not source.is_file():
            raise FileNotFoundError(source)
    items = [("weapon", tier) for tier in range(4)] + [("armor", tier) for tier in range(1, 4)]
    if args.only:
        selected = set(args.only.split(","))
        valid = {f"{kind}_{tier}" for kind, tier in items}
        if selected - valid:
            raise ValueError(f"Unknown item names: {sorted(selected - valid)}")
        items = [(kind, tier) for kind, tier in items if f"{kind}_{tier}" in selected]
    hashes = {kind: digest(path) for kind, path in sources.items()}
    dependencies = sorted(set(path for source in sources.values() for path in external_images(source)))
    atlas_hashes = {path.name: digest(path) for path in dependencies}
    results = [render_icon(kind, tier, sources[kind], args.output.resolve(), args)
               for kind, tier in items]
    if ({kind: digest(path) for kind, path in sources.items()} != hashes or
            {path.name: digest(path) for path in dependencies} != atlas_hashes):
        raise RuntimeError("Source equipment changed while rendering; freeze assets and rerun.")
    print("ITEM_ICON_RENDER_STATS " + json.dumps({"blender": bpy.app.version_string,
          "source_sha256": hashes, "atlas_sha256": atlas_hashes, "icons": results}, sort_keys=True))


if __name__ == "__main__":
    main()
