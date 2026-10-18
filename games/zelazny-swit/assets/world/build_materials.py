#!/usr/bin/env python3
"""Build original seamless 512 px village material maps; Pillow + NumPy only.
The generated PNGs are runtime assets; this authoring script is not needed by Godot.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

SIZE=512
OUT=Path(__file__).resolve().parent
Y,X=np.mgrid[0:SIZE,0:SIZE].astype(np.float64)/SIZE
RNG=np.random.default_rng(51472026)

def noise(cells, seed):
    grid=np.random.default_rng(seed).random((cells,cells))
    u=X*cells;v=Y*cells
    ix=np.floor(u).astype(int);iy=np.floor(v).astype(int)
    fx=u-ix;fy=v-iy
    fx=fx*fx*(3-2*fx);fy=fy*fy*(3-2*fy)
    return (grid[iy%cells,ix%cells]*(1-fx)*(1-fy)+grid[iy%cells,(ix+1)%cells]*fx*(1-fy)+grid[(iy+1)%cells,ix%cells]*(1-fx)*fy+grid[(iy+1)%cells,(ix+1)%cells]*fx*fy)

def fbm(seed):
    return sum(noise(c,seed+c)*w for c,w in [(2,.31),(4,.24),(8,.17),(16,.13),(32,.09),(64,.06)])

def save(name,color,height,normal_strength=1):
    Image.fromarray(np.uint8(np.clip(color,0,1)*255),'RGB').save(OUT/(name+'_albedo.png'),optimize=True)
    dx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*normal_strength
    dy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*normal_strength
    n=np.stack([-dx,dy,np.ones_like(dx)],axis=-1);n/=np.linalg.norm(n,axis=-1,keepdims=True)
    Image.fromarray(np.uint8(np.clip(n*.5+.5,0,1)*255),'RGB').save(OUT/(name+'_normal.png'),optimize=True)

def grey(n,base):return np.array(base)[None,None,:]*n[:,:,None]

# Packed clay, small stones, worn pores. Broad variation remains subtle.
ground=fbm(11);height=ground*.16
shade=.82+(ground-.5)*.24
for i in range(140):
    cx,cy=RNG.random(2);sx,sy=RNG.uniform(.002,.012,2)
    dx=np.minimum(abs(X-cx),1-abs(X-cx));dy=np.minimum(abs(Y-cy),1-abs(Y-cy))
    bead=np.clip(1-(dx/sx)**2-(dy/sy)**2,0,1)
    shade+=bead*RNG.uniform(-.11,.12);height+=bead*.12
save('earth',grey(shade,[1,.965,.90]),height,2)

# Fine grass/straw mark texture, without alpha cards or expensive ground shader.
g=fbm(31);shade=.80+(g-.5)*.28
im=Image.fromarray(np.uint8(np.clip(grey(shade,[.96,1,.89]),0,1)*255))
d=ImageDraw.Draw(im)
for i in range(1800):
    px,py=RNG.integers(0,SIZE,2);length=int(RNG.integers(2,9));tone=int(RNG.integers(145,215))
    tipx=int(px)+int(RNG.integers(-2,3));tipy=int(py)-length
    for ox in [-SIZE,0,SIZE]:
        for oy in [-SIZE,0,SIZE]:
            d.line((int(px)+ox,int(py)+oy,tipx+ox,tipy+oy),fill=(int(tone*.93),tone,int(tone*.83)),width=1)
save('grass',np.asarray(im)/255.,g*.25,1)

# Broad natural mineral grain with hairline cracks, not repeating brick stamps.
s=fbm(53);grain=noise(128,61);shade=.78+(s-.5)*.3+(grain-.5)*.045
vein=np.sin((X*3+Y*2)*np.pi*2+(noise(8,67)-.5)*6)
crack=np.clip((abs(vein)-.987)*55,0,1)
shade-=crack*.055
save('stone',grey(shade,[.98,1,1]),s*.27-crack*.12,2.5)

# Aged plaster: broad discoloration and restrained trowel texture.
p=fbm(79);fine=noise(96,83)
shade=.89+(p-.5)*.14+(fine-.5)*.025
save('plaster',grey(shade,[1,.989,.963]),p*.19+fine*.06,1.5)

# Vertical timber grain. Small ellipsoidal knots repeat seamlessly.
w=fbm(97)
wave=np.sin((X*42+noise(8,101)*.65+np.sin(Y*2*np.pi)*.35)*np.pi*2)
wave2=np.sin((X*93+noise(16,103)*.3)*np.pi*2)
shade=.84+(w-.5)*.16+wave*.025+wave2*.012
height=w*.1+wave*.12
for cx,cy in [(0.23,.29),(.71,.76)]:
    dx=np.minimum(abs(X-cx),1-abs(X-cx));dy=np.minimum(abs(Y-cy),1-abs(Y-cy))
    r=np.sqrt((dx/.025)**2+(dy/.075)**2)
    knot=np.exp(-r*2)
    shade-=knot*.22;height-=knot*.08
save('wood',grey(shade,[1,.965,.89]),height,2.5)

# Curved overlapping ceramic tiles: clear rows at screen scale, shallow normals.
rows=8
row=np.floor(Y*rows).astype(int);v=Y*rows-row
u=(X*8+(row%2)*.5)%1
seam=np.minimum(u,1-u)
edge=np.clip((.045-seam)/.045,0,1)
rowline=np.clip((.045-v)/.045,0,1)
curve=np.sin(u*np.pi)
h=(curve*.16+v*.06)*(1-rowline*.85)*(1-edge*.8)
r=fbm(127)
shade=.82+curve*.095-edge*.16-rowline*.21+(r-.5)*.08
save('roof',grey(shade,[1,.98,.95]),h,6.5)

# Plain coarse weave for banners and awnings. A single material map is tinted.
u=np.sin(X*256*np.pi);v=np.sin(Y*256*np.pi)
c=fbm(149)
shade=.86+(c-.5)*.1+(u+v)*.009
save('cloth',grey(shade,[1,1,.985]),(u+v)*.07+c*.03,1.7)


# Rounded, uneven courtyard cobbles, with dark packed earth between stones.
# The 512 px tile repeats every 2.4 m, not as individual mesh blocks.
shade=np.full((SIZE,SIZE),.39);h=np.full((SIZE,SIZE),.02)
rng=np.random.default_rng(173)
for row in range(8):
    for col in range(8):
        cx=(col+.5+(row%2)*.5)/8;cy=(row+.5)/8
        cx+=rng.uniform(-.008,.008);cy+=rng.uniform(-.008,.008)
        cx%=1;cy%=1
        dx=np.abs(X-cx);dy=np.abs(Y-cy)
        dx=np.minimum(dx,1-dx);dy=np.minimum(dy,1-dy)
        rx=.055+rng.uniform(-.004,.003);ry=.053+rng.uniform(-.004,.003)
        # Rounded rectangles keep the hand-laid pattern legible at phone size.
        distance=((dx/rx)**5+(dy/ry)**5)**.2
        stone=np.clip((1-distance)*12,0,1)
        tone=.72+rng.uniform(-.10,.10)
        shade=shade*(1-stone)+stone*(tone+(s-.5)*.10)
        h=np.maximum(h,stone*(.20+(s-.5)*.06))
save('paving',grey(shade,[.99,1,.98]),h,4.4)

print('Generated eight original 512 px albedo / normal pairs.')
