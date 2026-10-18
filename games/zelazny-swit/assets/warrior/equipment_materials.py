"""Original, deterministic mobile PBR atlas for Zelazny Swit equipment.

Authoring: Blender 4.5+, NumPy (bundled with Blender); no addons or downloads.
Run with regular Python to regenerate the PNGs: ``python equipment_materials.py``.
Runtime uses ordinary glTF metallic/roughness materials, not procedural nodes.

Blender integration::

    import equipment_materials as em
    em.assign_role_uv(piece, tier=1, role='steel')
    blade_material = em.build_material(name='BladeEquipmentAtlas')
    em.assign_role_uv(blade, 3, 'blade', material=blade_material)

All role regions share the same atlas. Joining objects therefore produces a
single material surface per armour or weapon. Colour is sRGB; normal/ORM maps
are non-colour. ORM follows glTF R=occlusion, G=roughness, B=metallic. Normals
are tangent-space OpenGL (+Y). No light, reflection or shadow is baked in.
"""

from __future__ import annotations

import hashlib
import json
import math
import os
from pathlib import Path
import struct
import zlib

import numpy as np

ATLAS_SIZE = 1024
EMISSION_SIZE = 256
GRID = 4
CELL_SIZE = ATLAS_SIZE // GRID
PADDING = 8
PIPELINE_VERSION = 3
ROOT = Path(__file__).resolve().parent

