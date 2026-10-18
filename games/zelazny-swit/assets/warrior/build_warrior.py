"""Build the mobile warrior from the CC0 Quaternius adult base and original armour.

Run: blender -b --python build_warrior.py -- --source /path/Superhero_Male_FullBody.gltf --hair /path/Hair_SimpleParted.gltf
The source is an authoring input only; warrior.glb contains all runtime resources.
Blender 4.5+, no addons. Original armour: Zelazny Swit project.
Adult base and parted hair: Quaternius Universal Base Characters, CC0.
"""
import bpy, math, json, os, sys, argparse
from mathutils import Vector, Matrix, Quaternion
from mathutils.kdtree import KDTree

P=argparse.ArgumentParser(); P.add_argument('--source',required=True); P.add_argument('--hair',required=True); P.add_argument('--render',action='store_true'); P.add_argument('--preview-dir')
args=P.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
OUT=os.path.dirname(os.path.abspath(__file__))
assert os.path.isfile(args.source), 'The CC0 adult source glTF must exist.'
assert os.path.isfile(args.hair), 'The CC0 parted hair source glTF must exist.'
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=args.source)
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE'); arm.name='WarriorRig'
body=bpy.data.objects.get('SuperHero_Male'); body.name='Body'
for o in list(bpy.context.scene.objects):
    if o.type=='MESH' and o not in [body,bpy.data.objects.get('Eyes'),bpy.data.objects.get('Eyebrows')]: bpy.data.objects.remove(o,do_unlink=True)

# Authoring dimensions are metres, Blender Z-up, face towards -Y until final export.
# Bake posed vertices BEFORE replacing the old bind matrices with the relaxed pose.
for side,s in [('l',1),('r',-1)]:
    pb=arm.pose.bones['upperarm_'+side]; pivot=pb.head.copy()
    pb.matrix=Matrix.Translation(pivot) @ Matrix.Rotation(s*math.radians(76),4,'Y') @ Matrix.Translation(-pivot) @ pb.matrix
    for finger in ['index','middle','ring','pinky']:
        for k,angle in [('01',48),('02',68),('03',55)]:
            p=arm.pose.bones[finger+'_'+k+'_'+side]; p.rotation_mode='XYZ'; p.rotation_euler.x=math.radians(angle)
    for k,angle in [('01',18),('02',30),('03',28)]:
        p=arm.pose.bones['thumb_'+k+'_'+side]; p.rotation_mode='XYZ'; p.rotation_euler.x=math.radians(angle)
bpy.context.view_layer.update()
deps=bpy.context.evaluated_depsgraph_get()
for o in [body,bpy.data.objects.get('Eyes'),bpy.data.objects.get('Eyebrows')]:
    ev=o.evaluated_get(deps); mesh=ev.to_mesh()
    assert len(mesh.vertices)==len(o.data.vertices)
    coords=[v.co.copy() for v in mesh.vertices]
    ev.to_mesh_clear()
    for v,co in zip(o.data.vertices,coords): v.co=co
bpy.ops.object.select_all(action='DESELECT'); arm.select_set(True); bpy.context.view_layer.objects.active=arm
bpy.ops.object.mode_set(mode='POSE'); bpy.ops.pose.armature_apply(selected=False); bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.update()

def mat(name,col,metal=0,rough=.5):
    m=bpy.data.materials.new(name); m.diffuse_color=(*col,1);m.use_nodes=True
    b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*col,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough
    return m
cloth=mat('Charcoal woven cloth',(.026,.042,.054),0,.85)
leather=mat('Oxhide and dark straps',(.095,.037,.022),0,.69)
gold=mat('Aged pale gold',(.68,.39,.10),.76,.28)
red=mat('Deep crimson silk',(.24,.012,.024),0,.58)
bronze=mat('Tempered bronze',(.25,.12,.045),.7,.39)
steel=mat('Blue guardian steel',(.10,.24,.34),.78,.31)
elite=mat('Midnight engraved steel',(.055,.072,.10),.82,.35)
hairmat=mat('Blue black hair',(.012,.018,.023),.02,.55)
pieces={i:[] for i in range(4)}

