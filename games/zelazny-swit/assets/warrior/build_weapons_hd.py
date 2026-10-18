"""Original high-detail mobile weapon families for Żelazny Świt.

Blender 4.5+, no addons. Run: blender -b -P build_weapons_hd.py -- --render DIR
Runtime GLBs use one shared PBR atlas plus a blade-only material for upgrade glow.
Grip is Godot (0,0,0), blade points -Y, deepest tip exactly -1.205 m.
No external game meshes, textures or copied designs are used.
"""
from pathlib import Path
import bpy, math, json, sys
from mathutils import Vector
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
import equipment_materials as em
bpy.ops.wm.read_factory_settings(use_empty=True)
MAT=em.build_material()
BLADE_MAT=em.build_material(name='BladeEquipmentAtlas')
ALL=[];STATS=[]


def xyz(p):
    x,y,z=p;return (x,-z,y)


def mesh(name,vs,fs,role,tier,blade=False,smooth=False):
    me=bpy.data.meshes.new(name);me.from_pydata([xyz(p) for p in vs],[],fs);me.update()
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob)
    for p in me.polygons:p.use_smooth=smooth
    em.assign_role_uv(ob,tier,role,material=BLADE_MAT if blade else MAT)
    return ob


def extrude(name,outline,depth,role,tier,z=0,bevel=.003,blade=False):
    n=len(outline);vs=[(x,y,z-depth*.5) for x,y in outline]+[(x,y,z+depth*.5) for x,y in outline]
    fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    ob=mesh(name,vs,fs,role,tier,blade)
    if bevel:
        bpy.context.view_layer.objects.active=ob;ob.select_set(True)
        m=ob.modifiers.new('Hand-forged bevel','BEVEL');m.width=bevel;m.segments=1
        bpy.ops.object.modifier_apply(modifier=m.name);ob.select_set(False)
        # Reproject the new chamfer polygons into the same atlas region.
        em.assign_role_uv(ob,tier,role,material=BLADE_MAT if blade else MAT)
    return ob


def ring(name,y0,y1,r0,r1,role,tier,sides=16):
    vs=[]
    for y,r in [(y0,r0),(y1,r1)]:vs.extend([(math.cos(k*math.tau/sides)*r,y,math.sin(k*math.tau/sides)*r) for k in range(sides)])
    fs=[tuple(reversed(range(sides))),tuple(range(sides,2*sides))]+[(k,(k+1)%sides,(k+1)%sides+sides,k+sides) for k in range(sides)]
    return mesh(name,vs,fs,role,tier,smooth=True)


def line(name,pts,width,depth,role,tier,blade=False):
    # A shallow raised inlay, with local surface width following the polyline.
    vs=[]
    for i,p in enumerate(pts):
        p=Vector(p);d=Vector(pts[min(i+1,len(pts)-1)])-Vector(pts[max(i-1,0)])
        tangent=Vector((-d.y,d.x,0)).normalized()*width*.5
        vs.extend([tuple(p-tangent),tuple(p+tangent),tuple(p-tangent+Vector((0,0,depth))),tuple(p+tangent+Vector((0,0,depth)))])
    fs=[]
    for i in range(len(pts)-1):
        a=i*4;b=(i+1)*4;fs.extend([(a+2,a+3,b+3,b+2),(a,b,b+2,a+2),(a+1,a+3,b+3,b+1)])
    return mesh(name,vs,fs,role,tier,blade)


def stone(name,c,w,h,role,trim,tier):
    x,y,z=c
    out=[(x,y+h*.5),(x-w*.5,y),(x,y-h*.5),(x+w*.5,y)]
    obs=[extrude(name+' bezel',out,.011,trim,tier,z,bevel=.003)]
    vs=[(x,y+h*.36,z+.008),(x-w*.36,y,z+.008),(x,y-h*.36,z+.008),(x+w*.36,y,z+.008),(x,y,z+.021)]
    obs.append(mesh(name+' faceted stone',vs,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],role,tier))
    return obs


