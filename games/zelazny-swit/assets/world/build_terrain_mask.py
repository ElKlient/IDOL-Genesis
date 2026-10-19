#!/usr/bin/env python3
"""Original Brzeziny landscape control map. Authoring only; NumPy + Pillow.

R: worn earth, G: cobblestones, B: broad colour variation, A: contact shade.
World coordinates span -50..50 m. Nothing is generated/downloaded on the phone.
"""
from pathlib import Path
import numpy as np
from PIL import Image

SIZE = 512
z, x = np.mgrid[0:SIZE, 0:SIZE].astype(float)
x = (x + .5) / SIZE * 100 - 50
z = (z + .5) / SIZE * 100 - 50

def smooth(a, b, v):
    t = np.clip((v-a)/(b-a), 0, 1)
    return t*t*(3-2*t)

def segment(ax, az, bx, bz):
    dx, dz = bx-ax, bz-az
    t = np.clip(((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz), 0, 1)
    return np.hypot(x-ax-t*dx, z-az-t*dz)

# Different wavelengths avoid a regular scalloped boundary or repeated stamps.
wear = (np.sin(x*1.9+np.cos(z*.7))*.13
        + np.sin(z*2.3+x*.37)*.09 + np.cos(x*4.7-z*3.9)*.035)
earth = np.zeros_like(x)
for ax, az, bx, bz, width in [(0,15,0,-18,4.2),(0,-18,-1,-27,3.3),
                              (-1,-27,1,-36,3),(1,-36,0,-43,2.4),
                              (-10,0,10,0,3.2)]:
    earth = np.maximum(earth, 1-smooth(width*.5-.25,width*.5+.85,segment(ax,az,bx,bz)+wear))
# Village common, worn around houses and shops. Soft soil/grass transition.
oval = np.sqrt((x/12.1)**2+((z-2)/11.9)**2)
earth = np.maximum(earth, 1-smooth(.89,1.09,oval+wear*.021))
plaza = np.sqrt((x/4.6)**2+((z-3.7)/4.25)**2)
paving = 1-smooth(.80,1.08,plaza+wear*.05)
# A narrow paved approach, interrupted by exposed earth at the edges.
paving = np.maximum(paving, (1-smooth(1.15,1.72,np.abs(x)+wear))
                    * smooth(-13,-11,z) * (1-smooth(7,9,z)) * .88)
variation = .5+np.sin(x*.21+np.sin(z*.17))*.17+np.cos(z*.41-x*.13)*.11
shade = np.zeros_like(x)
for cx, cz, rx, rz in [(-9,-3.2,3.2,2.9),(9.5,-3.6,3.3,3.1),
                       (-12.4,7.5,2.9,3),(12.9,8,3.1,3.2),
                       (-12.8,-10.5,2.6,2.3),(11.6,-10.2,2.6,2.3),
                       (-3.1,6.5,1.2,1.2),(8.4,-1.2,1.2,1.1)]:
    d = np.sqrt(((x-cx)/rx)**2+((z-cz)/rz)**2)
    shade = np.maximum(shade, (1-smooth(.72,1.30,d))*.30)
rgba = np.stack([earth,paving,variation,shade], axis=-1)
path = Path(__file__).with_name('terrain_control.png')
Image.fromarray(np.uint8(np.clip(rgba,0,1)*255)).save(path, optimize=True)
print(f'{path.name}: {SIZE}x{SIZE} RGBA, {path.stat().st_size} bytes')
