"""Build the high-detail mobile warrior from the CC0 Quaternius adult base and original armour.

Run: blender -b --python build_warrior_hd.py -- --source /path/Superhero_Male_FullBody.gltf --hair /path/Hair_SimpleParted.gltf
The CC0 source is an authoring input. Runtime uses warrior.glb plus the shared
canonical equipment atlas PNGs from equipment_materials.py.

Original sets: Crimson Guard (steel/sun/sash), Jade Gate (ivory/teal/bronze),
Cinder (asymmetric black iron, crossed harness, ember inlays).
The original 65-bone relaxed bind pose remains unchanged.
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

# HD equipment is authored in metres on the unchanged relaxed human bind pose.
# Visible forms use real bevels, articulated lames and woven atlas materials.
# All equipment pieces share one atlas; no per-rivet draw calls survive export.
sys.path.insert(0,OUT)
import equipment_materials as em

ROLE = {'cloth':cloth,'leather':leather,'gold':gold,'crimson':red,'steel':steel,
        'ivory':mat('Ivory enamel',(.68,.65,.53),.3,.38),
        'dark_steel':elite,'bronze':bronze,'teal':mat('Teal damask',(.018,.095,.092),0,.72),
        'ash':mat('Ash crimson',(.12,.032,.025),0,.83),
        'jade':mat('Polished jade',(.025,.35,.25),.22,.22),
        'ember':mat('Ember inlay',(.95,.12,.009),.35,.3),
        'charcoal':cloth,'black_leather':leather,'stitch':mat('Waxed linen stitch',(.52,.34,.16),0,.75),'blade':steel,'copper':mat('Old copper',(.40,.20,.10),.72,.31)}
PIECE_ROLES={}

def put(ob,role,tier=0):
    PIECE_ROLES[ob.name]=(tier,role)
    if em:
        em.assign_role_uv(ob,tier,role)
    return ob

def blend(z, lower, upper, low_z, high_z):
    t=max(0.0,min(1.0,(z-low_z)/(high_z-low_z)))
    t=t*t*(3-2*t)
    return {lower:1-t,upper:t} if lower!=upper else {lower:1.0}

def cloth_weights(v,side=None):
    x,y,z=v
    if z>=1.02:return blend(z,'pelvis','spine_03',1.05,1.38)
    if side is None:
        left=max(0,min(1,.5+x/.14));leg_mix={'l':left,'r':1-left}
    else:leg_mix={side:1.0}
    pelvis=max(0,min(1,(z-.82)/.22)) if z>.82 else 0
    calf=max(0,min(.35,(.65-z)/.27*.35)) if z<.65 else 0
    weights={}
    if pelvis:weights['pelvis']=pelvis
    for si,factor in leg_mix.items():
        if factor<=0:continue
        weights['thigh_'+si]=(1-pelvis)*(1-calf)*factor
        if calf:weights['calf_'+si]=(1-pelvis)*calf*factor
    return weights

def shell(name,sections,role,tier,bone=None,n=24,weight_fn=None,cap=False):
    # z, x-radius, front-radius, rear-radius, x-centre, y-centre.
    vs=[]
    for z,rx,fy,by,cx,cy in sections:
        for k in range(n):
            a=k*math.tau/n;si=math.sin(a)
            vs.append((cx+rx*math.cos(a),cy+si*(by if si>0 else fy),z))
    fs=[]
    for j in range(len(sections)-1):
        for k in range(n):fs.append((j*n+k,j*n+(k+1)%n,(j+1)*n+(k+1)%n,(j+1)*n+k))
    if cap:fs.extend([tuple(reversed(range(n))),tuple((len(sections)-1)*n+k for k in range(n))])
    ob=mesh(name,vs,fs,ROLE[role],bone,tier,weights=[weight_fn(v) for v in vs] if weight_fn else None)
    return put(ob,role,tier)

def pipe(name,points,radius,role,tier,bone=None,n=5,weight_fn=None):
    vs=[]
    for i,pt in enumerate(points):
        p=Vector(pt);d=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])
        if d.length<.00001:d=Vector((0,0,1))
        d.normalize();u=d.cross(Vector((0,0,1)))
        if u.length<.05:u=d.cross(Vector((0,1,0)))
        u.normalize();v=d.cross(u).normalized()
        for k in range(n):
            a=k*math.tau/n;vs.append(tuple(p+radius*(math.cos(a)*u+math.sin(a)*v)))
    fs=[]
    for j in range(len(points)-1):
        for k in range(n):fs.append((j*n+k,j*n+(k+1)%n,(j+1)*n+(k+1)%n,(j+1)*n+k))
    ob=mesh(name,vs,fs,ROLE[role],bone,tier,weights=[weight_fn(v) for v in vs] if weight_fn else None)
    return put(ob,role,tier)

def slab(name,outline,role,tier,bone=None,thickness=.006,axis=(0,-1,0),weight_fn=None,bevel=0):
    # Convex or gently concave panel: actual edge thickness and chamfer, no flat floating decals.
    axis=Vector(axis).normalized();v=[Vector(p) for p in outline];n=len(v)
    if bevel:
        c=sum(v,Vector())/n
        inset=[p+(c-p).normalized()*min(bevel,(c-p).length*.2) for p in v]
        vs=v+[p+axis*thickness*.35 for p in inset]+[p-axis*thickness*.65 for p in v]
        fs=[tuple(range(n,n*2)),tuple(reversed(range(n*2,n*3)))]
        for k in range(n):
            j=(k+1)%n;fs.extend([(k,j,n+j,n+k),(k,n*2+k,n*2+j,j)])
    else:
        vs=v+[p-axis*thickness for p in v]
        fs=[tuple(range(n)),tuple(reversed(range(n,n*2)))]+[(k,(k+1)%n,(k+1)%n+n,k+n) for k in range(n)]
    ob=mesh(name,vs,fs,ROLE[role],bone,tier,weights=[weight_fn(p) for p in vs] if weight_fn else None)
    for p in ob.data.polygons:p.use_smooth=False
    return put(ob,role,tier)

def ribbon(name,points,width,role,tier,bone,thickness=.004,weight_fn=None):
    # True leather strap: outside face, reverse face and edge thickness, with a 3D frame around shoulders.
    vs=[]
    for i,p0 in enumerate(points):
        p=Vector(p0);d=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])
        d.normalize();normal=Vector((p.x*.16,p.y,.065 if p.z>1.45 else .005)).normalized()
        side=d.cross(normal)
        if side.length<.01:side=Vector((1,0,0))
        side.normalize();side*=width*.5
        vs.extend([p-side,p+side,p-side-normal*thickness,p+side-normal*thickness])
    fs=[]
    for i in range(len(points)-1):
        a=i*4;b=(i+1)*4
        fs.extend([(a,a+1,b+1,b),(a+2,b+2,b+3,a+3),(a,b,b+2,a+2),(a+1,a+3,b+3,b+1)])
    ob=mesh(name,vs,fs,ROLE[role],bone,tier,weights=[weight_fn(p) for p in vs] if weight_fn else None);return put(ob,role,tier)

def angled_buckle(name,c,direction,w,h,role,tier):
    c=Vector(c);up=Vector((direction[0],0,direction[2])).normalized();right=Vector((up.z,0,-up.x))
    pts=[c-right*w*.5-up*h*.5,c+right*w*.5-up*h*.5,c+right*w*.5+up*h*.5,c-right*w*.5+up*h*.5]
    pipe(name+' frame',pts+[pts[0]],.0035,role,tier,n=4,weight_fn=cloth_weights)
    pipe(name+' pin',[c-right*w*.4,c+right*w*.4],.0025,role,tier,n=4,weight_fn=cloth_weights)


def rivet(name,p,r,role,tier,bone,axis=(0,-1,0),weight_fn=None):
    p=Vector(p);d=Vector(axis).normalized();u=d.cross(Vector((0,0,1)))
    if u.length<.05:u=d.cross(Vector((0,1,0)))
    u.normalize();v=d.cross(u).normalized();vs=[p+d*r*.45]
    for k in range(6):vs.append(p+(u*math.cos(k*math.tau/6)+v*math.sin(k*math.tau/6))*r)
    fs=[(0,k+1,(k+1)%6+1) for k in range(6)]
    ob=mesh(name,vs,fs,ROLE[role],bone,tier,weights=[weight_fn(q) for q in vs] if weight_fn else None)
    return put(ob,role,tier)

def gem(name,c,w,h,role,tier,bone,frame_role='gold'):
    x,y,z=c;outline=[(x,y,z+h/2),(x-w/2,y,z),(x,y,z-h/2),(x+w/2,y,z)]
    slab(name+' bezel',outline,frame_role,tier,bone,thickness=.012,bevel=.004)
    vs=[(x,y-.012,z+h*.38),(x-w*.36,y-.012,z),(x,y-.012,z-h*.38),(x+w*.36,y-.012,z),(x,y-.023,z)]
    ob=mesh(name+' inset stone',vs,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],ROLE[role],bone,tier,smooth=False);put(ob,role,tier)

def buckle(name,c,w,h,role,tier,bone):
    x,y,z=c;rr=.0028
    pipe(name,[(x-w/2,y,z-h/2),(x+w/2,y,z-h/2),(x+w/2,y,z+h/2),(x-w/2,y,z+h/2),(x-w/2,y,z-h/2)],rr,role,tier,bone,n=4)
    pipe(name+' pin',[(x-w*.4,y-.001,z),(x+w*.4,y-.001,z)],rr*.7,role,tier,bone,n=4)

# Per-family union keeps torso/arm clothing continuous without coplanar duplicate faces.
CLOTH_FACE_CLAIMS={i:set() for i in range(4)}
BASE_FULL_CLOTH_FACES=set()

def fitted_source_cloth(name,role,tier,chosen,inflate=.010,clip_plane=None):
    source=body.data;source.update();vertices=[];faces=[];weights=[];cache={}
    def source_record(i):
        v=source.vertices[i]
        return {'co':v.co+v.normal*inflate,'w':{body.vertex_groups[g.group].name:g.weight for g in v.groups},'key':('v',i)}
    def clipped(poly):
        if clip_plane is None:return poly
        normal,offset=clip_plane;out=[]
        for i,current in enumerate(poly):
            previous=poly[i-1];dc=normal.dot(current['co'])-offset;dp=normal.dot(previous['co'])-offset
            inc=dc<=1e-8;inp=dp<=1e-8
            if inc!=inp:
                t=dp/(dp-dc)
                w={n:previous['w'].get(n,0)*(1-t)+current['w'].get(n,0)*t for n in set(previous['w'])|set(current['w'])}
                key=('cut',tuple(sorted((previous['key'],current['key']),key=repr)),round(offset,9))
                out.append({'co':previous['co'].lerp(current['co'],t),'w':w,'key':key})
            if inc:out.append(current)
        return out
    for face in chosen:
        if face.index in CLOTH_FACE_CLAIMS[tier]:continue
        original=[source_record(i) for i in face.vertices];poly=clipped(original)
        if len(poly)<3:continue
        indices=[]
        for record in poly:
            key=record['key']
            if key not in cache:
                cache[key]=len(vertices);vertices.append(record['co']);weights.append(record['w'])
            indices.append(cache[key])
        faces.append(tuple(indices));CLOTH_FACE_CLAIMS[tier].add(face.index)
        if tier==0 and (clip_plane is None or all(clip_plane[0].dot(r['co'])<=clip_plane[1]+1e-8 for r in original)):
            BASE_FULL_CLOTH_FACES.add(face.index)
    ob=mesh(name,vertices,faces,ROLE[role],tier=tier,weights=weights);put(ob,role,tier)
    return ob

def fitted_body_cloth(name,role,tier,inflate=.010):
    # Full upper thorax includes the armpits/back, with a clean, continuously skinned neckline.
    source=body.data;source.update()
    chosen=[face for face in source.polygons if 1.295<face.center.z<1.635 and abs(face.center.x)<.335]
    return fitted_source_cloth(name,role,tier,chosen,inflate,(Vector((0,0,1)),1.586))

def fitted_arm_cloth(name,role,tier,side,full_sleeve=False,inflate=.010):
    source=body.data;source.update();chosen=[];relevant={'upperarm_'+side,'lowerarm_'+side}
    for face in source.polygons:
        c=face.center
        if c.z<1.08 or c.z>1.635 or abs(c.x)<.16:continue
        influence=sum(g.weight for i in face.vertices for g in source.vertices[i].groups if body.vertex_groups[g.group].name in relevant)/len(face.vertices)
        if influence>.045:chosen.append(face)
    a,b=bone_ends(('lowerarm_' if full_sleeve else 'upperarm_')+side)
    axis=(b-a).normalized();end=a.lerp(b,.42 if full_sleeve else .80)
    ob=fitted_source_cloth(name,role,tier,chosen,inflate,(axis,axis.dot(end)))
    if not full_sleeve:
        # A rounded woven cuff covers the actual clean cut; exposed elbow skin is intentional for A/C.
        a,b=bone_ends('upperarm_'+side)
        pad=.004 if tier else 0
        cuff=segment_shell('Bound short sleeve cuff '+side,a,b,[(.73,.083+pad),(.75,.088+pad),(.83,.088+pad),(.85,.08+pad)],ROLE[role],'upperarm_'+side,tier,n=24);put(cuff,role,tier)
    return ob

# The base outfit is deliberately neutral: every selected family supplies its own coloured sash.
# The torso is close fitting, with broad ribcage and a real taper at the waist.
shell('Quilted sleeveless gambeson',[(.985,.176,.119,.108,0,.024),(1.07,.177,.128,.113,0,.012),(1.19,.218,.141,.117,0,.015),(1.32,.246,.146,.118,0,.018),(1.41,.245,.132,.112,0,.023)],'charcoal',0,n=28,weight_fn=cloth_weights)
fitted_body_cloth('Fitted shoulder undershirt','charcoal',0,.006)
# A folded, open collar follows the neck instead of an oversized cylindrical helmet.
# The shoulder undershirt supplies the fitted neckline; no intersecting cylindrical collar.
for side,s in [('l',1),('r',-1)]:
    x=s*.1143
    def pantweight(v,si=side):
        if v[2]<.62:return blend(v[2],'calf_'+si,'thigh_'+si,.42,.66)
        return blend(v[2],'thigh_'+si,'pelvis',.84,1.0)
    shell('Pleated trousers '+side,[(.17,.063,.075,.073,x,.052),(.29,.071,.086,.082,x,.046),(.46,.083,.098,.092,x,.041),(.56,.086,.098,.09,x,.034),(.68,.113,.113,.116,x,.033),(.82,.13,.12,.117,x,.032),(.95,.118,.119,.109,x,.035)],'charcoal',0,n=24,weight_fn=pantweight)
    a,b=bone_ends('upperarm_'+side)
    fitted_arm_cloth('Fitted quilted undersleeve '+side,'charcoal',0,side,False,.006)
    # Shaped leather boot with toe box and heel. Foot weights preserve planted soles.
    def bootweight(v,si=side):return blend(v[2],'foot_'+si,'calf_'+si,.09,.30)
    shell('Fitted high boot '+side,[(.018,.075,.155,.08,x,.047),(.065,.079,.168,.085,x,.046),(.12,.067,.118,.079,x,.047),(.21,.064,.084,.071,x,.047),(.37,.077,.085,.076,x,.047)],'black_leather',0,n=24,weight_fn=bootweight,cap=True)
    shell('Boot sole '+side,[(.014,.078,.158,.084,x,.047),(.037,.079,.162,.085,x,.047)],'black_leather',0,'foot_'+side,n=24,cap=True)
    # Glove back and wrist support leave fingers visible around the actual grip.
    a,b=bone_ends('lowerarm_'+side)
    ob=segment_shell('Wrist leather wrap '+side,a,b,[(.69,.048),(.79,.053),(.95,.048)],leather,'lowerarm_'+side,0,n=16);put(ob,'leather',0)

FAMILIES={1:{'metal':'steel','trim':'gold','cloth':'crimson','stone':'crimson'},2:{'metal':'ivory','trim':'bronze','cloth':'teal','stone':'jade'},3:{'metal':'dark_steel','trim':'copper','cloth':'ash','stone':'ember'}}

def front_y(x,z,offset=0):
    # Smooth shallow breast curvature, negative Y is the authored front.
    w=.196+(max(0,min(1,(z-1.12)/.24)))*.058
    d=.132+math.sin(max(0,min(1,(z-1.08)/.39))*math.pi)*.038
    # Paired pectoral curvature and a subtle sternum give the forged shell an anatomical fit.
    pec=.012*math.exp(-((abs(x)-.105)/.077)**2-((z-1.345)/.075)**2)
    sternum=.0035*math.exp(-(x/.032)**2-((z-1.34)/.105)**2)
    return -d+.063*(x/max(.1,w))**2-pec+sternum+offset

def torso_plate(tier,role,trim):
    rows={1:[(1.205,.199),(1.25,.221),(1.31,.24),(1.37,.241),(1.415,.218),(1.45,.174)],2:[(1.25,.156),(1.285,.184),(1.37,.199),(1.415,.186),(1.455,.157)],3:[(1.19,.183),(1.25,.212),(1.32,.233),(1.39,.237),(1.445,.173)]}[tier]
    if tier==2:
        # Dark structural cuirass surrounds the smaller ivory shield, as a distinct jade-family construction.
        outer_rows=[(1.17,.181),(1.26,.223),(1.36,.245),(1.43,.213),(1.465,.169)]
        ov=[];on=17
        for zz,ww in outer_rows:
            for kk in range(on):
                xx=(kk/(on-1)*2-1)*ww;ov.append((xx,front_y(xx,zz)-.001,zz))
        of=[(jj*on+kk,jj*on+kk+1,(jj+1)*on+kk+1,(jj+1)*on+kk) for jj in range(len(outer_rows)-1) for kk in range(on-1)]
        outer=mesh('Guardian dark structural cuirass',ov,of,ROLE['dark_steel'],tier=tier,weights=[cloth_weights(q) for q in ov]);put(outer,'dark_steel',tier)
    n=17;vs=[]
    for j,(z,w) in enumerate(rows):
        for k in range(n):
            x=(k/(n-1)*2-1)*w
            zz=z+(.029*(abs(x)/w)**1.4 if j==len(rows)-1 else (-(.058 if tier==2 else .028)*(1-(abs(x)/w)) +(.018*x/w if tier==3 else 0)) if j==0 else 0)
            vs.append((x,front_y(x,z)-(.014 if tier==2 else .006),zz))
    fs=[]
    for j in range(len(rows)-1):
        for k in range(n-1):fs.append((j*n+k,j*n+k+1,(j+1)*n+k+1,(j+1)*n+k))
    ob=mesh('Sculpted breastplate',vs,fs,ROLE[role],tier=tier,weights=[cloth_weights(p) for p in vs]);put(ob,role,tier)
    edge=vs[:n]+[vs[j*n+n-1] for j in range(1,len(rows))]+list(reversed(vs[(len(rows)-1)*n:]))+[vs[j*n] for j in range(len(rows)-2,0,-1)]+[vs[0]]
    # A broad inset frame, most pronounced on the courtly ivory breastplate.
    frame_width=.013 if tier==2 else .006
    frame_vs=[]
    centre=Vector((0,-.17,1.34))
    for point in edge:
        point=Vector(point);inner=point+(centre-point).normalized()*frame_width
        point.y-=.0025;inner.y=front_y(inner.x,inner.z)-(.018 if tier==2 else .009)
        frame_vs.extend([point,inner])
    frame_fs=[(j*2,j*2+2,j*2+3,j*2+1) for j in range(len(edge)-1)]
    frame=mesh('Cast breastplate frame',frame_vs,frame_fs,ROLE[trim],tier=tier,weights=[cloth_weights(q) for q in frame_vs]);put(frame,trim,tier)
    pipe('Breastplate rolled edge',edge,.0035,trim,tier,n=5,weight_fn=cloth_weights)
    # Sweeping etched lines sit on one continuous fitted plate, never intersecting flat overlays.
    for sign in ([-1,1] if tier==1 else []):
        pts=[]
        for x,z in [(sign*.025,1.25),(sign*.085,1.285),(sign*.163,1.35),(sign*.181,1.413)]:pts.append((x,front_y(x,z)-.013,z))
        pipe('Pectoral engraved sweep',pts,.0035,trim,tier,'spine_03',n=4)
    # Fitted lower protection exposes coloured cloth and the waist instead of forming a metal corset.
    lower_rows={1:[(1.215,.197,.078),(1.145,.177,.067)],2:[(1.235,.173,.079),(1.17,.161,.062)],3:[(1.195,.177,.100)]}[tier]
    for row,(top,w,height) in enumerate(lower_rows):
        nn=13;vv=[]
        for j in range(3):
            v=j/2;zz=top-v*height
            for k in range(nn):
                u=k/(nn-1)*2-1;x=u*w
                z=zz-.014*(1-u*u)+(u*.022 if tier==3 else 0)
                vv.append((x,front_y(x,z)-.014+row*.004,z))
        ff=[]
        for j in range(2):
            for k in range(nn-1):ff.append((j*nn+k,j*nn+k+1,(j+1)*nn+k+1,(j+1)*nn+k))
        ff=[tuple(reversed(f)) for f in ff]
        lower_role='dark_steel' if tier==2 else role
        ob=mesh('Fitted lower breast lame',vv,ff,ROLE[lower_role],tier=tier,weights=[cloth_weights(q) for q in vv]);put(ob,lower_role,tier)
        pipe('Lower breast lame rolled hem',vv[2*nn:],.0035,trim,tier,n=4,weight_fn=cloth_weights)
    # Fine topology follows the actual trapezius instead of intersecting a guessed primitive.
    clothrole=FAMILIES[tier]['cloth']
    fitted_body_cloth('Tailored family shoulder yoke',clothrole,tier,.010)
    ncollar=32;cv=[];front_drop=.044 if tier==2 else .063
    collar_sections=[(1.51,.127,.118,.123,.015),(1.56,.099,.115,.106,.008),(1.60,.082,.108,.099,.005)]
    for row,(z,rx,fy,by,cy) in enumerate(collar_sections):
        for k in range(ncollar):
            angle=k*math.tau/ncollar;si=math.sin(angle)
            drop=front_drop*(row/2)**1.5*max(0,-si)**3
            cv.append((rx*math.cos(angle),cy+si*(by if si>0 else fy),z-drop))
    cf=[]
    for row in range(2):
        for k in range(ncollar):cf.append((row*ncollar+k,row*ncollar+(k+1)%ncollar,(row+1)*ncollar+(k+1)%ncollar,(row+1)*ncollar+k))
    collar=mesh('Tailored open stand collar',cv,cf,ROLE[clothrole],'spine_03',tier);put(collar,clothrole,tier)
    top=cv[2*ncollar:]
    pipe('Collar fine embroidery',top+[top[0]],.0025,trim,tier,'spine_03',n=4)
    # Backplate is tapered and split at the spine for a crafted rear view.
    shell('Tapered back cuirass',[(1.10,.176,.12,.149,0,.02),(1.27,.237,.12,.162,0,.018),(1.41,.229,.10,.155,0,.023),(1.465,.161,.083,.125,0,.026)],'dark_steel' if tier==2 else role,tier,n=24,weight_fn=cloth_weights)
    # Hide the front half of the back shell; it must not cover the sculpted front.
    back=pieces[tier][-1]
    import bmesh
    bm=bmesh.new();bm.from_mesh(back.data)
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_center_median().y<.02],context='FACES');bm.to_mesh(back.data);bm.free()
    for s in [-1,1]:
        pipe('Back engraved seam',[(s*.10,.143,1.14),(s*.16,.143,1.31),(s*.12,.133,1.43)],.004,trim,tier,n=4,weight_fn=cloth_weights)
        # Leather harness runs over the clavicle, anchored with true buckles.
        pts=[(s*.16,-.112,1.40),(s*.156,-.073,1.465),(s*.148,.012,1.487),(s*.15,.10,1.438),(s*.16,.14,1.34)]
        ribbon('Shoulder leather harness',pts,.035,'leather',tier,'spine_03')
        buckle('Harness buckle',(s*.162,-.124,1.413),.039,.041,trim,tier,'spine_03')
    # Chest emblem is visibly different for each family and shares atlas surface.
    if tier==1:
        c=Vector((0,-.185,1.343));n=12
        for k in range(n):
            a=k*math.tau/n;r0=.036;r1=.057 if k%2==0 else .051
            pp=[c+Vector((math.sin(a-.10)*r0,0,math.cos(a-.1)*r0)),c+Vector((math.sin(a)*r1,-.001,math.cos(a)*r1)),c+Vector((math.sin(a+.10)*r0,0,math.cos(a+.1)*r0))]
            slab('Dawn crest ray',pp,trim,tier,'spine_03',.003)
        pipe('Dawn sun ring',[(math.sin(k*math.tau/20)*.035,-.188,1.343+math.cos(k*math.tau/20)*.035) for k in range(21)],.0032,trim,tier,'spine_03',n=4)
    elif tier==2:
        for sign in [-1,1]:
            for xx,zz in [(sign*.142,1.42),(sign*.167,1.36),(sign*.145,1.29)]:
                rivet('Ivory shield inset rivet',(xx,front_y(xx,zz)-.023,zz),.0045,trim,tier,'spine_03')
            chase=[(sign*.068,front_y(sign*.068,1.277)-.024,1.277),(sign*.103,front_y(sign*.103,1.289)-.024,1.289),(sign*.126,front_y(sign*.126,1.311)-.024,1.311)]
            pipe('Ivory shield corner chase',chase,.0028,trim,tier,'spine_03',n=4)
        gem('Jade guardian seal',(0,-.188,1.35),.064,.082,'jade',tier,'spine_03',trim)
        for s in [-1,1]:
            pipe('Guardian angular knot',[(s*.025,-.19,1.389),(s*.052,-.185,1.368),(s*.052,-.185,1.335),(s*.027,-.19,1.315)],.0045,trim,tier,'spine_03',n=4)
    else:
        gem('Cinder heart',(0,-.188,1.351),.052,.10,'ember',tier,'spine_03',trim)
        for s in [-1,1]:
            pipe('Cinder angular seam',[(s*.025,-.182,1.389),(s*.071,-.18,1.377),(s*.103,-.176,1.335),(s*.128,-.158,1.328)],.003,'copper',tier,'spine_03',n=4)


def shoulder(tier,side,s,metal,trim):
    if tier==2:metal='dark_steel'
    a,b=bone_ends('upperarm_'+side);direction=(b-a).normalized()
    a-=direction*.044;b-=direction*.044
    a.x+=s*.005;b.x+=s*.005
    bulk=1.13 if (tier==3 and side=='r') else (1.05 if tier==1 and side=='l' else .94 if tier==1 else 1.0)
    # A domed cap follows the humerus; the lower lames overlap along that same axis.
    layers=[ [(-.20,.032),(-.11,.088),(.025,.126),(.16,.134),(.29,.127)],[(.24,.111),(.32,.12),(.47,.115)],[(.42,.098),(.50,.108),(.64,.103)] ]
    if tier==1 and side=='r':layers=layers[:2]
    for layer,profile in enumerate(layers):
        profile=[(t,r*bulk) for t,r in profile]
        ob=segment_shell('Articulated shoulder lame '+side,a,b,profile,ROLE[metal],'upperarm_'+side,tier,n=24);put(ob,metal,tier)
        if layer==0:
            # Seal the dome's inner upper loop; a real pauldron never has an open black hole beside the neck.
            cap_vs=[v.co.copy() for v in ob.data.vertices[:24]]
            cap_vs.append(sum(cap_vs,Vector())/24-direction*.006)
            cap_faces=[(k,24,(k+1)%24) for k in range(24)]
            cap=mesh('Closed pauldron crown '+side,cap_vs,cap_faces,ROLE[metal],'upperarm_'+side,tier);put(cap,metal,tier)
        t,r=profile[-1]
        trimob=segment_shell('Shoulder rolled edge '+side,a,b,[(t-.022,r+.002),(t+.022,r+.002)],ROLE[trim],'upperarm_'+side,tier,n=24);put(trimob,trim,tier)
        c=a.lerp(b,t-.045)
        # Front quarter rivets avoid adding visual noise to the neck silhouette.
        for k in [-1,1]:
            p=c+Vector((k*r*.46,-r*.88,0))
            rivet('Shoulder peened rivet',p,.0045,trim,tier,'upperarm_'+side)
    if tier==2:
        # Bronze architectural shoulder frame, squared at the front like the jade guardian's insignia.
        c=a.lerp(b,.03)+Vector((0,-.125,.007))
        pts=[c+Vector((-.045,0,.036)),c+Vector((.045,0,.036)),c+Vector((.049,-.003,-.036)),c+Vector((-.049,-.003,-.036))]
        slab('Rectangular ivory shoulder inset',pts,'ivory',tier,'upperarm_'+side,.005,bevel=.004)
        pipe('Guardian shoulder rectangular frame',pts+[pts[0]],.0045,trim,tier,'upperarm_'+side,n=4)
    elif tier==3 and side=='r':
        # One heavy angular swept pauldron makes the cinder set readable in silhouette.
        c=a.lerp(b,.05)
        pts=[c+Vector((s*.006,-.082,.071)),c+Vector((s*.077,-.113,.071)),c+Vector((s*.151,-.065,.031)),c+Vector((s*.141,-.071,-.052)),c+Vector((s*.06,-.128,-.073)),c+Vector((s*.005,-.111,-.014))]
        slab('Heavy cinder swept shoulder plate',pts,metal,tier,'upperarm_'+side,.010,bevel=.006)
        pipe('Heavy cinder shoulder copper edge',pts+[pts[0]],.005,trim,tier,'upperarm_'+side,n=5)
    # Flush shield detail on the front of the cap: a shallow fitted emboss, not an upright spike.
    c=a.lerp(b,.10)+Vector((0,-.118,.004))
    pts=[c+Vector((0,0,.041)),c+Vector((s*.036,0,.008)),c+Vector((0,-.005,-.036)),c+Vector((-s*.036,0,.008))]
    slab('Shoulder flush insignia',pts,metal,tier,'upperarm_'+side,.004,bevel=.003)
    pipe('Shoulder insignia border',pts+[pts[0]],.003,trim,tier,'upperarm_'+side,n=4)
    if tier>1:gem('Shoulder inset',tuple(c+Vector((0,-.006,0))),.028,.037,'jade' if tier==2 else 'ember',tier,'upperarm_'+side,trim)
    else:
        pipe('Shoulder dawn line',[c+Vector((-.015,-.007,0)),c+Vector((0,-.007,.017)),c+Vector((.015,-.007,0))],.0025,trim,tier,'upperarm_'+side,n=4)


def skirt_panel(tier,an,width,ztop,zbottom,role,trim,side=None,metallic=False,ragged=False):
    # Each vertical panel has pleats and a split hem, not a single rigid cone.
    nx=7;nz=7;vs=[]
    for j in range(nz):
        t=j/(nz-1);z=ztop+(zbottom-ztop)*t
        rx=.207+.055*t;ry=.145+.060*t
        for k in range(nx):
            u=k/(nx-1);a=an+(u-.5)*width
            fold=math.sin(u*math.pi*4)*.007*(.4+.6*t)
            zz=z
            if j==nz-1:zz+=.014*math.sin(u*math.pi)+(0.021*math.sin(u*18) if ragged else 0)
            vs.append(((rx+fold)*math.sin(a),.02-(ry+fold)*math.cos(a),zz))
    fs=[]
    for j in range(nz-1):
        for k in range(nx-1):fs.append((j*nx+k,j*nx+k+1,(j+1)*nx+k+1,(j+1)*nx+k))
    count=len(vs)
    back=[(x*.992,.02+(y-.02)*.992,z) for x,y,z in vs]
    fs+= [tuple(reversed(tuple(i+count for i in f))) for f in list(fs)]
    vs+=back
    wfun=lambda p:cloth_weights(p,side)
    ob=mesh('Split woven skirt panel',vs,fs,ROLE[role],tier=tier,weights=[wfun(p) for p in vs]);put(ob,role,tier)
    # Use existing regular UVs for woven cloth so patterns do not reset on every polygon.
    if em:
        uv=ob.data.uv_layers.get('UVMap') or ob.data.uv_layers.new(name='UVMap')
        for p in ob.data.polygons:
            for li in p.loop_indices:
                i=ob.data.loops[li].vertex_index%(nx*nz);uv.data[li].uv=(i%nx/(nx-1),i//nx/(nz-1))
        em.assign_role_uv(ob,tier,role,uv_mode='existing')
    for edge in [[vs[j*nx] for j in range(nz)],[vs[j*nx+nx-1] for j in range(nz)],vs[(nz-1)*nx:nz*nx]]:
        pipe('Cloth embroidered border',edge,.003,trim,tier,n=4,weight_fn=wfun)
    return vs


def lamellar(tier,side,s,metal,trim):
    # Independent thigh tassets leave a real opening and visible cloth between the legs.
    count={1:4,2:2,3:3}[tier]
    centre=s*.126
    for row in range(count):
        ztop=.995-row*.076;zbottom=ztop-.110
        width=(.118 if tier!=3 else .13)+(row*.004)
        nx=7;vs=[]
        for j,z in enumerate([ztop,zbottom]):
            for k in range(nx):
                u=k/(nx-1)*2-1;x=centre+u*width*.5
                y=-.163+row*.004+.025*u*u
                zz=z-(.011*(1-u*u) if j else 0)+(s*.006*u if tier==3 else 0)
                vs.append((x,y,zz))
        fs=[tuple(reversed((k,k+1,nx+k+1,nx+k))) for k in range(nx-1)]
        wfun=lambda q:cloth_weights(q,side)
        ob=mesh('Separate front thigh tasset',vs,fs,ROLE[metal],tier=tier,weights=[wfun(q) for q in vs]);put(ob,metal,tier)
        pipe('Front tasset lower edge',vs[nx:],.004,trim,tier,n=4,weight_fn=wfun)
        for edge in [[vs[0],vs[nx]],[vs[nx-1],vs[nx*2-1]]]:pipe('Tasset side brass frame',edge,.0028,trim,tier,n=4,weight_fn=wfun)
        for k in [1,nx-2]:
            q=Vector(vs[k]);q.y-=.002;q.z-=.017
            rivet('Tasset brass fastener',q,.0045,trim,tier,None,weight_fn=wfun)
    # Short side lames frame the long coloured robe instead of closing it inside a full metal skirt.
    for row in range(2 if tier!=3 else 3):
        ztop=1.005-row*.067;zbottom=ztop-.102
        x=s*(.214+row*.008)
        vs=[(x,-.065,ztop),(x,.073,ztop),(x+s*.010,.084,zbottom+.012),(x+s*.010,-.073,zbottom)]
        if s<0:vs=list(reversed(vs))
        wfun=lambda q:cloth_weights(q,side)
        slab('Short articulated hip lame',vs,'dark_steel' if tier==2 else metal,tier,thickness=.005,axis=(s,0,0),weight_fn=wfun,bevel=.003)
        pipe('Side hip lame trim',vs+[vs[0]],.0032,trim,tier,n=4,weight_fn=wfun)



def belt_and_sash(tier,trim,clothrole):
    # Five overlapping asymmetric wraps read as real folded silk around a leather belt.
    for row in range(4):
        sec=[]
        for z,rx,fy,by in [(.976+row*.023,.179,.149,.127),(1.006+row*.023,.185,.155,.132)]:sec.append((z,rx,fy,by,0,.018))
        shell('Folded waist sash',sec,clothrole,tier,'pelvis',n=28)
    shell('Wide leather belt',[(1.026,.188,.159,.135,0,.018),(1.048 if tier==1 else 1.061,.188,.159,.135,0,.018)],'leather',tier,'pelvis',n=28)
    pipe('Belt top stitch',[(.189*math.cos(k*math.tau/28),.018+.160*math.sin(k*math.tau/28),1.058) for k in range(29)],.0018,trim,tier,'pelvis',n=3)
    if tier!=3:buckle('Large waist buckle',(0,-.152,1.044),.072,.058,trim,tier,'pelvis')
    else:
        slab('Forged wedge waist clasp',[(-.038,-.158,1.063),(.038,-.158,1.063),(.029,-.16,1.027),(0,-.166,1.004),(-.029,-.16,1.027)],trim,tier,'pelvis',thickness=.007,bevel=.003)
    if tier==2:gem('Jade buckle stone',(0,-.159,1.044),.044,.048,'jade',tier,'pelvis',trim)
    elif tier==3:gem('Cinder buckle stone',(0,-.159,1.044),.039,.047,'ember',tier,'pelvis',trim)
    else:
        slab('Solid dawn waist medallion',[(math.cos(k*math.tau/12)*.025,-.16,1.044+math.sin(k*math.tau/12)*.025) for k in range(12)],trim,tier,'pelvis',thickness=.005,bevel=.002)
        pipe('Sun waist clasp',[(math.cos(k*math.tau/12)*.023,-.159,1.044+math.sin(k*math.tau/12)*.023) for k in range(13)],.004,trim,tier,'pelvis',n=4)
    pipe('Braided waist cord',[(-.183,-.071,1.03),(-.12,-.139,1.006),(0,-.153,.998),(.12,-.136,1.009),(.188,-.079,1.045)],.0038,trim,tier,'pelvis',n=5)
    # Knotted sash at one hip, no huge cape that would obscure combat silhouettes.
    for offset in [-.015,.015]:
        pipe('Silk knot loop',[(.177,-.079,1.051),(.207,-.101,1.037+offset),(.222,-.078,1.02),(.194,-.063,1.048)],.011,clothrole,tier,'pelvis',n=7)
    panel_specs={
        1:[(-.15,.56,.48,'r'),(.24,.43,.56,'l'),(-1.47,.77,.48,'r'),(1.45,.74,.55,'l'),(2.78,.72,.51,'l'),(-2.78,.71,.57,'r')],
        2:[(0,.75,.42,None),(-1.14,.92,.43,'r'),(1.14,.90,.46,'l'),(2.73,.84,.44,'l'),(-2.73,.84,.49,'r')],
        3:[(-.28,.56,.64,'r'),(.31,.49,.55,'l'),(-1.42,.70,.55,'r'),(1.42,.65,.65,'l'),(2.78,.70,.57,'l'),(-2.78,.72,.63,'r')]
    }[tier]
    for an,w,bottom,si in panel_specs:
        skirt_panel(tier,an,w,.988,bottom,clothrole,trim,si,ragged=tier==3)
    # Tiny hanging tassels on harness distinguish courtly jade armour.
    if tier==2:
        for s in [-1,1]:
            pipe('Braided shoulder tassel',[(s*.17,-.14,1.393),(s*.18,-.151,1.323),(s*.179,-.153,1.277)],.006,'teal',tier,'spine_03',n=6)
            for k in [-1,0,1]:pipe('Tassel silk end',[(s*.179+k*.004,-.153,1.292),(s*.183+k*.004,-.155,1.25)],.0028,'teal',tier,'spine_03',n=4)


def bracer(tier,side,s,metal,trim,stone):
    if tier==2:metal='dark_steel'
    a,b=bone_ends('lowerarm_'+side)
    ob=segment_shell('Sculpted forearm plate '+side,a,b,[(.13,.074),(.18,.080),(.38,.078),(.67,.063),(.83,.061),(.91,.048)],ROLE[metal],'lowerarm_'+side,tier,n=20);put(ob,metal,tier)
    for t,r in [(.19,.081),(.84,.062)]:
        ob=segment_shell('Bracer rim '+side,a,b,[(t-.014,r),(t+.014,r)],ROLE[trim],'lowerarm_'+side,tier,n=20);put(ob,trim,tier)
    d=(b-a).normalized();front=Vector((0,-1,0));c=a.lerp(b,.45)+front*.077
    # Carved, shield-shaped raised bracer spine.
    pts=[c-d*.08,c+Vector((s*.034,0,0))-d*.02,c+d*.105,c-Vector((s*.034,0,0))-d*.02]
    slab('Bracer crest',pts,'ivory' if tier==2 else metal,tier,'lowerarm_'+side,.006,bevel=.004)
    pipe('Bracer gold ridge',[c-d*.069+Vector((0,-.004,0)),c+d*.095+Vector((0,-.004,0))],.0038,trim,tier,'lowerarm_'+side,n=4)
    if tier>1:gem('Bracer stone',tuple(c+Vector((0,-.01,0))),.027,.041,stone,tier,'lowerarm_'+side,trim)
    # Two real leather retaining straps with buckles show at the exposed side.
    for t,r in [(.29,.082),(.74,.065)]:
        ob=segment_shell('Bracer retaining strap '+side,a,b,[(t-.017,r),(t+.017,r)],leather,'lowerarm_'+side,tier,n=18);put(ob,'leather',tier)
        q=a.lerp(b,t)+Vector((s*r,0,0));buckle('Bracer strap clasp',tuple(q+Vector((0,-.018,0))),.024,.023,trim,tier,'lowerarm_'+side)


def greave(tier,side,s,metal,trim,stone):
    if tier==2:metal='dark_steel'
    x=s*.1143;n=13;vs=[]
    # The shin front is peaked; sides curve around the calf instead of a round pipe.
    for z,rx,ry in [(.12,.063,.086),(.20,.076,.094),(.36,.084,.10),(.46,.077,.092),(.50,.057,.077)]:
        for k in range(n):
            a=-math.pi/2+(k/(n-1)*2-1)*1.15
            ridge=.012*math.exp(-((k-(n-1)/2)/2.1)**2)
            vs.append((x+math.cos(a)*rx,.047+math.sin(a)*(ry+ridge),z))
    fs=[]
    for j in range(4):
        for k in range(n-1):fs.append((j*n+k,j*n+k+1,(j+1)*n+k+1,(j+1)*n+k))
    ob=mesh('Anatomical greave '+side,vs,fs,ROLE[metal],'calf_'+side,tier);put(ob,metal,tier)
    edge=[vs[j*n] for j in range(5)]+vs[4*n:]+list(reversed([vs[j*n+n-1] for j in range(4)]))+list(reversed(vs[:n]))
    pipe('Greave rolled trim',edge,.0042,trim,tier,'calf_'+side,n=4)
    pipe('Greave median ridge',[(x,-.055,.14),(x,-.069,.26),(x,-.07,.41),(x,-.037,.49)],.0042,trim,tier,'calf_'+side,n=4)
    # A bent shield covers the knee while remaining attached to the lower leg.
    pts=[(x,-.063,.611),(x-.067,-.064,.57),(x-.061,-.084,.523),(x,-.102,.485),(x+.061,-.084,.523),(x+.067,-.064,.57)]
    slab('Bevelled knee shield',pts,'ivory' if tier==2 else metal,tier,'calf_'+side,.008,bevel=.008)
    pipe('Knee shield border',pts+[pts[0]],.0042,trim,tier,'calf_'+side,n=4)
    if tier>1:gem('Knee inset stone',(x,-.107,.554),.032,.05,stone,tier,'calf_'+side,trim)
    for z,r in [(.20,.083),(.425,.088)]:
        shell('Greave leather retaining band',[(z-.014,r,.097,.083,x,.047),(z+.014,r,.097,.083,x,.047)],'leather',tier,'calf_'+side,n=20)
        buckle('Greave strap buckle',(x+s*r*.7,-.02,z),.026,.025,trim,tier,'calf_'+side)
    # Three overlapping articulated sabaton plates on the foot, weighted to the foot bone.
    for row,(z,fy,rx) in enumerate([(.066,.154,.078),(.094,.128,.074),(.123,.092,.069)]):
        vv=[]
        for j in range(3):
            f=j/2
            for k in range(11):
                xx=(k/10*2-1)*rx
                yy=.045-fy+f*.052
                zz=z+.024*(1-(xx/rx)**2)-f*.010
                vv.append((x+xx,yy,zz))
        ff=[]
        for j in range(2):
            for k in range(10):ff.append((j*11+k,j*11+k+1,(j+1)*11+k+1,(j+1)*11+k))
        ob=mesh('Articulated sabaton lame',vv,ff,ROLE[metal],'foot_'+side,tier);put(ob,metal,tier)
        pipe('Sabaton brass toe edge',vv[:11],.0035,trim,tier,'foot_'+side,n=4)
    # Heel and ankle guards complete the silhouette on rear views.
    shell('Ankle plate collar',[(.125,.069,.084,.08,x,.047),(.17,.067,.085,.078,x,.047)],metal,tier,'foot_'+side,n=20)

for tier,family in FAMILIES.items():
    metal,trim,clothrole,stone=[family[k] for k in ['metal','trim','cloth','stone']]
    torso_plate(tier,metal,trim)
    belt_and_sash(tier,trim,clothrole)
    for side,s in [('l',1),('r',-1)]:
        aa,bb=bone_ends('upperarm_'+side)
        fitted_arm_cloth('Tailored family sleeve '+side,clothrole,tier,side,tier==2,.010)
        shoulder(tier,side,s,metal,trim)
        lamellar(tier,side,s,metal,trim)
        bracer(tier,side,s,metal,trim,stone)
        greave(tier,side,s,metal,trim,stone)
    if tier==3:
        # Structural harness wraps across the shoulders and tucks beneath the belt, with real thickness.
        for sign in [-1,1]:
            pts=[(sign*.15,.143,1.405),(sign*.154,.09,1.495),(sign*.157,-.072,1.505),(sign*.17,front_y(sign*.17,1.44)-.025,1.44),(sign*.11,front_y(sign*.11,1.35)-.025,1.35),(sign*.02,front_y(sign*.02,1.25)-.025,1.25),(-sign*.13,front_y(-sign*.13,1.12)-.025,1.12),(-sign*.15,-.075,1.035)]
            strap=ribbon('Crossed cinder structural harness',pts,.039,'leather',tier,None,weight_fn=cloth_weights)
            for edge in [0,1]:
                pp=[strap.data.vertices[i*4+edge].co+Vector((0,-.001,0)) for i in range(len(pts))]
                pipe('Leather harness stitched edge',pp,.0013,'stitch',tier,n=4,weight_fn=cloth_weights)
            c=(sign*.075,front_y(sign*.075,1.31)-.033,1.31)
            angled_buckle('Cinder cross harness clasp',c,(-sign*.09,0,-.1),.037,.039,trim,tier)

# Official CC0 authored hair retains the verified face/hairline proportions.
def join(obs,name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();ob=bpy.context.object;ob.name=name
    # Joining preserves each vertex group's skin weights; there should be one armature modifier.
    for m in list(ob.modifiers):
        if m.type=='ARMATURE' and m!=ob.modifiers[0]:ob.modifiers.remove(m)
    return ob
before=set(bpy.context.scene.objects);bpy.ops.import_scene.gltf(filepath=args.hair)
hair=next(o for o in bpy.context.scene.objects if o not in before and o.type=='MESH');hair.name='Hair'
g=hair.vertex_groups.new(name='Head');g.add(list(range(len(hair.data.vertices))),1,'REPLACE')
hair.parent=arm;mod=hair.modifiers.new('Skin','ARMATURE');mod.object=arm
# Preserve authored strand shading and normal detail while choosing a natural ebony hair tone.
import numpy as np
for m in hair.data.materials:
    m=m.copy();hair.data.materials[0]=m;m.name='Ebony parted hair'
    for node in m.node_tree.nodes:
        if node.type=='TEX_IMAGE' and node.image and node.image.colorspace_settings.name!='Non-Color':
            im=node.image.copy();im.name='Warrior ebony hair atlas';node.image=im
            pix=np.empty(len(im.pixels),dtype=np.float32);im.pixels.foreach_get(pix);pix=pix.reshape((-1,4));pix[:,:3]*=.065;im.pixels.foreach_set(pix.ravel());im.pack()
brows=bpy.data.objects.get('Eyebrows');brows.data.materials.clear();brows.data.materials.append(hairmat)
for t in range(4):join(pieces[t],'Armor'+str(t))

# Delete hidden feet/torso triangles while retaining the continuous face and exposed arms.
# The underclothes are present in every tier. Keep seam margins to avoid holes at joints.
import bmesh
bm=bmesh.new();bm.from_mesh(body.data)
dead=[]
for f in bm.faces:
    c=f.calc_center_median()
    if c.z<.93 or (.99<c.z<1.40 and abs(c.x)<.15) or f.index in BASE_FULL_CLOTH_FACES:dead.append(f)
bmesh.ops.delete(bm,geom=dead,context='FACES');bm.to_mesh(body.data);bm.free();body.data.update()

# Cap skinning at four influences, as required by the mobile import path.
for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    if o.vertex_groups:
        bpy.ops.object.vertex_group_limit_total(limit=4);bpy.ops.object.vertex_group_normalize_all(lock_active=False)
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

# Triangulate authored n-gons before tangent export; keep all skin weights.
for ob in [o for o in bpy.context.scene.objects if o.type=='MESH']:
    bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free();ob.data.update()

# Downsize authored texture images to a bounded 1024 edge; embed directly in GLB.
for im in bpy.data.images:
    if im.size[0]>1024 or im.size[1]>1024:
        ratio=1024/max(im.size);im.scale(round(im.size[0]*ratio),round(im.size[1]*ratio))
    if im.source=='FILE':im.pack()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'warrior-building.glb'),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_materials='EXPORT',export_yup=True,export_tangents=True)
if hasattr(em,'externalize_atlas_images'):em.externalize_atlas_images(os.path.join(OUT,'warrior-building.glb'))
import struct
export_data=open(os.path.join(OUT,'warrior-building.glb'),'rb').read()
assert export_data[:4]==b'glTF' and struct.unpack_from('<I',export_data,8)[0]==len(export_data)
export_json=json.loads(export_data[20:20+struct.unpack_from('<I',export_data,12)[0]])
assert {'Armor0','Armor1','Armor2','Armor3','Body','Hair'}.issubset({n.get('name') for n in export_json['nodes']})
assert len(export_json['skins'][0]['joints'])==65
os.replace(os.path.join(OUT,'warrior-building.glb'),os.path.join(OUT,'warrior.glb'))
stats={}
for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
    o.data.calc_loop_triangles();stats[o.name]={'triangles':len(o.data.loop_triangles),'vertices':len(o.data.vertices),'materials':len(o.data.materials)}
with open(os.path.join(OUT,'warrior_stats.json'),'w') as f:json.dump(stats,f,indent=2)
print('WARRIOR_STATS',json.dumps(stats))

if args.render:
    # Photographs of the actual exported geometry, not image-generation concepts.
    preview_dir=args.preview_dir or OUT;os.makedirs(preview_dir,exist_ok=True)
    preview_weapons=[]
    weapon_file=os.path.join(OUT,'weapons.glb')
    if os.path.isfile(weapon_file):
        before=set(bpy.context.scene.objects);bpy.ops.import_scene.gltf(filepath=weapon_file)
        preview_weapons=[o for o in bpy.context.scene.objects if o not in before]
        wrist=arm.data.bones['hand_r'].head_local.copy()+Vector((0,.005,-.060))
        for tier in range(4):
            node=next((o for o in preview_weapons if o.name=='Weapon'+str(tier)),None)
            if node:
                node.location=wrist;node.rotation_mode='XYZ';node.rotation_euler=(.94,.12,0);node.scale=(.84+.10*tier,)*3
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,.012));floor=bpy.context.object;floor.data.materials.append(mat('Preview floor',(.075,.08,.09),0,.75))
    world=bpy.context.scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.18,.19,.21,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5
    def area(name,loc,power,size,color):
        ld=bpy.data.lights.new(name,'AREA');ld.energy=power;ld.shape='DISK';ld.size=size;ld.color=color;lo=bpy.data.objects.new(name,ld);bpy.context.collection.objects.link(lo);lo.location=loc;lo.rotation_euler=(Vector((0,0,1.1))-lo.location).to_track_quat('-Z','Y').to_euler()
    area('Large soft key',(-3,4,5),850,4,(1,.90,.78));area('Cool rim',(2,-3,4),1200,3,(.62,.76,1));area('Face fill',(0,4,2),250,3,(.88,.94,1))
    ca=bpy.data.cameras.new('Preview camera');cam=bpy.data.objects.new('Preview camera',ca);bpy.context.collection.objects.link(cam);cam.location=(3.3,6.2,2.4);cam.rotation_euler=(Vector((0,0,1.04))-cam.location).to_track_quat('-Z','Y').to_euler();ca.type='ORTHO';ca.ortho_scale=2.38;bpy.context.scene.camera=cam
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=True;sc.render.resolution_x=900;sc.render.resolution_y=1100;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.render.image_settings.file_format='PNG'
    for tier in range(1,4):
        for i in range(1,4):bpy.data.objects['Armor'+str(i)].hide_render=i!=tier
        for ob in preview_weapons:
            if ob.type=='MESH':
                parent=ob.parent
                ob.hide_render=not(parent and parent.name=='Weapon'+str(tier))
        sc.render.filepath=os.path.join(preview_dir,'warrior-HD-'+str(tier)+'-actual.png');bpy.ops.render.render(write_still=True)