def blade_mesh(stations,tier):
    # Smooth the actual silhouette as a cubic curve, not a handful of angled rectangular slices.
    controls=stations
    def interpolate(y,column):
        i=next((j for j in range(len(controls)-1) if controls[j][0]>=y>=controls[j+1][0]),len(controls)-2)
        a,b=controls[i],controls[i+1];length=b[0]-a[0];t=(y-a[0])/length
        def derivative(j):
            lo=max(0,j-1);hi=min(len(controls)-1,j+1)
            return (controls[hi][column]-controls[lo][column])/(controls[hi][0]-controls[lo][0])
        return ((2*t**3-3*t*t+1)*a[column]+(t**3-2*t*t+t)*length*derivative(i)+(-2*t**3+3*t*t)*b[column]+(t**3-t*t)*length*derivative(i+1))
    stations=[]
    for row in range(49 if tier else 25):
        y=-.205-row/(48 if tier else 24)
        stations.append((y,interpolate(y,1),max(.0004,interpolate(y,2)),max(.001,interpolate(y,3))))
    # Ten forged cross-section planes stay crisp; each plane is smoothly shaded along its length.
    profile=[(-.5,0),(-.34,.52),(-.10,.67),(.20,.67),(.40,.46),(.5,0),(.40,-.46),(.20,-.67),(-.10,-.67),(-.34,-.52)]
    vs=[];fs=[];roles=[];logical=[];smooth=[];n=len(profile)
    for edge in range(n):
        base=len(vs)
        for row,(y,c,w,t) in enumerate(stations):
            for k in [edge,(edge+1)%n]:
                x,z=profile[k];vs.append((c+x*w,y,z*t));logical.append((row,k))
        for row in range(len(stations)-1):
            q=base+row*2;fs.append((q,q+1,q+3,q+2));smooth.append(True)
            roles.append('dark_steel' if tier==3 and edge in [1,2,3,6,7,8] else 'blade')
    for row in [0,len(stations)-1]:
        y,c,w,t=stations[row];base=len(vs)
        for k,(x,z) in enumerate(profile):vs.append((c+x*w,y,z*t));logical.append((row,k))
        fs.append(tuple(reversed(range(base,base+n))) if row==0 else tuple(range(base,base+n)))
        roles.append('dark_steel' if tier==3 else 'blade');smooth.append(False)
    ob=mesh('Hollow-ground forged blade',vs,fs,'blade',tier,blade=True)
    uv=ob.data.uv_layers.active
    for poly,role,is_smooth in zip(ob.data.polygons,roles,smooth):
        poly.use_smooth=is_smooth;u0,v0,u1,v1=em.ROLE_RECTS[role]
        for li in poly.loop_indices:
            row,col=logical[ob.data.loops[li].vertex_index]
            uu=profile[col][0]+.5;vv=(-stations[row][0]-.205)
            uv.data[li].uv=(u0+uu*(u1-u0),v0+max(0,min(1,vv))*(v1-v0))
    # Fuller and glowing inlays use the same smooth stations as the forged blade itself.
    return ob,stations


