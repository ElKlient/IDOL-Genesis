#!/usr/bin/env python3
"""Original needle spray cutout, generated at authoring time; Pillow only."""
from pathlib import Path
import random, math
from PIL import Image, ImageDraw

rng = random.Random(651419)
im = Image.new('RGBA', (256,512))
d = ImageDraw.Draw(im)
stem = [(128+math.sin(y*.025)*2,y) for y in range(18,496,6)]
d.line(stem, fill=(106,100,60,255), width=4)
for y in range(38,484,15):
    width = 18+80*math.sin((y-20)/490*math.pi)**.8
    for side in [-1,1]:
        endx = 128+side*width*rng.uniform(.85,1.1)
        endy = y-rng.uniform(25,49)
        d.line((128,y,endx,endy),fill=(74,94,55,255),width=3)
        for j in range(13):
            u = (j+1)/14
            px = 128+(endx-128)*u
            py = y+(endy-y)*u
            for sign in [-1,1]:
                tipx = px+side*rng.uniform(5,13)
                tipy = py+sign*rng.uniform(9,21)-5
                value = rng.randint(0,35)
                d.line((px,py,tipx,tipy), fill=(74+value,102+value,57+value//2,255),width=2)
out = Path(__file__).with_name('pine_spray.png')
im.save(out,optimize=True)
print(f'{out.name}: 256x512 RGBA, {out.stat().st_size} bytes')