def mesh(name,verts,faces,material,bone=None,tier=None,weights=None,smooth=True):
    me=bpy.data.meshes.new(name); me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(ob);ob.data.materials.append(material)
    if smooth:
        for p in me.polygons:p.use_smooth=True
    if bone:
        g=ob.vertex_groups.new(name=bone);g.add(list(range(len(verts))),1,'REPLACE')
    elif weights:
        gs={n:ob.vertex_groups.new(name=n) for n in set(n for w in weights for n in w)}
        for i,w in enumerate(weights):
            for n,v in w.items():gs[n].add([i],v,'REPLACE')
    mod=ob.modifiers.new('Skin','ARMATURE');mod.object=arm;ob.parent=arm
    if tier is not None:pieces[tier].append(ob)
    return ob

def ring_shell(name,sections,material,bone,tier=None,n=24):
    # Sections: z, half-width, front-depth, back-depth, centre-x, centre-y.
    vs=[]
    for z,rx,fy,by,cx,cy in sections:
        for k in range(n):
            a=2*math.pi*k/n;si=math.sin(a);vs.append((cx+rx*math.cos(a),cy+si*(by if si>0 else fy),z))
    fs=[]
    for j in range(len(sections)-1):
        for k in range(n):fs.append((j*n+k,j*n+(k+1)%n,(j+1)*n+(k+1)%n,(j+1)*n+k))
    return mesh(name,vs,fs,material,bone,tier)

def tube(name,points,radius,material,bone,tier=None,n=5):
    vs=[]
    for i,pp in enumerate(points):
        p=Vector(pp);d=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])
        if d.length<.00001:d=Vector((0,0,1))
        d.normalize();u=d.cross(Vector((0,0,1)))
        if u.length<.05:u=d.cross(Vector((0,1,0)))
        u.normalize();v=d.cross(u).normalized()
        for k in range(n):
            a=k*math.tau/n;vs.append(p+radius*(math.cos(a)*u+math.sin(a)*v))
    fs=[]
    for j in range(len(points)-1):
        for k in range(n):fs.append((j*n+k,j*n+(k+1)%n,(j+1)*n+(k+1)%n,(j+1)*n+k))
    return mesh(name,vs,fs,material,bone,tier)

def segment_shell(name,a,b,radii,material,bone,tier,n=16):
    a,b=Vector(a),Vector(b);d=(b-a).normalized();u=d.cross(Vector((0,1,0))).normalized();v=d.cross(u).normalized()
    vs=[]
    for t,r in radii:
        c=a.lerp(b,t)
        for k in range(n):
            an=k*math.tau/n;vs.append(c+(math.cos(an)*u+math.sin(an)*v)*r)
    fs=[]
    for j in range(len(radii)-1):
        for k in range(n):fs.append((j*n+k,j*n+(k+1)%n,(j+1)*n+(k+1)%n,(j+1)*n+k))
    return mesh(name,vs,fs,material,bone,tier)

def bone_ends(name):
    b=arm.data.bones[name];return b.head_local.copy(),b.tail_local.copy()

# Continuous underclothes. All variants wear the same fitted tunic, trousers and boots.
ring_shell('Padded sleeveless tunic',[(.99,.174,.112,.105,0,.025),(1.09,.18,.125,.12,0,.01),(1.28,.236,.145,.12,0,.015),(1.40,.249,.14,.12,0,.018),(1.47,.185,.112,.10,0,.026)],cloth,'spine_03',0)
ring_shell('Leather waist',[(.967,.184,.124,.12,0,.018),(1.023,.184,.124,.12,0,.018)],leather,'pelvis',0)
for side,s in [('l',1),('r',-1)]:
    x=s*.1143
    ring_shell('Trousers '+side,[(.10,.069,.087,.075,x,.06),(.27,.079,.09,.083,x,.045),(.51,.085,.09,.083,x,.038),(.72,.11,.105,.108,x,.034),(.94,.123,.117,.105,x,.035)],cloth,'thigh_'+side,0,20)
    boot=ring_shell('Soft boot '+side,[(.018,.078,.157,.085,x,.045),(.08,.082,.17,.09,x,.05),(.15,.071,.103,.084,x,.05),(.37,.078,.087,.079,x,.047)],leather,'calf_'+side,0,20)
    # The sole follows the planted foot; the boot shaft transitions into the calf.
    # This lets the runtime ankle IK keep a flat foot while the shin bends in a crouch.
    foot_group=boot.vertex_groups.new(name='foot_'+side)
    for v in boot.data.vertices:
        z=v.co.z
        w=1.0 if z<=.08 else (1.0-(z-.08)/.14 if z<=.15 else max(0,.5*(.37-z)/.22))
        foot_group.add([v.index],w,'REPLACE')
        boot.vertex_groups['calf_'+side].add([v.index],1-w,'REPLACE')
    a,b=bone_ends('upperarm_'+side)
    segment_shell('Upper cloth '+side,a,b,[(0,.075),(.22,.089),(.75,.075)],cloth,'upperarm_'+side,0)
    a,b=bone_ends('lowerarm_'+side)
    segment_shell('Wrist binding '+side,a,b,[(.64,.05),(.70,.053),(.92,.048)],leather,'lowerarm_'+side,0)