for tier in range(4):
    pieces=[]
    trim=['bronze','gold','bronze','copper'][tier]
    grip=['black_leather','crimson','teal','ash'][tier]
    if tier==0:
        stations=[(-.205,0,.09,.030),(-.27,0,.119,.030),(-.60,0,.112,.029),(-.94,.005,.089,.025),(-1.11,.012,.065,.021),(-1.205,.018,.0004,.001)]
    elif tier==1:
        # Crimson guard sabre: the blade bows away from the hilt and returns through a curved tip.
        stations=[(-.205,0,.094,.033),(-.28,-.006,.125,.034),(-.43,-.037,.143,.034),(-.62,-.071,.150,.033),(-.80,-.086,.157,.031),(-.96,-.066,.148,.029),(-1.06,-.038,.133,.026),(-1.12,-.008,.107,.023),(-1.16,.010,.082,.018),(-1.185,.025,.049,.011),(-1.205,.030,.0004,.001)]
    elif tier==2:
        # Jade dao: a more elegant recurved, hollow-ground edge with a deeper concave waist.
        stations=[(-.205,0,.100,.033),(-.29,-.008,.125,.035),(-.45,-.052,.137,.035),(-.64,-.091,.165,.034),(-.82,-.096,.177,.032),(-.98,-.073,.168,.029),(-1.08,-.042,.147,.025),(-1.14,-.009,.115,.021),(-1.18,.017,.073,.014),(-1.205,.030,.0004,.001)]
    else:
        # Cinder cleaver: forward-weighted broad distal blade and a cut-back sweeping spine.
        stations=[(-.205,0,.110,.039),(-.28,-.005,.160,.040),(-.43,-.035,.179,.040),(-.61,-.057,.203,.039),(-.80,-.061,.231,.038),(-.98,-.041,.242,.035),(-1.08,-.013,.214,.031),(-1.14,.006,.171,.026),(-1.18,.025,.106,.016),(-1.205,.030,.0004,.001)]
    forged,stations=blade_mesh(stations,tier);pieces.append(forged)
    # Two-part grip with a subtly bowed middle, separate real leather winding.
    pieces.append(ring('Leather grip lower',-.105,.018,.028,.026,grip,tier))
    pieces.append(ring('Leather grip upper',-.184,-.105,.028,.030,grip,tier))
    for turn in range(9):
        pts=[]
        for k in range(13):
            a=k*math.tau/12;y=-.17+turn*.019+k/12*.019;r=.0302
            pts.append((math.cos(a)*r,y,math.sin(a)*r))
        # Winding has leather ridges, with one diagonal cross seam across each wrap.
        pieces.append(line('Spiral woven grip binding',pts,.006,.0015,'leather' if tier==0 else grip,tier))
    pieces.append(ring('Upper brass grip collar',-.199,-.176,.039,.035,trim,tier))
    pieces.append(ring('Pommel neck',.018,.037,.027,.035,trim,tier))
    for yy in [-.195,-.18,.021,.034]:pieces.append(ring('Fine fitting line',yy,yy+.003,.037,.037,trim,tier))
    if tier==0:
        guard=[(-.115,-.18),(-.137,-.191),(-.127,-.216),(-.042,-.226),(.042,-.226),(.127,-.216),(.137,-.191),(.115,-.18),(.035,-.197),(-.035,-.197)]
        pommel=[(-.034,.03),(-.041,.055),(-.019,.076),(.019,.076),(.041,.055),(.034,.03)]
    elif tier==1:
        guard=[(-.172,-.143),(-.197,-.16),(-.18,-.198),(-.128,-.207),(-.067,-.242),(0,-.232),(.067,-.242),(.128,-.207),(.18,-.198),(.197,-.16),(.172,-.143),(.139,-.176),(.079,-.182),(0,-.198),(-.079,-.182),(-.139,-.176)]
        pommel=[(-.037,.028),(-.049,.051),(-.034,.078),(0,.09),(.034,.078),(.049,.051),(.037,.028)]
    elif tier==2:
        guard=[(-.183,-.143),(-.183,-.208),(-.125,-.208),(-.125,-.227),(-.047,-.227),(-.047,-.251),(.047,-.251),(.047,-.227),(.125,-.227),(.125,-.208),(.183,-.208),(.183,-.143),(.131,-.143),(.131,-.183),(.079,-.183),(.079,-.16),(-.079,-.16),(-.079,-.183),(-.131,-.183),(-.131,-.143)]
        pommel=[(-.036,.027),(-.047,.051),(-.029,.083),(.029,.083),(.047,.051),(.036,.027)]
    else:
        guard=[(-.215,-.125),(-.211,-.177),(-.171,-.199),(-.154,-.22),(-.088,-.224),(-.054,-.266),(0,-.243),(.054,-.266),(.088,-.224),(.154,-.22),(.171,-.199),(.211,-.177),(.215,-.125),(.167,-.157),(.113,-.166),(.076,-.156),(0,-.187),(-.076,-.156),(-.113,-.166),(-.167,-.157)]
        pommel=[(-.036,.025),(-.048,.05),(-.029,.086),(0,.101),(.029,.086),(.048,.05),(.036,.025)]
    pieces.append(extrude('Signature forged crossguard',guard,.048,trim,tier,bevel=.0045))
    pieces.append(extrude('Faceted pommel',pommel,.047,trim,tier,bevel=.004))
    # Dark lower inset creates a real metal frame on the guard instead of one gold blob.
    if tier>0:
        inset=[(x*.79, -.198+(y+.198)*.60) for x,y in guard]
        pieces.append(extrude('Guard dark inset',inset,.006,'dark_steel',tier,z=.027,bevel=.0015))
        for sign in [-1,1]:
            if tier==1:
                # Dawn medallion/crest at both sides of the blade collar.
                sun=[]
                for k in range(16):
                    r=.049 if k%2==0 else .034;a=k*math.tau/16
                    sun.append((math.cos(a)*r,-.211+math.sin(a)*r))
                pieces.append(extrude('Eight-ray crimson guard seal',sun,.005,trim,tier,sign*.036,.001))
                pieces+=stone('Crimson guard stone',(0,-.211,sign*.038),.044,.057,'crimson',trim,tier)
            elif tier==2:
                pieces+=stone('Jade guardian guard',(0,-.208,sign*.038),.068,.084,'jade',trim,tier)
            else:
                pieces+=stone('Cinder heart guard',(0,-.214,sign*.037),.055,.082,'ember',trim,tier)
    if tier in [1,2]:
        # Etched fuller inlay follows the exact longitudinal blade curve on both sides.
        for sign in [-1,1]:
            pts=[(c-w*.22,y,sign*(t*.67+.001)) for y,c,w,t in stations[2:-2:3]]
            pieces.append(line('Signature curved fuller',pts,.0045,.0009,trim,tier,blade=True))
            if tier==2:
                pts=[(c+w*.08,y,sign*(t*.67+.0015)) for y,c,w,t in stations[2:-2:3]]
                pieces.append(line('Jade line inlay',pts,.008,.0008,'jade',tier,blade=False))
    elif tier==3:
        for sign in [-1,1]:
            pts=[]
            for k,(y,c,w,t) in enumerate(stations[2:-2:4]):
                pts.append((c+(.015 if k%2==0 else -.015),y,sign*(t*.67+.001)))
            pieces.append(line('Cinder fissure brass channel',pts,.014,.0011,'copper',tier,blade=True))
            pieces.append(line('Cinder fissure ember core',[(x,y,z+sign*.0013) for x,y,z in pts],.005,.0008,'ember',tier,blade=False))
    if tier>0:
        for sign in [-1,1]:
            # Raised guard-to-blade shoulders form a strong ornamental transition.
            left=[(-.05,-.231),(-.073,-.27),(-.062,-.335),(-.032,-.31),(-.015,-.257)]
            right=[(-x,y) for x,y in reversed(left)]
            for outline in [left,right]:pieces.append(extrude('Ornamental blade collar',outline,.004,trim,tier,sign*.026,.0015))
            # Two short engravings echo the family crest without covering the cutting edge.
            pts=[(-.029,-.30,sign*.025),(-.041,-.34,sign*.025),(-.036,-.38,sign*.025)]
            if tier==2:pts=[(-.025,-.30,sign*.025),(-.055,-.34,sign*.025),(-.045,-.39,sign*.025)]
            pieces.append(line('Collar chase engraving',pts,.0028,.0007,trim,tier,blade=True))
    # Physical fastening studs, only a few polygons each and joined into the atlas surface.
    for x in ([-.096,.096] if tier else [-.072,.072]):
        out=[(x-.006,-.196),(x,-.190),(x+.006,-.196),(x,-.202)]
        pieces.append(extrude('Crossguard fastening rivet',out,.005,trim,tier,z=.027,bevel=.001))
    bpy.ops.object.select_all(action='DESELECT')
    for p in pieces:p.select_set(True)
    bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();ob=bpy.context.object;ob.name='Weapon'+str(tier)+'Mesh'
    # Exactly two surfaces; blade-only upgrades cannot make skin or leather glow.
    materials=[]
    for p in ob.data.polygons:
        m=ob.data.materials[p.material_index]
        if m not in materials:materials.append(m)
    poly_mats=[ob.data.materials[p.material_index] for p in ob.data.polygons]
    ob.data.materials.clear()
    for m in materials:ob.data.materials.append(m)
    for p,m in zip(ob.data.polygons,poly_mats):p.material_index=materials.index(m)
    ob.data.calc_loop_triangles()
    node=bpy.data.objects.new('Weapon'+str(tier),None);bpy.context.collection.objects.link(node);ob.parent=node
    ob['asset_role']='original_signature_weapon';ob['tier']=tier
    ALL.extend([node,ob]);STATS.append({'tier':tier,'triangles':len(ob.data.loop_triangles),'surfaces':len(materials),'blade_tip_y':-1.205})

