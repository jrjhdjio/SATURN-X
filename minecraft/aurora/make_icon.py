"""Render an original geometric pack badge; Pillow is only a build-time dependency."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math
ROOT=Path(__file__).resolve().parent
S=1024
im=Image.new('RGB',(S,S)); px=im.load()
for y in range(S):
    for x in range(S):
        t=y/(S-1); glow=math.exp(-(((x-760)/580)**2+((y-260)/560)**2)*3)
        px[x,y]=(int(9+13*t+10*glow),int(19+22*t+54*glow),int(40+26*t+54*glow))
d=ImageDraw.Draw(im)
d.rounded_rectangle((44,44,980,980),radius=150,outline=(92,171,178),width=3)
# Sun and low mountain geometry, all authored as simple vector shapes.
d.ellipse((570,215,770,415),fill=(255,207,143))
d.polygon([(110,645),(385,270),(565,525),(680,390),(950,645)],fill=(43,115,134))
d.polygon([(385,270),(510,445),(419,407),(384,359),(341,404),(298,397)],fill=(204,235,225))
d.polygon([(110,645),(385,270),(368,474),(525,645)],fill=(28,82,108))
d.polygon([(105,645),(275,518),(414,645),(655,451),(949,645)],fill=(14,48,75))
for i in range(6):
    y=660+i*17; w=175+i*22
    d.line((S//2-w,y,S//2+w,y),fill=(59,135-i*8,158-i*7),width=4)
font='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
font2='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
def txt(text,y,size,color,fontname):
    try:f=ImageFont.truetype(fontname,size)
    except OSError:f=ImageFont.load_default(size=size)
    d.text((S/2,y),text,anchor='mm',font=f,fill=color)
txt('SATURN X',153,34,(139,215,218),font)
txt('AURORA',816,95,(244,240,221),font)
txt('VIBRANT VISUALS',902,25,(130,177,192),font2)
(ROOT/'pack').mkdir(exist_ok=True)
im.resize((256,256),Image.Resampling.LANCZOS).save(ROOT/'pack/pack_icon.png')
