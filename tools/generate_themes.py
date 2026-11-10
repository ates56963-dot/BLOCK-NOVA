"""Procedurally generate eight original vertical puzzle-game background textures."""
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFilter
ROOT=Path(__file__).resolve().parents[1]/'assets/themes'
W,H=640,1280
COLS=[((9,10,39),(40,20,100),(23,150,210)),((5,20,38),(9,75,120),(45,155,235)),
      ((31,19,9),(99,65,20),(242,172,65)),((17,7,36),(75,30,112),(169,68,250)),
      ((4,29,45),(10,78,112),(23,191,172)),((37,13,34),(111,35,75),(250,122,50)),
      ((5,35,25),(23,100,72),(51,210,117)),((15,17,25),(40,47,58),(95,109,134))]
rng=np.random.default_rng(7122026)
y,x=np.mgrid[0:H,0:W].astype('float32')
for variant,(top,mid,glow) in enumerate(COLS):
    t=y/H
    arr=np.zeros((H,W,3),dtype=np.float32)
    for c in range(3): arr[:,:,c]=top[c]*(1-t)+mid[c]*t*0.55
    centers=[(W*0.46,H*0.18,230),(W*0.82,H*0.55,195),(W*0.12,H*0.82,190)]
    for k,(cx,cy,rr) in enumerate(centers):
        rr*=1.1
        g=np.exp(-(((x-cx)/rr)**2+((y-cy)/(rr*1.75))**2)*2.5)
        for c in range(3): arr[:,:,c]+=g*glow[c]*(0.16 if k==0 else 0.065)
    wave=np.sin(x/72+y/102+variant*0.9)*np.cos(x/155-y/82)
    for c in range(3):arr[:,:,c]+=wave*glow[c]*0.025
    im=Image.fromarray(np.uint8(np.clip(arr,0,255)),'RGB').convert('RGBA')
    draw=ImageDraw.Draw(im,'RGBA')
    for k in range(115 if variant in (0,3) else 56):
        sx=int(rng.integers(0,W));sy=int(rng.integers(0,H));radius=int(rng.choice([1,1,1,2]))
        draw.ellipse((sx-radius,sy-radius,sx+radius,sy+radius),fill=(*glow, int(rng.integers(26,99))))
    if variant==0:  # orbit arcs
        for i in range(4):
            draw.arc((-200+i*30,170+i*38,770+i*12,990+i*12),205,335,fill=(*glow,28+i*9),width=2)
    if variant==1:  # crystal facets
        for i in range(17):
            cx=int(rng.integers(-20,670));cy=int(rng.integers(0,1250));s=int(rng.integers(55,170))
            draw.polygon([(cx,cy-s),(cx+s//2,cy-s//4),(cx+s//3,cy+s),(cx-s//2,cy+s//2)],outline=(*glow,30),width=2)
    if variant==2:  # gold rays
        for i in range(26):
            sx=i*48-500
            draw.line((sx,0,sx+480,H),fill=(*glow,20),width=3)
    if variant==3:  # perspective cyber grid
        for i in range(0,W,64):draw.line((i,0,i,H),fill=(*glow,24),width=1)
        for i in range(0,H,64):draw.line((0,i,W,i),fill=(*glow,24),width=1)
    if variant==4:  # ocean caustic waves
        for j in range(10):
            yy=130+j*112
            pts=[(xx,yy+int(22*np.sin(xx/66+j*0.82))) for xx in range(0,W,5)]
            draw.line(pts,fill=(*glow,28),width=3)
    if variant==5:  # horizon and dunes
        for j in range(4):
            yy=340+j*132
            pts=[(xx,yy+int(38*np.sin(xx/95+j*0.9))) for xx in range(0,W,3)]
            draw.line(pts,fill=(*glow,35),width=2)
    if variant==6:  # emerald leaf-like diamonds
        for j in range(18):
            cx=int(rng.integers(0,W));cy=int(rng.integers(0,H));sy=int(rng.integers(25,100))
            draw.polygon([(cx,cy-sy),(cx+sy//2,cy),(cx,cy+sy),(cx-sy//2,cy)],outline=(*glow,28),width=2)
    if variant==7:
        for j in range(3):draw.arc((-350+j*70,300+j*45,850-j*60,1200-j*60),210,332,fill=(*glow,30),width=1)
    im.convert('RGB').save(ROOT/f'theme_{variant}.webp',format='WEBP',quality=80,method=5)
    print(variant,(ROOT/f'theme_{variant}.webp').stat().st_size)
