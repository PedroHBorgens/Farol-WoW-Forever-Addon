from PIL import Image, ImageDraw, ImageFilter
import sys
N = 1024
def lerp(a, b, t): return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(len(a)))

img = Image.new("RGBA", (N, N))
d = ImageDraw.Draw(img)
# céu noturno (gradiente)
top, bottom = (8, 20, 48, 255), (34, 70, 120, 255)
for y in range(N):
    d.line([(0, y), (N, y)], fill=lerp(top, bottom, y / N))
# estrelas
for (x, y, r) in [(120,140,7),(260,90,5),(840,120,6),(930,260,5),(700,70,4),(80,330,4),(380,190,4)]:
    d.ellipse([x-r, y-r, x+r, y+r], fill=(255, 250, 220, 255))

lamp = (N*0.5, N*0.33)
# fachos de luz (camada translúcida desfocada)
beams = Image.new("RGBA", (N, N), (0,0,0,0))
bd = ImageDraw.Draw(beams)
bd.polygon([lamp, (0, N*0.12), (0, N*0.42)], fill=(255, 230, 120, 120))
bd.polygon([lamp, (N, N*0.20), (N, N*0.50)], fill=(255, 230, 120, 120))
beams = beams.filter(ImageFilter.GaussianBlur(10))
img = Image.alpha_composite(img, beams)
# brilho em volta da lâmpada
glow = Image.new("RGBA", (N, N), (0,0,0,0))
gd = ImageDraw.Draw(glow)
gd.ellipse([lamp[0]-170, lamp[1]-170, lamp[0]+170, lamp[1]+170], fill=(255, 220, 100, 140))
glow = glow.filter(ImageFilter.GaussianBlur(60))
img = Image.alpha_composite(img, glow)
d = ImageDraw.Draw(img)

# mar
sea_top = N*0.80
for y in range(int(sea_top), N):
    d.line([(0, y), (N, y)], fill=lerp((14, 60, 90, 255), (6, 30, 50, 255), (y - sea_top)/(N - sea_top)))
for i, y in enumerate([N*0.84, N*0.90, N*0.96]):
    for x0 in range(-60 + i*40, N, 160):
        d.arc([x0, y-18, x0+120, y+18], 200, 340, fill=(120, 190, 220, 255), width=10)

# rocha
d.ellipse([N*0.22, N*0.74, N*0.78, N*0.90], fill=(52, 48, 56, 255))
d.ellipse([N*0.30, N*0.72, N*0.70, N*0.84], fill=(72, 66, 74, 255))

# torre (trapézio com listras)
tb, tt = N*0.79, N*0.42           # base e topo
wb, wt = N*0.30, N*0.18           # larguras
cx = N*0.5
def xat(y):
    t = (tb - y) / (tb - tt)
    w = wb + (wt - wb) * t
    return cx - w/2, cx + w/2
bands = 5
for i in range(bands):
    y1 = tb - (tb-tt) * i / bands
    y0 = tb - (tb-tt) * (i+1) / bands
    l1, r1 = xat(y1); l0, r0 = xat(y0)
    color = (200, 40, 40, 255) if i % 2 == 0 else (245, 245, 240, 255)
    d.polygon([(l1, y1), (r1, y1), (r0, y0), (l0, y0)], fill=color)
# sombra lateral da torre
l1, r1 = xat(tb); l0, r0 = xat(tt)
shade = Image.new("RGBA", (N, N), (0,0,0,0))
ImageDraw.Draw(shade).polygon([(cx + (r1-cx)*0.35, tb), (r1, tb), (r0, tt), (cx + (r0-cx)*0.35, tt)], fill=(0,0,0,60))
img = Image.alpha_composite(img, shade); d = ImageDraw.Draw(img)
# porta
d.rounded_rectangle([cx-30, tb-110, cx+30, tb], radius=28, fill=(60, 35, 30, 255))

# galeria (varanda)
d.rectangle([cx - N*0.13, tt - 26, cx + N*0.13, tt + 6], fill=(40, 40, 46, 255))
# sala da lanterna (vidro aceso)
lt, lb = N*0.27, tt - 26
d.rectangle([cx - N*0.075, lt, cx + N*0.075, lb], fill=(255, 225, 110, 255))
for k in (-1, 0, 1):
    x = cx + k * N*0.04
    d.line([(x, lt), (x, lb)], fill=(60, 50, 40, 255), width=8)
d.ellipse([lamp[0]-34, lamp[1]-34, lamp[0]+34, lamp[1]+34], fill=(255, 255, 230, 255))
# teto
d.polygon([(cx - N*0.11, lt + 4), (cx + N*0.11, lt + 4), (cx, N*0.17)], fill=(170, 30, 30, 255))
d.ellipse([cx-18, N*0.17-24, cx+18, N*0.17+12], fill=(170, 30, 30, 255))

# moldura dourada estilo ícone
frame = Image.new("RGBA", (N, N), (0,0,0,0))
fd = ImageDraw.Draw(frame)
for w, c in ((44, (90, 64, 20, 255)), (30, (214, 170, 70, 255)), (12, (255, 225, 140, 255))):
    fd.rectangle([0, 0, N-1, N-1], outline=c, width=w)
img = Image.alpha_composite(img, frame)

out_dir = sys.argv[1]
icon64 = img.resize((64, 64), Image.LANCZOS)
icon64.save(f"{out_dir}/Farol/Media/Farol.tga")                 # usado pelo jogo
img.resize((400, 400), Image.LANCZOS).save(f"{out_dir}/assets/farol-icon-400.png")  # CurseForge
img.resize((512, 512), Image.LANCZOS).save(f"{out_dir}/assets/farol-icon-512.png")
# prévia: como aparece pequeno
prev = Image.new("RGBA", (64*4+20*3, 64*4), (30, 30, 30, 255))
prev.paste(icon64.resize((256, 256), Image.NEAREST), (0, 0))
for i, s in enumerate((16, 24, 32)):
    prev.paste(img.resize((s, s), Image.LANCZOS), (256 + 10 + i*24, 10 + i*40))
print("ok")
