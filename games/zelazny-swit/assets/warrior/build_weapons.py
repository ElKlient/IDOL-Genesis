"""Original mobile sword meshes for Żelazny Świt, authored in Blender.

Run: blender --background --factory-startup --python build_weapons.py
The exported coordinates are Godot local axes: grip at origin, blade toward -Y.
No source models, copied game assets, textures or shader effects are used.
"""
from pathlib import Path
import json
import math
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)


def xyz(point):
    """Desired Godot local axes -> Blender, whose glTF exporter writes Y-up."""
    x, y, z = point
    return (x, -z, y)


def material(name, color, metallic, roughness):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Metallic'].default_value = metallic
    shader.inputs['Roughness'].default_value = roughness
    return mat


def mesh(name, vertices, faces, mat, bevel=0.0):
    data = bpy.data.meshes.new(name)
    data.from_pydata([xyz(v) for v in vertices], [], faces)
    data.materials.append(mat)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    if bevel:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        mod = obj.modifiers.new('Forged edge bevel', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        mod.affect = 'EDGES'
        bpy.ops.object.modifier_apply(modifier=mod.name)
        obj.select_set(False)
    return obj


def extrusion(name, outline, depth, mat, center_z=0.0, bevel=0.0):
    n = len(outline)
    vertices = [(x, y, center_z - depth / 2) for x, y in outline]
    vertices += [(x, y, center_z + depth / 2) for x, y in outline]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    return mesh(name, vertices, faces, mat, bevel)


def blade(name, stations, mat):
    # A six-sided steel section makes real bevel planes and a raised central face.
    vertices = []
    for y, center, width, thickness in stations:
        for x, z in [(-.5, 0), (-.24, .5), (.24, .5), (.5, 0), (.24, -.5), (-.24, -.5)]:
            vertices.append((center + width * x, y, thickness * z))
    faces = [tuple(reversed(range(6)))]
    for i in range(len(stations) - 1):
        a, b = i * 6, (i + 1) * 6
        faces += [(a + k, a + (k + 1) % 6, b + (k + 1) % 6, b + k) for k in range(6)]
    faces.append(tuple((len(stations) - 1) * 6 + k for k in range(6)))
    return mesh(name, vertices, faces, mat)


def ring(name, y0, y1, radius0, radius1, mat, sides=10):
    vertices = []
    for y, radius in [(y0, radius0), (y1, radius1)]:
        vertices += [(math.cos(i * math.tau / sides) * radius, y,
                      math.sin(i * math.tau / sides) * radius) for i in range(sides)]
    faces = [tuple(reversed(range(sides))), tuple(range(sides, sides * 2))]
    faces += [(i, (i + 1) % sides, (i + 1) % sides + sides, i + sides) for i in range(sides)]
    obj = mesh(name, vertices, faces, mat)
    for polygon in obj.data.polygons[2:]:
        polygon.use_smooth = True
    return obj


def strip(name, points, width, z, mat):
    left = [(x - width / 2, y) for x, y in points]
    right = [(x + width / 2, y) for x, y in reversed(points)]
    return extrusion(name, left + right, .0018, mat, z)


stats = []
all_export = []
for tier in range(4):
    steel_colors = [(.32, .36, .38), (.56, .62, .67), (.34, .50, .64), (.62, .65, .63)]
    steel = material('Blade' if tier == 0 else f'Blade.{tier:03}', steel_colors[tier], .86, [.48, .27, .23, .25][tier])
    trim = material('MetalTrim' if tier == 0 else f'MetalTrim.{tier:03}',
                    [(.22, .21, .19), (.54, .34, .12), (.70, .77, .79), (.72, .47, .16)][tier], .78, .29)
    leather = material('Leather' if tier == 0 else f'Leather.{tier:03}',
                       [(.13, .075, .04), (.14, .055, .025), (.025, .065, .09), (.055, .025, .02)][tier], .0, .7)
    pieces = []
    base_width = [.118, .145, .168, .188][tier]
    if tier < 2:
        stations = [(-.205, 0, base_width * .65, .032), (-.245, 0, base_width, .034),
                    (-.38, 0, base_width, .034), (-.96, 0, base_width * .72, .028),
                    (-1.115, 0, base_width * .57, .025), (-1.205, 0, .001, .002)]
    elif tier == 2:
        stations = [(-.205, 0, .11, .034), (-.28, 0, .154, .035),
                    (-.52, .007, base_width, .035), (-.85, .026, .157, .030),
                    (-1.10, .047, .135, .025), (-1.205, .080, .001, .002)]
    else:
        stations = [(-.205, 0, .12, .035), (-.285, 0, .18, .035),
                    (-.49, .006, base_width, .035), (-.80, .028, .184, .032),
                    (-1.02, .052, .156, .029), (-1.135, .075, .134, .025),
                    (-1.205, .117, .001, .002)]
    pieces.append(blade('Forged Blade', stations, steel))
    # A real leather grip and ten-sided fittings; no box primitives.
    pieces.append(ring('Leather Grip', -.174, .018, .031, .026, leather, 10))
    for i in range(5):
        y = -.148 + i * .032
        pieces.append(ring('Grip Wrap', y, y + .006, .032, .032, trim, 10))
    pieces.append(ring('Grip Collar', -.196, -.172, .041, .036, trim, 10))
    pieces.append(ring('Pommel Neck', .016, .035, .029, .038, trim, 10))
    if tier == 0:
        pommel = [(-.035, .027), (-.043, .048), (-.024, .073), (.024, .073), (.043, .048), (.035, .027)]
        guard = [(-.142, -.178), (-.150, -.207), (-.048, -.222), (.048, -.222), (.15, -.207),
                 (.142, -.178), (.04, -.192), (-.04, -.192)]
    elif tier == 1:
        pommel = [(-.035, .027), (-.045, .05), (-.028, .079), (.028, .079), (.045, .05), (.035, .027)]
        guard = [(-.162, -.157), (-.178, -.177), (-.151, -.215), (-.05, -.229), (.05, -.229),
                 (.151, -.215), (.178, -.177), (.162, -.157), (.126, -.192), (.035, -.195), (-.035, -.195), (-.126, -.192)]
    elif tier == 2:
        pommel = [(-.034, .022), (-.046, .048), (-.027, .082), (.027, .082), (.046, .048), (.034, .022)]
        guard = [(-.18, -.143), (-.178, -.184), (-.11, -.223), (-.045, -.232), (.045, -.232),
                 (.11, -.223), (.178, -.184), (.18, -.143), (.128, -.177), (.04, -.195), (-.04, -.195), (-.128, -.177)]
    else:
        pommel = [(-.038, .020), (-.047, .047), (-.025, .087), (0, .100), (.025, .087), (.047, .047), (.038, .020)]
        guard = [(-.205, -.13), (-.199, -.18), (-.163, -.212), (-.092, -.23), (-.04, -.245),
                 (.04, -.245), (.092, -.23), (.163, -.212), (.199, -.18), (.205, -.13),
                 (.143, -.177), (.069, -.183), (0, -.189), (-.069, -.183), (-.143, -.177)]
    pieces.append(extrusion('Pommel', pommel, .047, trim, bevel=.004))
    pieces.append(extrusion('Crossguard', guard, .052, trim, bevel=.004))
    if tier >= 1:
        # Front and reverse fuller inlays follow each blade's forged curve.
        p = [(-.012, -.29), (-.010, -.52), (.007 if tier > 1 else -.010, -.83),
             (.024 if tier > 1 else -.010, -1.02)]
        for sign in [-1, 1]:
            pieces.append(strip('Fuller Inlay', p, .0045, sign * .0178, trim))
    if tier == 3:
        # Original eight-ray dawn medallion, restrained enough to remain readable on a phone.
        sun = []
        for i in range(16):
            r = .059 if i % 2 == 0 else .037
            a = i * math.tau / 16
            sun.append((math.cos(a) * r, -.206 + math.sin(a) * r))
        for z in [-.037, .037]:
            pieces.append(extrusion('Dawn Seal', sun, .006, trim, z))
        edge = [(.046, -.31), (.061, -.52), (.078, -.80), (.096, -1.02), (.117, -1.135)]
        for sign in [-1, 1]:
            pieces.append(strip('Dawn Edge Inlay', edge, .006, sign * .0135, trim))

    bpy.ops.object.select_all(action='DESELECT')
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    weapon_mesh = bpy.context.object
    weapon_mesh.name = f'Weapon{tier}Mesh'
    # Joining collapses the component meshes to exactly three material surfaces.
    used = []
    for slot in weapon_mesh.material_slots:
        if slot.material not in used:
            used.append(slot.material)
    polygon_materials = [weapon_mesh.material_slots[p.material_index].material for p in weapon_mesh.data.polygons]
    weapon_mesh.data.materials.clear()
    for mat in used:
        weapon_mesh.data.materials.append(mat)
    for polygon, mat in zip(weapon_mesh.data.polygons, polygon_materials):
        polygon.material_index = used.index(mat)
    weapon_mesh.data.calc_loop_triangles()
    tri_count = len(weapon_mesh.data.loop_triangles)
    if tri_count > 1000:
        raise RuntimeError(f'Tier {tier} exceeds mobile budget: {tri_count}')
    node = bpy.data.objects.new(f'Weapon{tier}', None)
    bpy.context.scene.collection.objects.link(node)
    weapon_mesh.parent = node
    all_export += [node, weapon_mesh]
    stats.append({'tier': tier, 'triangles': tri_count, 'materials': len(used), 'blade_tip_y': -1.205})

bpy.ops.object.select_all(action='DESELECT')
for obj in all_export:
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(HERE / 'weapons.glb'), export_format='GLB',
                         use_selection=True, export_yup=True, export_animations=False,
                         export_cameras=False, export_lights=False, export_extras=True)