# Split crimson rear cloth, with a natural taper, below all armour tiers.
for s in [-1,1]:
    vs=[(s*.025,.14,.98),(s*.17,.13,.98),(s*.20,.18,.58),(s*.07,.19,.53)]
    mesh('Split back tab',vs,[(0,1,2,3)],red,'pelvis',0,smooth=False)
    tube('Tab edging',[vs[0],vs[3],vs[2],vs[1]],.0045,gold,'pelvis',0)

def pauldron(side,s,tier,metal):
    centre=arm.data.bones['upperarm_'+side].head_local.copy()+Vector((s*.005,0,.026))
    for layer in range(2 if tier<3 else 3):
        vs=[];nr=5;n=20
        for j in range(nr):
            ph=(.10+j/(nr-1)*1.64)
            for k in range(n):
                th=k*math.tau/n
                # A rounded armour lobe, not a shoulder box.
                vs.append(centre+Vector((s*(.025+math.sin(ph)*(.116+layer*.008)*math.cos(th)),math.sin(ph)*(.119+layer*.007)*math.sin(th),math.cos(ph)*.073-layer*.027)))
        fs=[]
        fs.append(tuple(reversed(range(n))))
        for j in range(nr-1):
            for k in range(n):fs.append((j*n+k,j*n+(k+1)%n,(j+1)*n+(k+1)%n,(j+1)*n+k))
        mesh('Articulated shoulder '+side,vs,fs,metal,'upperarm_'+side,tier)
        border=vs[(nr-1)*n:]+[vs[(nr-1)*n]]
        tube('Shoulder gold rim',border,.006 if tier>1 else .004,gold,'upperarm_'+side,tier)
    if tier==3:
        for k in range(3):
            x=centre.x+s*(.00+k*.036)
            tube('Shoulder etched feather',[(x,-.104,centre.z-.016),(x+s*.02,-.118,centre.z+.026),(x+s*.036,-.09,centre.z+.05)],.004,gold,'upperarm_'+side,tier)
        # Swept, shallow crest over the rounded lames, giving the elite silhouette its own design.
        vv=[centre+Vector((s*.015,-.087,.025)),centre+Vector((s*.068,-.095,.042)),centre+Vector((s*.145,-.061,.035)),centre+Vector((s*.117,-.063,-.031)),centre+Vector((s*.055,-.108,-.018)),centre+Vector((s*.064,-.12,.007))]
        mesh('Swept shoulder crest',vv,[(0,1,5),(1,2,5),(2,3,5),(3,4,5),(4,0,5)],gold,'upperarm_'+side,tier)