import bmesh
for ob in [o for o in ALL if o.type=='MESH']:
    bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free();ob.data.update()
bpy.ops.object.select_all(action='DESELECT')
for ob in ALL:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(HERE/'weapons-building.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_tangents=True,export_cameras=False,export_lights=False,export_extras=True)
if hasattr(em,'externalize_atlas_images'):em.externalize_atlas_images(HERE/'weapons-building.glb')
import os,struct
raw=(HERE/'weapons-building.glb').read_bytes();assert raw[:4]==b'glTF' and struct.unpack_from('<I',raw,8)[0]==len(raw)
g=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
assert {'Weapon0','Weapon1','Weapon2','Weapon3'}.issubset({n.get('name') for n in g['nodes']})
for ob in [o for o in ALL if o.type=='MESH']:assert abs(min(v.co.z for v in ob.data.vertices)+1.205)<.00001
os.replace(HERE/'weapons-building.glb',HERE/'weapons.glb')
print('WEAPON_HD_STATS',json.dumps(STATS))
if '--render' in sys.argv:
    out=Path(sys.argv[sys.argv.index('--render')+1]);out.mkdir(parents=True,exist_ok=True)
    for tier in range(4):
        node=bpy.data.objects['Weapon'+str(tier)];node.rotation_euler.y=math.pi;node.location.x=(tier-1.5)*.52
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True;sc.world=bpy.data.worlds.new('Weapon Studio');sc.world.color=(.2,.22,.25)
    sc.render.resolution_x=1800;sc.render.resolution_y=1100;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX'
    for name,loc,power,color in [('Soft key',(-2,-3,2.6),1000,(1,.91,.78)),('Cool rim',(2,2,2),1200,(.65,.78,1))]:
        ld=bpy.data.lights.new(name,'AREA');ld.energy=power;ld.color=color;ld.size=4;lo=bpy.data.objects.new(name,ld);bpy.context.collection.objects.link(lo);lo.location=loc;lo.rotation_euler=(Vector((0,0,.6))-lo.location).to_track_quat('-Z','Y').to_euler()
    ca=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',ca);bpy.context.collection.objects.link(cam);cam.location=(0,-4,1.04);cam.rotation_euler=(Vector((0,0,.6))-cam.location).to_track_quat('-Z','Y').to_euler();ca.type='ORTHO';ca.ortho_scale=2.72;sc.camera=cam
    sc.render.filepath=str(out/'weapons-HD-actual.png');bpy.ops.render.render(write_still=True)
