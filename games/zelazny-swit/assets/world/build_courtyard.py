#!/usr/bin/env python3
"""Original weathered irregular cobbles, seamless colour and bevel normals."""
from pathlib import Path
import numpy as np
from PIL import Image

size = 512
y,x = np.mgrid[0:size,0:size].astype(float)/size
rng = np.random.default_rng(22102026)
nearest = np.full((size,size),100.0)
second = nearest.copy()
ids = np.zeros((size,size),int)
tones = rng.uniform(.72,.98,64)
for row in range(8):
    for col in range(8):
        i = row*8+col
        cx = (col+.5+(row%2)*.45+rng.uniform(-.16,.16))/8
        cy = (row+.5+rng.uniform(-.15,.15))/8
        dx = np.abs(x-cx); dx = np.minimum(dx,1-dx)
        dy = np.abs(y-cy); dy = np.minimum(dy,1-dy)
        # Rounded, elongated setts rather than a field of regular rectangles.
        dist = np.sqrt((dx*.88)**2+(dy*1.12)**2)
        better = dist < nearest
        second = np.where(better,nearest,np.minimum(second,dist))
        nearest = np.minimum(nearest,dist)
        ids = np.where(better,i,ids)
edge = second-nearest
bevel = np.clip((edge-.0025)/.009,0,1)
bevel = bevel*bevel*(3-2*bevel)
grain = np.random.default_rng(772).random((size,size))
weather = np.sin(x*np.pi*12+np.sin(y*np.pi*8))*np.cos(y*np.pi*10)*.018
stone = tones[ids]+weather+(grain-.5)*.045
colour = .25*(1-bevel)+stone*bevel
# Sparse mineral flecks and soil pores, subordinate to the main bevel shapes.
colour -= (grain>.985)*.055*bevel
height = bevel*.65+(stone-.8)*.12*bevel
dx = (np.roll(height,-1,1)-np.roll(height,1,1))*4.5
dy = (np.roll(height,-1,0)-np.roll(height,1,0))*4.5
normal = np.stack([-dx,dy,np.ones_like(dx)],axis=-1)
normal /= np.linalg.norm(normal,axis=-1,keepdims=True)
rgb = np.stack([colour*.99,colour,colour*.96],axis=-1)
out = Path(__file__).parent
Image.fromarray(np.uint8(np.clip(rgb,0,1)*255)).save(out/'paving_albedo.png',optimize=True)
Image.fromarray(np.uint8(np.clip(normal*.5+.5,0,1)*255)).save(out/'paving_normal.png',optimize=True)
print('paving_albedo.png / paving_normal.png: seamless 512 square weathered cobbles')