def create_armour(tier,metal):
    # Sculpted silhouette from waist through pectorals, low neck to expose the real face.
    sec=[(1.027,.19,.132,.124,0,.015),(1.10,.193,.139,.13,0,.015),(1.19,.218,.152,.137,0,.017),(1.31,.252,.169,.14,0,.02),(1.40,.256,.151,.137,0,.021),(1.465,.171,.12,.106,0,.025)]
    ring_shell('Curved cuirass',sec,metal,'spine_03',tier,28)
    for z,rx,fy in [(1.035,.192,.134),(1.108,.198,.145)]:
        tube('Waist edge',[(rx*math.cos(k*math.tau/28),.015+fy*math.sin(k*math.tau/28),z) for k in range(29)],.007,gold,'spine_01',tier)
    # Engraved front V motif, laid over the convex breastplate.
    for s in [-1,1]:
        tube('Breast sweeping gold',[(s*.018,-.155,1.185),(s*.085,-.158,1.255),(s*.163,-.143,1.338),(s*.193,-.105,1.409)],.008 if tier>1 else .005,gold,'spine_03',tier)
        if tier>1:
            tube('Outer breast scroll',[(s*.042,-.16,1.278),(s*.09,-.159,1.319),(s*.124,-.15,1.36),(s*.119,-.147,1.39)],.004,gold,'spine_03',tier)
    # Central diamond clasp and raised crest.
    mesh('Crimson crest',[(0,-.184,1.39),(-.033,-.174,1.354),(0,-.184,1.307),(.033,-.174,1.354),(0,-.197,1.355)],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],red,'spine_03',tier)
    tube('Crest bezel',[(0,-.186,1.394),(-.038,-.177,1.354),(0,-.186,1.301),(.038,-.177,1.354),(0,-.186,1.394)],.006,gold,'spine_03',tier)
    # Overlapping lamellar scales around the pelvis: separate plates with shaped hems.
    for row in range(3 if tier>1 else 2):
        count=12 if tier>1 else 10
        for k in range(count):
            an=math.tau*(k+.5)/count; half=math.pi/count*.86
            ztop=1.04-row*.098;zbot=ztop-.145
            vs=[]
            for jj,(z,r) in enumerate([(ztop,.207+row*.009),(zbot,.235+row*.012)]):
                for q in range(4):
                    a=an-half+2*half*q/3
                    vs.append((math.cos(a)*r,.018+math.sin(a)*r*.73,z+(math.sin(q/3*math.pi)*(-.017) if jj else 0)))
            mesh('Lamellar tasset',vs,[(0,1,5,4),(1,2,6,5),(2,3,7,6)],metal,'pelvis',tier)
            tube('Tasset hem',[vs[4],vs[5],vs[6],vs[7]],.004,gold,'pelvis',tier)
    for side,s in [('l',1),('r',-1)]:
        pauldron(side,s,tier,metal)
        a,b=bone_ends('lowerarm_'+side)
        segment_shell('Forged bracer '+side,a,b,[(.16,.078),(.22,.083),(.72,.060),(.85,.063),(.90,.053)],metal,'lowerarm_'+side,tier)
        for t,r in [(.21,.084),(.85,.064)]:segment_shell('Bracer gold band '+side,a,b,[(t-.018,r),(t+.018,r)],gold,'lowerarm_'+side,tier)
        # Shin armour with an angular central ridge and rounded side wrap.
        x=s*.1143;n=11;vs=[]
        for z,rad in [(.13,.082),(.20,.09),(.42,.092),(.50,.075)]:
            for k in range(n):
                ang=-math.pi*.86+k/(n-1)*math.pi*.72
                vs.append((x+math.cos(ang)*rad,.044+math.sin(ang)*rad*1.15,z))
        fs=[]
        for j in range(3):
            for k in range(n-1):fs.append((j*n+k,j*n+k+1,(j+1)*n+k+1,(j+1)*n+k))
        mesh('Ridged greave '+side,vs,fs,metal,'calf_'+side,tier)
        tube('Greave centre engraving',[(x,-.065,.145),(x,-.072,.26),(x,-.067,.42),(x,-.043,.49)],.006,gold,'calf_'+side,tier)
        # Knee medallions are smoothly bevelled diamond shields.
        vv=[(x,-.07,.60),(x-.069,-.066,.552),(x,-.088,.486),(x+.069,-.066,.552),(x,-.112,.55)]
        mesh('Knee shield '+side,vv,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],gold if tier==3 else metal,'calf_'+side,tier)
    # Small raised rivets, kept to a few dozen polygons and sharing the gold surface.
    if tier>=2:
        for s in [-1,1]:
            for z in [1.15,1.21,1.27]:
                x=s*(.167+(z-1.15)*.15);y=-.09
                mesh('Rivet',[(x-.008,y,z),(x,y-.006,z+.008),(x+.008,y,z),(x,y-.006,z-.008)],[(0,1,2),(0,2,3)],gold,'spine_03',tier)

for t,m in [(1,bronze),(2,steel),(3,elite)]:create_armour(t,m)

# Original short hair cap: asymmetric crown and a swept fringe of tapered locks.
cx,cy,cz=0,.024,1.727;vs=[]; nr=8;n=28
for j in range(nr):
    ph=.06+j/(nr-1)*1.68
    for k in range(n):
        an=k*math.tau/n
        # Rear hairline lower than forehead. The fringe is modelled separately.
        z=cz+math.cos(ph)*.116
        if j==nr-1:z+=(-.008 if math.sin(an)<0 else -.045)
        vs.append((cx+math.sin(ph)*.096*math.cos(an),cy+math.sin(ph)*.10*math.sin(an),z))
fs=[]
for j in range(nr-1):
    for k in range(n):fs.append((j*n+k,j*n+(k+1)%n,(j+1)*n+(k+1)%n,(j+1)*n+k))