ROLES = (
    'steel', 'gold', 'bronze', 'ivory',
    'dark_steel', 'crimson', 'teal', 'ash',
    'leather', 'jade', 'ember', 'blade',
    'charcoal', 'stitch', 'copper', 'black_leather',
)
ROLE_RECTS = {
    role: (
        ((i % GRID) * CELL_SIZE + PADDING) / ATLAS_SIZE,
        ((i // GRID) * CELL_SIZE + PADDING) / ATLAS_SIZE,
        (((i % GRID) + 1) * CELL_SIZE - PADDING) / ATLAS_SIZE,
        (((i // GRID) + 1) * CELL_SIZE - PADDING) / ATLAS_SIZE,
    ) for i, role in enumerate(ROLES)
}
ALIASES = {
    'dark_metal': 'dark_steel', 'black_steel': 'dark_steel',
    'blue_steel': 'steel', 'steel_blue': 'steel',
    'white_steel': 'ivory', 'ivory_steel': 'ivory',
    'cloth_red': 'crimson', 'red': 'crimson',
    'cloth_teal': 'teal', 'jade_cloth': 'teal',
    'cloth_ash': 'ash', 'cloth_black': 'charcoal',
    'black_cloth': 'charcoal', 'bronze_trim': 'bronze',
    'gold_trim': 'gold', 'ember_gem': 'ember', 'jade_gem': 'jade',
    'blade_steel': 'blade', 'iron': 'blade', 'ivory_gold': 'bronze',
}
TIER_ROLES = {
    0: {'steel': 'steel', 'cloth': 'charcoal', 'gold': 'bronze'},
    1: {'steel': 'steel', 'cloth': 'crimson', 'gold': 'gold'},
    2: {'steel': 'ivory', 'cloth': 'teal', 'gold': 'bronze'},
    3: {'steel': 'dark_steel', 'cloth': 'ash', 'gold': 'copper'},
}
PALETTES = {
    # Colour values are actual sRGB reflectance colours, not lit beauty colours.
    'steel':       ((.24, .29, .35), .88, .34),
    'gold':        ((.68, .49, .25), .88, .31),
    'bronze':      ((.55, .42, .27), .84, .38),
    'ivory':       ((.72, .71, .65), .74, .36),
    'dark_steel':  ((.135, .15, .17), .88, .43),
    'crimson':     ((.29, .055, .065), .00, .78),
    'teal':        ((.035, .19, .18), .00, .73),
    'ash':         ((.17, .052, .041), .00, .86),
    'leather':     ((.18, .095, .052), .00, .66),
    'jade':        ((.035, .36, .255), .04, .23),
    'ember':       ((.31, .058, .012), .38, .40),
    'blade':       ((.60, .63, .65), .96, .255),
    'charcoal':    ((.075, .085, .09), .00, .83),
    'stitch':      ((.55, .39, .19), .05, .76),
    'copper':      ((.47, .31, .19), .86, .43),
    'black_leather': ((.055, .048, .042), .00, .69),
}
FILES = {
    'color': 'equipment_color.png',
    'normal': 'equipment_normal.png',
    'orm': 'equipment_orm.png',
    'emission': 'equipment_emission.png',
    'blade_emission': 'equipment_blade_emission.png',
}


def _png(path, pixels):
    """Write lossless RGB PNG without a third-party imaging dependency."""
    pixels = np.asarray(pixels, dtype=np.uint8)
    height, width, channels = pixels.shape
    assert channels == 3
    # PNG row zero is the top. Atlas UVs and all authoring arrays are bottom-up.
    raw = b''.join(b'\x00' + row.tobytes() for row in pixels[::-1])
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', width, height, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 8)) + chunk(b'IEND', b''))


def _smooth_noise(rng, n, knots):
    grid = rng.random((knots + 1, knots + 1), dtype=np.float32)
    coords = np.linspace(0, knots, n, endpoint=False, dtype=np.float32)
    lo = np.floor(coords).astype(int)
    f = coords - lo
    f = f * f * (3 - 2 * f)
    a = grid[lo[:, None], lo[None, :]]
    b = grid[lo[:, None] + 1, lo[None, :]]
    c = grid[lo[:, None], lo[None, :] + 1]
    d = grid[lo[:, None] + 1, lo[None, :] + 1]
    return ((a * (1-f[:, None]) + b * f[:, None]) * (1-f[None, :]) + (c * (1-f[:, None]) + d * f[:, None]) * f[None, :]) * 2 - 1


def _line_field(rng, n, count=34, width=.7, vertical=True):
    """Finite, individually varied polishing scratches rather than white noise."""
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    field = np.zeros((n, n), np.float32)
    for _ in range(count):
        u, v = rng.uniform(10, n - 10, 2)
        length = rng.uniform(n*.025, n*.24)
        angle = rng.normal(math.pi/2 if vertical else .12, .12)
        dx, dy = math.cos(angle), math.sin(angle)
        along = (xx-u) * dx + (yy-v) * dy
        perp = (xx-u) * dy - (yy-v) * dx
        taper = np.clip(1 - np.abs(along)/length, 0, 1)
        field += np.exp(-(perp/width)**2) * taper * rng.uniform(.35, 1)
    return np.minimum(field, 1.3)


def _tile(role, index):
    n = CELL_SIZE
    rng = np.random.default_rng(95017 + index * 131)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    x = (xx - PADDING) / (n-2*PADDING-1)
    y = (yy - PADDING) / (n-2*PADDING-1)
    macro = _smooth_noise(rng, n, 5)
    mid = _smooth_noise(rng, n, 21)
    fine = rng.standard_normal((n,n), dtype=np.float32)
    edge_distance = np.minimum.reduce([x, y, 1-x, 1-y])
    edge = np.clip(1 - edge_distance/.028, 0, 1)
    base, metal, rough = PALETTES[role]
    color = np.broadcast_to(np.array(base, np.float32), (n,n,3)).copy()
    height = np.zeros((n,n), np.float32)
    occlusion = np.ones((n,n), np.float32)
    roughness = np.full((n,n), rough, np.float32)
    metallic = np.full((n,n), metal, np.float32)
    emission = np.zeros((n,n,3), np.float32)

    if role in {'steel','gold','bronze','ivory','dark_steel','blade','copper'}:
        brush = np.sin(xx * 2.7 + mid*1.4) * .5 + np.sin(xx * .63 + yy*.015) * .5
        scratches = _line_field(rng, n, 38 if role!='blade' else 64, .65)
        pits = np.clip((fine-2.35)*.075, 0, .11)
        patina = np.clip(macro*.5 + mid*.15 - .17, 0, .24)
        color *= (1 + macro*.075 + mid*.027 + brush*.016 + fine*.004)[...,None]
        color *= (1-patina*.23)[...,None]
        color += scratches[...,None] * (.035 if role!='dark_steel' else .027)
        # Exposed edges reveal the same alloy, not painted-on gold highlights.
        color += (edge * (.038 + np.clip(mid,0,1)*.045))[...,None]
        height += brush*.0015 - scratches*.012 - pits*.13
        roughness += mid*.025 + patina*.18 + pits - scratches*.09 - edge*.05
        occlusion -= pits*.6
        metallic -= patina*.14
        if role=='blade':
            # Longitudinal grinding and a subtle hammered temper line.
            temper = np.exp(-((x - (.16 + np.sin(y*12)*.012))/.018)**2)
            color += temper[...,None]*.024
            roughness += temper*.018
        if role in {'bronze','copper'}:
            oxide = np.clip(macro-.4,0,.3)
            color[...,0] -= oxide*.045
            color[...,1] += oxide*.018
            roughness += oxide*.17

    elif role in {'crimson','teal','ash','charcoal','stitch'}:
        # Interlaced warp and weft plus sparse brocade woven into the fabric.
        warp = np.cos(xx*math.tau/5.5)
        weft = np.cos(yy*math.tau/5.5)
        over = np.sin(xx*math.pi/5.5) * np.sin(yy*math.pi/5.5)
        weave = (warp + weft)*.28 + over*.30
        diamond = np.abs((x*5 % 1)-.5) + np.abs((y*5 % 1)-.5)
        brocade = np.exp(-((diamond-.34)/.025)**2) + np.exp(-((diamond-.12)/.018)**2)*.35
        if role in {'ash','charcoal','stitch'}:
            brocade *= .12
        dye = macro*.055 + mid*.025 + fine*.006 + weave*.036
        color *= (1+dye)[...,None]
        color += brocade[...,None] * np.array((.025,.019,.010),np.float32)
        # Mild compressed hem; the geometry author supplies actual seams.
        hem = np.exp(-((edge_distance-.035)/.007)**2)
        stitch = hem * (np.sin((x+y)*math.tau*42) > .1)
        color += stitch[...,None]*.055
        height += weave*.016 + brocade*.008 + stitch*.018
        roughness += mid*.035 - brocade*.05 - stitch*.02
        occlusion -= np.clip(-weave,0,1)*.07
        if role=='ash':
            rubbed = np.clip(macro+mid*.2-.25,0,.5)
            # Rubbed blood-maroon dye stays dark red rather than turning salmon
            # under the warm key light used by the character and item previews.
            color += rubbed[...,None] * np.array((.018,.010,.008),np.float32)
            roughness += rubbed*.04

    elif role in {'leather','black_leather'}:
        grain = _smooth_noise(rng,n,64)
        pores = np.clip((fine-1.2)*.028,0,.10)
        creases = np.exp(-((np.sin(xx*.046 + np.sin(yy*.018)*.75 + macro*.6))/.06)**2)
        color *= (1 + macro*.10 + grain*.035 - pores*.8 - creases*.05)[...,None]
        color += edge[...,None]*.025
        height += grain*.009 - pores*.09 - creases*.006
        roughness += grain*.02 + pores*.4 - edge*.045
        occlusion -= pores*.5 + creases*.025

    elif role=='jade':
        vein = np.sin(xx*.037 + yy*.017 + macro*2.8 + mid*.45)
        pale = np.exp(-(vein/.055)**2)
        dark = np.exp(-((vein-.7)/.10)**2)
        color *= (1 + macro*.11 + mid*.025)[...,None]
        color += pale[...,None] * np.array((.15,.13,.08))
        color -= dark[...,None] * np.array((.008,.045,.025))
        height += mid*.0015 - pale*.002
        roughness += mid*.018 + dark*.025
        emission = color * .045

    elif role=='ember':
        crack = np.sin(xx*.046 + yy*.013 + macro*1.8)
        fissure = np.exp(-(crack/.08)**2)
        core = np.exp(-(crack/.027)**2)
        color *= (1 + macro*.08 + mid*.05)[...,None]
        color += fissure[...,None] * np.array((.40,.07,.002))
        color += core[...,None] * np.array((.13,.15,.025))
        height -= fissure*.019
        roughness += mid*.06 - fissure*.12
        emission = fissure[...,None] * np.array((.78,.07,.003)) + core[...,None]*np.array((.15,.20,.018))

    # Extend each tile's edge pixels through its gutter to prevent filtering
    # neighbouring roles into thin trim and strongly minified equipment.
    for a in (color,height,roughness,metallic,occlusion,emission):
        a[:PADDING] = a[PADDING:PADDING+1]
        a[-PADDING:] = a[-PADDING-1:-PADDING]
        a[:,:PADDING] = a[:,PADDING:PADDING+1]
        a[:,-PADDING:] = a[:,-PADDING-1:-PADDING]
    gy,gx = np.gradient(height)
    tangent_normal = np.stack((-gx*4.5,-gy*4.5,np.ones_like(gx)),axis=-1)
    tangent_normal /= np.linalg.norm(tangent_normal,axis=-1,keepdims=True)
    normal = tangent_normal*.5+.5
    orm = np.stack((np.clip(occlusion,.7,1),np.clip(roughness,.15,.97),np.clip(metallic,0,1)),axis=-1)
    return np.clip(color,0,1),np.clip(normal,0,1),orm,np.clip(emission,0,1)


def generate_atlas(output_dir=None, force=False):
    """Return texture paths; deterministically regenerate only when needed."""
    directory = Path(output_dir) if output_dir else ROOT
    directory.mkdir(parents=True,exist_ok=True)
    paths = {kind:directory/name for kind,name in FILES.items()}
    stats_path = directory/'equipment_material_stats.json'
    if not force and all(p.exists() for p in paths.values()) and stats_path.exists():
        try:
            if json.loads(stats_path.read_text())['pipeline_version']==PIPELINE_VERSION:
                return paths
        except (ValueError,KeyError,OSError):
            pass
    atlases = [np.zeros((ATLAS_SIZE,ATLAS_SIZE,3),np.float32) for _ in range(4)]
    for i,role in enumerate(ROLES):
        tx,ty = i%GRID,i//GRID
        for image,tile in zip(atlases,_tile(role,i)):
            image[ty*CELL_SIZE:(ty+1)*CELL_SIZE,tx*CELL_SIZE:(tx+1)*CELL_SIZE] = tile
    # Emission needs only broad gem/fissure colour; 256² avoids another 1024 map.
    emission = atlases[3].reshape(EMISSION_SIZE,4,EMISSION_SIZE,4,3).mean(axis=(1,3))
    blade_emission=np.zeros_like(atlases[3])
    yy,xx=np.mgrid[0:CELL_SIZE,0:CELL_SIZE].astype(np.float32)
    x=(xx-PADDING)/(CELL_SIZE-2*PADDING-1);y=(yy-PADDING)/(CELL_SIZE-2*PADDING-1)
    for i,role in enumerate(ROLES):
        if role not in {'steel','ivory','dark_steel','blade'}:
            continue
        # Narrow honing lines, a faint fuller and tiny rune-like notches.
        # This mask affects only metal blade cells; leather and trim stay dark.
        edge=np.exp(-((x-.025)/.014)**2)+np.exp(-((x-.975)/.014)**2)
        centre=np.exp(-((x-(.5+.012*np.sin(y*10)))/.009)**2)
        notch=np.exp(-((x-(.5+((y*12)%1-.5)*.10))/.009)**2)
        notch*=np.clip((y-.18)*10,0,1)*np.clip((.82-y)*10,0,1)
        mask=(edge*.32+centre*.12+notch*.085)*np.clip((y-.04)*15,0,1)*np.clip((.97-y)*15,0,1)
        mask[:PADDING]=mask[PADDING:PADDING+1];mask[-PADDING:]=mask[-PADDING-1:-PADDING]
        mask[:,:PADDING]=mask[:,PADDING:PADDING+1];mask[:,-PADDING:]=mask[:,-PADDING-1:-PADDING]
        tx,ty=i%GRID,i//GRID
        blade_emission[ty*CELL_SIZE:(ty+1)*CELL_SIZE,tx*CELL_SIZE:(tx+1)*CELL_SIZE]=mask[...,None]
    blade_emission=blade_emission.reshape(EMISSION_SIZE,4,EMISSION_SIZE,4,3).mean(axis=(1,3))
    for kind,array in zip(('color','normal','orm','emission','blade_emission'),atlases[:3]+[emission,blade_emission]):
        _png(paths[kind],np.rint(array*255).astype(np.uint8))
    stats = {
        'pipeline_version':PIPELINE_VERSION,
        'author':'Zelazny Swit project; original deterministic material textures',
        'atlas_size':[ATLAS_SIZE,ATLAS_SIZE],
        'emission_size':[EMISSION_SIZE,EMISSION_SIZE],
        'channels':{'color':'sRGB RGB','normal':'linear tangent space +Y','orm':'linear R=occlusion G=roughness B=metallic','emission':'sRGB RGB jade/ember accents','blade_emission':'sRGB monochrome thin honing/engraving mask'},
        'role_rectangles':ROLE_RECTS,
        'role_palettes':PALETTES,
        'gutter_pixels':PADDING,
        'gpu_rgba8_with_full_mips_bytes':int((3*ATLAS_SIZE**2+2*EMISSION_SIZE**2)*4*4/3),
        'files':{kind:{'file':path.name,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()} for kind,path in paths.items()},
    }
    stats_path.write_text(json.dumps(stats,indent=2)+'\n')
    return paths


def resolve_role(role, tier=None):
    role = str(role).lower().strip().replace(' ','_')
    if tier is not None and role in {'steel','cloth','gold'}:
        role = TIER_ROLES.get(int(tier),TIER_ROLES[1])[role]
    role = ALIASES.get(role,role)
    if role not in ROLE_RECTS:
        raise ValueError('Unknown equipment role %r; valid roles: %s' % (role,', '.join(ROLES)))
    return role


def build_material(output_dir=None,name='EquipmentAtlas'):
    """Get a glTF-exportable Blender material using the four shared images."""
    import bpy
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    paths = generate_atlas(output_dir)
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (.34,.32,.28,1)
    # Opaque, single sided; actual cloth is given thickness by the modeller.
    m.use_backface_culling = True
    nodes=m.node_tree.nodes;links=m.node_tree.links
    nodes.clear()
    output=nodes.new('ShaderNodeOutputMaterial');output.location=(650,0)
    shader=nodes.new('ShaderNodeBsdfPrincipled');shader.location=(350,0)
    shader.inputs['Metallic'].default_value=1
    shader.inputs['Roughness'].default_value=1
    shader.inputs['IOR'].default_value=1.45
    links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    images={}
    emission_kind='blade_emission' if name.startswith('Blade') else 'emission'
    for index,(kind,path) in enumerate(paths.items()):
        if kind not in {'color','normal','orm',emission_kind}:
            continue
        im=bpy.data.images.load(str(path),check_existing=True)
        im.colorspace_settings.name='Non-Color' if kind in {'normal','orm'} else 'sRGB'
        node=nodes.new('ShaderNodeTexImage');node.name='Equipment '+kind;node.label='Equipment '+kind
        node.image=im;node.interpolation='Linear';node.extension='EXTEND';node.location=(-620,250-index*250)
        images[kind]=node
    links.new(images['color'].outputs['Color'],shader.inputs['Base Color'])
    channels=nodes.new('ShaderNodeSeparateColor');channels.mode='RGB';channels.location=(-290,-200)
    links.new(images['orm'].outputs['Color'],channels.inputs['Color'])
    links.new(channels.outputs['Green'],shader.inputs['Roughness'])
    links.new(channels.outputs['Blue'],shader.inputs['Metallic'])
    normal=nodes.new('ShaderNodeNormalMap');normal.location=(-40,-430)
    normal.inputs['Strength'].default_value=.8
    links.new(images['normal'].outputs['Color'],normal.inputs['Color'])
    links.new(normal.outputs['Normal'],shader.inputs['Normal'])
    links.new(images[emission_kind].outputs['Color'],shader.inputs['Emission Color'])
    shader.inputs['Emission Strength'].default_value=1
    group=bpy.data.node_groups.get('glTF Material Output')
    if group is None:
        group=bpy.data.node_groups.new('glTF Material Output','ShaderNodeTree')
        group.interface.new_socket(name='Occlusion',in_out='INPUT',socket_type='NodeSocketFloat')
    ao=nodes.new('ShaderNodeGroup');ao.node_tree=group;ao.location=(0,-210)
    links.new(channels.outputs['Red'],ao.inputs['Occlusion'])
    m['equipment_atlas_version']=PIPELINE_VERSION
    return m


def material_for(tier=None,role=None,name=None):
    """Compatibility helper: tier/role choose UVs, never duplicate textures."""
    return build_material(name=name or 'EquipmentAtlas')


def apply_role_uv(obj,role,uv_mode='auto',material=None,tier=None):
    """Assign one atlas region to a mesh, without Blender context operators.

    ``auto`` projects each polygon on its dominant normal plane using object
    bounds. ``existing`` scales the existing primary 0..1 UVs into the region.
    For cloth or a blade, the geometry author can set a deliberate UV layout and
    pass ``existing``. All exported coordinates remain inside the padded cell.
    """
    role=resolve_role(role,tier)
    if obj.type!='MESH':
        raise TypeError('Atlas UVs require a mesh object')
    me=obj.data
    uv=me.uv_layers.active or me.uv_layers.new(name='UVMap')
    u0,v0,u1,v1=ROLE_RECTS[role]
    had_role=obj.get('equipment_role')
    old_rect=ROLE_RECTS.get(had_role) if had_role else None
    if uv_mode=='existing':
        coords=[tuple(v.uv) for v in uv.data]
        if old_rect:
            ou0,ov0,ou1,ov1=old_rect
            coords=[((u-ou0)/(ou1-ou0),(v-ov0)/(ov1-ov0)) for u,v in coords]
        for data,(u,v) in zip(uv.data,coords):
            data.uv=(u0+max(0,min(1,u))*(u1-u0),v0+max(0,min(1,v))*(v1-v0))
    elif uv_mode in {'auto','box'}:
        if not me.vertices:
            return obj
        xyz=np.array([tuple(v.co) for v in me.vertices],np.float32)
        lower=xyz.min(axis=0);extent=np.maximum(xyz.max(axis=0)-lower,1e-6)
        normalized=(xyz-lower)/extent
        for poly in me.polygons:
            axis=max(range(3),key=lambda i:abs(poly.normal[i]))
            # X-facing: YZ, Y-facing (front/back): XZ, Z-facing: XY.
            ua,va=((1,2),(0,2),(0,1))[axis]
            for li in poly.loop_indices:
                co=normalized[me.loops[li].vertex_index]
                u=float(co[ua]);v=float(co[va])
                uv.data[li].uv=(u0+u*(u1-u0),v0+v*(v1-v0))
    else:
        raise ValueError('uv_mode must be auto, box or existing')
    me.materials.clear();me.materials.append(material or build_material())
    for poly in me.polygons:
        poly.material_index=0
    obj['equipment_role']=role
    if tier is not None:
        obj['equipment_tier']=int(tier)
    return obj


def assign_role_uv(obj,tier,role,uv_mode='auto',material=None):
    return apply_role_uv(obj,role,uv_mode=uv_mode,material=material,tier=tier)


def externalize_atlas_images(glb_path):
    """Make body/weapon GLBs reference the same canonical atlas PNG resources.

    Blender exports a self-contained GLB first. Only our five explicitly named
    atlas images are externalized; source skin/eye/hair textures stay embedded.
    Removed atlas buffer views are compacted, and every retained bufferView
    reference is remapped. The result is a standard GLB with relative PNG URIs.
    Call after export, with the PNGs beside the resulting GLB.
    """
    path=Path(glb_path)
    raw=path.read_bytes()
    magic,version,total=struct.unpack_from('<4sII',raw,0)
    if magic!=b'glTF' or version!=2 or total!=len(raw):
        raise ValueError('Not a valid glTF 2 GLB: '+str(path))
    chunks=[];offset=12
    while offset<len(raw):
        length,kind=struct.unpack_from('<I4s',raw,offset);offset+=8
        chunks.append((kind,raw[offset:offset+length]));offset+=length
    doc=json.loads(next(data for kind,data in chunks if kind==b'JSON'))
    binary=next((data for kind,data in chunks if kind==b'BIN\x00'),b'')
    old_views=doc.get('bufferViews',[])
    removed_candidates=set();externalized=[]
    for image in doc.get('images',[]):
        name=Path(image.get('name','')).stem.lower()
        uri=Path(image.get('uri','')).stem.lower()
        kind=next((kind for kind,file in FILES.items() if Path(file).stem in {name,uri}),None)
        if kind is None:
            continue
        canonical=FILES[kind]
        if not (path.parent/canonical).is_file():
            raise FileNotFoundError('External atlas PNG missing beside GLB: '+canonical)
        if 'bufferView' in image:
            removed_candidates.add(image.pop('bufferView'))
        image.pop('mimeType',None)
        image['uri']=canonical
        externalized.append(canonical)
    if not externalized:
        raise ValueError('No equipment atlas images found in '+str(path))

    referenced=set()
    def gather(value):
        if isinstance(value,dict):
            for key,child in value.items():
                if key=='bufferView' and isinstance(child,int):
                    referenced.add(child)
                else:
                    gather(child)
        elif isinstance(value,list):
            for child in value:
                gather(child)
    gather(doc)
    remove=removed_candidates-referenced
    mapping={};new_views=[];new_binary=bytearray()
    for old_index,view in enumerate(old_views):
        if old_index in remove:
            continue
        if view.get('buffer',0)!=0:
            raise ValueError('Atlas compaction expects a single GLB buffer')
        while len(new_binary)%4:
            new_binary.append(0)
        start=view.get('byteOffset',0);length=view['byteLength']
        new_view=dict(view);new_view['byteOffset']=len(new_binary)
        new_binary.extend(binary[start:start+length])
        mapping[old_index]=len(new_views);new_views.append(new_view)
    def remap(value):
        if isinstance(value,dict):
            for key,child in value.items():
                if key=='bufferView' and isinstance(child,int):
                    value[key]=mapping[child]
                else:
                    remap(child)
        elif isinstance(value,list):
            for child in value:
                remap(child)
    remap(doc)
    doc['bufferViews']=new_views
    if doc.get('buffers'):
        doc['buffers'][0]['byteLength']=len(new_binary)
    json_bytes=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode('utf8')
    json_bytes+=b' '*((-len(json_bytes))%4)
    new_binary+=b'\x00'*((-len(new_binary))%4)
    body=struct.pack('<I4s',len(json_bytes),b'JSON')+json_bytes
    if new_binary:
        body+=struct.pack('<I4s',len(new_binary),b'BIN\x00')+new_binary
    updated=struct.pack('<4sII',b'glTF',2,12+len(body))+body
    temporary=path.with_suffix(path.suffix+'.atlas-tmp')
    temporary.write_bytes(updated)
    os.replace(temporary,path)
    return {'externalized':externalized,'before_bytes':len(raw),'after_bytes':len(updated),'removed_buffer_views':len(remove)}


if __name__=='__main__':
    paths=generate_atlas(force=True)
    print(json.dumps({kind:str(path) for kind,path in paths.items()},indent=2))
