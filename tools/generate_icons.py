"""Procedural original BLOCK NOVA launch icons. No external images required."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, random
random.seed(92026)
ROOT = Path(__file__).resolve().parents[1] / 'assets'
ROOT.mkdir(parents=True,exist_ok=True)
S=512

def icon(foreground_only=False):
    im=Image.new('RGBA',(S,S),(0,0,0,0))
    if not foreground_only:
        bg=Image.new('RGBA',(S,S)); p=bg.load()
        for y in range(S):
            for x in range(S):
                r=((x-260)**2+(y-200)**2)**.5/420
                p[x,y]=(int(12+32*(1-r)),int(7+15*(1-r)),int(37+68*(1-r)),255)
        im.alpha_composite(bg)
        stars=Image.new('RGBA',(S,S));d=ImageDraw.Draw(stars)
        for i in range(65):
            x=random.randrange(10,S-10);y=random.randrange(10,S-10);a=random.randrange(45,130)
            d.ellipse((x-1,y-1,x+1,y+1),fill=(155,198,255,a))
        im.alpha_composite(stars)
    glow=Image.new('RGBA',(S,S)); gd=ImageDraw.Draw(glow)
    cubes=[(150,120,(35,202,254)),(258,117,(112,93,249)),(98,222,(242,177,54)),(205,225,(196,68,242)),(312,219,(242,68,167)),(154,330,(42,207,139)),(263,330,(44,153,250))]
    for x,y,c in cubes:
        gd.rounded_rectangle((x-5,y-5,x+108,y+108),radius=23,fill=(*c,110))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(23)))
    draw=ImageDraw.Draw(im)
    for x,y,c in cubes:
        dark=tuple(max(0,int(v*.52)) for v in c)
        draw.rounded_rectangle((x,y+6,x+98,y+103),radius=16,fill=(*dark,255),outline=(224,228,255,90),width=2)
        draw.rounded_rectangle((x+4,y,x+94,y+92),radius=13,fill=(*c,255))
        light=tuple(min(255,int(v*.75)+62) for v in c)
        draw.polygon([(x+14,y+10),(x+80,y+10),(x+68,y+30),(x+28,y+35)],fill=(*light,195))
        draw.line((x+10,y+77,x+10,y+24),fill=(255,255,255,150),width=3)
        draw.arc((x+6,y+5,x+92,y+92),183,325,fill=(255,255,255,170),width=3)
    return im

icon().convert('RGB').save(ROOT/'icon.png',compress_level=9)
icon().resize((192,192),Image.Resampling.LANCZOS).convert('RGB').save(ROOT/'icon_192.png',compress_level=9)
icon(foreground_only=True).resize((432,432),Image.Resampling.LANCZOS).save(ROOT/'adaptive_fg_432.png',compress_level=9)
bg=Image.new('RGB',(432,432),(14,12,51))
bg.save(ROOT/'adaptive_bg_432.png')
print('Generated Android launcher icons')