hair=mesh('Hair cap',vs,fs,hairmat,'Head')
hairparts=[hair]
for k in range(11):
    x=-.086+k*.016
    # Two curved sides of each lock meet at an offset tip; surface highlights describe the sweep.
    tip=(x+.020,-.081+(abs(x)*.25),1.705+(k%3)*.006)
    vv=[(x-.012,-.045,1.802),(x+.010,-.045,1.806),(x+.027,-.085,1.761),(x+.012,-.09,1.748),tip]
    hairparts.append(mesh('Swept hair lock',vv,[(0,1,2,3),(3,2,4)],hairmat,'Head'))
# Crown comb ridges, low enough to remain an adult haircut rather than a helmet.
for k in range(6):
    x=-.065+k*.024
    hairparts.append(tube('Swept crown strand',[(x,.074,1.794),(x+.015,.023,1.836),(x+.027,-.033,1.814)],.009,hairmat,'Head',n=4))

def join(obs,name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();ob=bpy.context.object;ob.name=name
    # Joining preserves each vertex group's skin weights; there should be one armature modifier.
    for m in list(ob.modifiers):
        if m.type=='ARMATURE' and m!=ob.modifiers[0]:ob.modifiers.remove(m)
    return ob
hair=join(hairparts,'Hair')
if os.path.isfile(args.hair):
    # CC0 authored hair gives the close portrait fine strand shapes and a real hairline.
    bpy.data.objects.remove(hair,do_unlink=True)
    before=set(bpy.context.scene.objects);bpy.ops.import_scene.gltf(filepath=args.hair)
    hair=next(o for o in bpy.context.scene.objects if o not in before and o.type=='MESH');hair.name='Hair'
    g=hair.vertex_groups.new(name='Head');g.add(list(range(len(hair.data.vertices))),1,'REPLACE')
    hair.parent=arm;mod=hair.modifiers.new('Skin','ARMATURE');mod.object=arm
    # Darken a private in-memory image copy, retaining authored strand shading and normal map.
    import numpy as np
    for m in hair.data.materials:
        m=m.copy();hair.data.materials[0]=m;m.name='Ebony parted hair'
        for node in m.node_tree.nodes:
            if node.type=='TEX_IMAGE' and node.image and node.image.colorspace_settings.name!='Non-Color':
                im=node.image.copy();im.name='Warrior ebony hair atlas';node.image=im
                pix=np.empty(len(im.pixels),dtype=np.float32);im.pixels.foreach_get(pix);pix=pix.reshape((-1,4));pix[:,:3]*=.065;im.pixels.foreach_set(pix.ravel());im.pack()
    # The base eyebrow atlas is pale grey, so use the same dark hair colour for readable brows.
    brows=bpy.data.objects.get('Eyebrows');brows.data.materials.clear();brows.data.materials.append(hairmat)
for t in range(4):join(pieces[t],'Armor'+str(t))

# Cloth follows both sides of the knee and blends naturally from pelvis to ribs.
under=bpy.data.objects['Armor0']
for side,s in [('l',1),('r',-1)]:
    thigh='thigh_'+side;calf='calf_'+side
    if under.vertex_groups.get(calf) is None:under.vertex_groups.new(name=calf)
    for v in under.data.vertices:
        groups={under.vertex_groups[g.group].name:g.weight for g in v.groups}
        if thigh in groups:
            t=max(0,min(1,(v.co.z-.45)/.17))
            under.vertex_groups[thigh].add([v.index],t,'REPLACE')
            under.vertex_groups[calf].add([v.index],1-t,'REPLACE')
for name in ['pelvis','spine_01','spine_02']:
    if under.vertex_groups.get(name) is None:under.vertex_groups.new(name=name)
for v in under.data.vertices:
    groups={under.vertex_groups[g.group].name:g.weight for g in v.groups}
    if 'spine_03' in groups:
        t=max(0,min(1,(v.co.z-1.03)/.30))
        under.vertex_groups['spine_03'].add([v.index],t,'REPLACE')
        under.vertex_groups['pelvis'].add([v.index],1-t,'REPLACE')

# Delete hidden feet/torso triangles while retaining the continuous face and exposed arms.
# The underclothes are present in every tier. Keep seam margins to avoid holes at joints.
import bmesh
bm=bmesh.new();bm.from_mesh(body.data)
dead=[]
for f in bm.faces:
    c=f.calc_center_median()
    if c.z<.93 or (.99<c.z<1.40 and abs(c.x)<.15):dead.append(f)
bmesh.ops.delete(bm,geom=dead,context='FACES');bm.to_mesh(body.data);bm.free();body.data.update()

# Cap skinning at four influences, as required by the mobile import path.
for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    if o.vertex_groups:
        bpy.ops.object.vertex_group_limit_total(limit=4);bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    for p in o.data.polygons:p.use_smooth=True
    o['asset_role']='continuous_human_skin' if o==body else 'original_equipment'

# Scale to 2 m and face Godot -Z, applying to both mesh vertices and rest matrices.
allobs=list(bpy.context.scene.objects)
transform=Matrix.Scale(1.1,4)@Matrix.Rotation(math.pi,4,'Z')
arm.data.transform(transform)
for o in [o for o in allobs if o.type=='MESH']:
    o.data.transform(transform);o.matrix_parent_inverse=Matrix.Identity(4);o.matrix_basis=Matrix.Identity(4)
arm.matrix_world=Matrix.Identity(4)
bpy.context.view_layer.update()

# glTF coordinates: Blender(x,y,z) -> Godot(x,z,-y).
C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))
height=max(v.co.z for o in allobs if o.type=='MESH' for v in o.data.vertices)
info={'height_metres':height,'front':[0,0,-1],'base_always_visible':'Armor0','tier_meshes':['Armor1','Armor2','Armor3'],'bones':{}}
for b in arm.data.bones:
    h=C@arm.matrix_world@b.head_local;ta=C@arm.matrix_world@b.tail_local
    mm=C@arm.matrix_world@b.matrix_local@C.inverted()
    local=b.matrix_local if b.parent is None else b.parent.matrix_local.inverted()@b.matrix_local
    local=C@local@C.inverted()
    info['bones'][b.name]={'head':list(h),'tail':list(ta),'parent':b.parent.name if b.parent else None,'global_rest_matrix':[list(row) for row in mm],'local_rest_matrix':[list(row) for row in local]}
