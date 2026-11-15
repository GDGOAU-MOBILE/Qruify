"""Draws the review board: three layout options, and option 1 in each appearance.
Dark and tinted are approximations of how iOS renders them."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
sys.path.insert(0, str(Path(__file__).parent))
from make_icon import OPTIONS, matrix

OPT = int(sys.argv[1]) if len(sys.argv) > 1 else 1
W = 1024
yy, xx = np.mgrid[0:W, 0:W]
u = (xx - W / 2 + .5) / (W / 2); v = (yy - W / 2 + .5) / (W / 2)
MASK = Image.fromarray((((np.abs(u) ** 5 + np.abs(v) ** 5) <= 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))

def qr_layer(option):
    tilt, S, cx, cy = OPTIONS[option]
    m = np.array(matrix(), dtype=np.uint8); n = len(m)
    img = Image.fromarray((m * 255).astype(np.uint8)).resize((n * 16, n * 16), Image.NEAREST).resize((S, S), Image.LANCZOS)
    alpha = img                                  # 255 where dark
    rot = alpha.rotate(-90 + tilt, expand=True, resample=Image.BICUBIC, fillcolor=0)
    layer = Image.new("L", (W * 3, W * 3), 0)
    layer.paste(rot, (int(W + cx - rot.width / 2), int(W + cy - rot.height / 2)))
    return layer.crop((W, W, 2 * W, 2 * W))      # ink alpha, 255 = QR module

def icon(option, mode):
    ink = qr_layer(option)
    if mode == "light":
        bg, fg = (255, 255, 255), (0, 0, 0)
    elif mode == "dark":
        bg, fg = (18, 18, 20), (255, 255, 255)
    else:                                        # tinted: grayscale art over a dark base, tinted
        grad = np.linspace(46, 20, W)[:, None].repeat(W, 1)
        base = np.stack([grad * 0.9, grad * 0.95, grad * 1.1], -1).astype(np.uint8)
        canvas = Image.fromarray(base)
        tint = Image.new("RGB", (W, W), (255, 176, 66))
        canvas.paste(tint, (0, 0), ink)
        return canvas
    canvas = Image.new("RGB", (W, W), bg)
    canvas.paste(Image.new("RGB", (W, W), fg), (0, 0), ink)
    return canvas

def shown(img, size, wall):
    s = Image.new("RGB", (size, size), wall)
    k = int(size * 0.78)
    ic = img.resize((k, k), Image.LANCZOS); mk = MASK.resize((k, k), Image.LANCZOS)
    shadow = Image.new("L", (size, size), 0)
    shadow.paste(mk, ((size - k) // 2, (size - k) // 2 + 8))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14)).point(lambda p: int(p * 0.25))
    s.paste(Image.new("RGB", (size, size), (0, 0, 0)), (0, 0), shadow)
    s.paste(ic, ((size - k) // 2, (size - k) // 2), mk)
    return s

font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 30)
cell, gap, top = 520, 0, 70
board = Image.new("RGB", (cell * 3, top + cell * 2 + top), (236, 236, 240))
d = ImageDraw.Draw(board)
titles1 = ["Option 1: peek", "Option 2: bold (chosen)", "Option 3: large"]
for i in (1, 2, 3):
    board.paste(shown(icon(i, "light"), cell, (236, 236, 240)), ((i - 1) * cell, top))
    d.text(((i - 1) * cell + 24, 20), titles1[i - 1], fill=(30, 30, 34), font=font)
for j, (mode, label) in enumerate([("light", "Default"), ("dark", "Dark"), ("tint", "Tinted (approximation)")]):
    wall = {"light": (236, 236, 240), "dark": (28, 28, 32), "tint": (60, 60, 70)}[mode]
    tile = shown(icon(OPT, mode), cell, wall)
    board.paste(tile, (j * cell, top * 2 + cell - 50))
    d.text((j * cell + 24, top + cell - 14), f"Option {OPT}, {label}", fill=(30, 30, 34), font=font)
board = board.crop((0, 0, cell * 3, top + cell * 2 + 20))
out = Path(__file__).resolve().parent.parent / "previews"
board.save(out / "icon-review.png")
for m, n in (("light", "default"), ("dark", "dark"), ("tint", "tinted")):
    icon(OPT, m).save(out / f"option{OPT}-{n}-1024.png")
print("saved")