print('WEAPON_STATS', json.dumps(stats))

# Optional source-only beauty render: supply --render /absolute/output.png.
import sys
if '--render' in sys.argv:
    output = Path(sys.argv[sys.argv.index('--render') + 1])
    for tier in range(4):
        node = bpy.data.objects[f'Weapon{tier}']
        # Rotate the swords upright in Blender for a readable four-column lineup.
        node.rotation_euler.y = math.pi
        node.location.x = (tier - 1.5) * .55
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.world = bpy.data.worlds.new('Studio')
    scene.world.color = (.22, .24, .28)
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1000
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = 'AgX'
    for name, loc, energy, color in [('Key', (0, -3, 2.6), 700, (1, .9, .78)),
                                     ('Rim', (1, 2, 2), 1000, (.6, .75, 1))]:
        data = bpy.data.lights.new(name, 'AREA')
        data.energy, data.color, data.size = energy, color, 4
        light = bpy.data.objects.new(name, data)
        scene.collection.objects.link(light)
        light.location = loc
        light.rotation_euler = (Vector((0, 0, .6)) - light.location).to_track_quat('-Z', 'Y').to_euler()
    data = bpy.data.cameras.new('Camera')
    camera = bpy.data.objects.new('Camera', data)
    scene.collection.objects.link(camera)
    camera.location = (0, -4, 1.05)
    camera.rotation_euler = (Vector((0, 0, .55)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    data.type, data.ortho_scale = 'ORTHO', 2.6
    scene.camera = camera
    scene.render.filepath = str(output)
    bpy.ops.render.render(write_still=True)