with open(os.path.join(OUT,'warrior_rig.json'),'w') as f:json.dump(info,f,indent=2)

# Downsize authored texture images to a bounded 1024 edge; embed directly in GLB.
for im in bpy.data.images:
    if im.size[0]>1024 or im.size[1]>1024:
        ratio=1024/max(im.size);im.scale(round(im.size[0]*ratio),round(im.size[1]*ratio))
    if im.source=='FILE':im.pack()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'warrior.glb'),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_materials='EXPORT',export_yup=True)
stats={}
for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
    o.data.calc_loop_triangles();stats[o.name]={'triangles':len(o.data.loop_triangles),'vertices':len(o.data.vertices),'materials':len(o.data.materials)}
with open(os.path.join(OUT,'warrior_stats.json'),'w') as f:json.dump(stats,f,indent=2)
print('WARRIOR_STATS',json.dumps(stats))

if args.render:
    # Actual engine asset preview, no generated artwork.
    for o in bpy.context.scene.objects:
        if o.name in ['Armor1','Armor2']:o.hide_render=True
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.012));floor=bpy.context.object;floor.data.materials.append(mat('Preview floor',(.035,.042,.052),0,.7))
    world=bpy.context.scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.15,.19,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45
    def area(name,loc,power,size,color):
        ld=bpy.data.lights.new(name,'AREA');ld.energy=power;ld.shape='DISK';ld.size=size;ld.color=color;lo=bpy.data.objects.new(name,ld);bpy.context.collection.objects.link(lo);lo.location=loc;lo.rotation_euler=(Vector((0,0,1.1))-lo.location).to_track_quat('-Z','Y').to_euler()
    area('Warm key',(-3,4,5),750,4,(1,.84,.67));area('Cool rim',(2,-3,4),1000,3,(.5,.7,1));area('Face fill',(0,4,2),180,3,(.8,.9,1))
    ca=bpy.data.cameras.new('Preview camera');cam=bpy.data.objects.new('Preview camera',ca);bpy.context.collection.objects.link(cam);cam.location=(3.6,6.1,2.5);cam.rotation_euler=(Vector((0,0,1.05))-cam.location).to_track_quat('-Z','Y').to_euler();ca.type='ORTHO';ca.ortho_scale=2.45;bpy.context.scene.camera=cam
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.render.resolution_x=900;sc.render.resolution_y=1100;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.render.image_settings.file_format='PNG'
    preview_dir=args.preview_dir or OUT;os.makedirs(preview_dir,exist_ok=True)
    sc.render.filepath=os.path.join(preview_dir,'warrior-actual-elite.png');bpy.ops.render.render(write_still=True)
