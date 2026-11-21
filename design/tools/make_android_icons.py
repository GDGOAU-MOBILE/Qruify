"""Builds the Android launcher icons from the dark variant of the Qruify icon.

Adaptive icon (Android 8+): solid near-black background + white QR layer, plus
a monochrome layer for Android 13 themed icons. Older Android gets a flat
rounded-square PNG. Run from anywhere: python3 make_android_icons.py
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, str(Path(__file__).parent))
from make_icon import OPTIONS, matrix

OPTION = 2
BG = (18, 18, 20)            # same near-black as the iOS dark variant
RES = Path(__file__).resolve().parents[2] / "android/app/src/main/res"

def ink_canvas(canvas_px):
    """White-on-transparent QR layer. The 1024 design sits in the middle
    2/3 of the 108dp adaptive canvas (the part every launcher shows); the code
    keeps going into the outer third, which launchers hide or use for motion."""
    tilt, S, cx, cy = OPTIONS[OPTION]
    n = len(matrix())
    m = np.array(matrix(), dtype=np.uint8)
    big = 4096
    k = big / 1024
    img = Image.fromarray((m * 255).astype(np.uint8)).resize((n * 16, n * 16), Image.NEAREST)
    img = img.resize((int(S * k), int(S * k)), Image.LANCZOS)
    rot = img.rotate(-90 + tilt, expand=True, resample=Image.BICUBIC, fillcolor=0)
    full = Image.new("L", (int(big * 1.5), int(big * 1.5)), 0)        # 1536-unit canvas
    off = big * 0.25                                                  # design starts at 256
    full.paste(rot, (int(off + cx * k - rot.width / 2), int(off + cy * k - rot.height / 2)))
    full = full.resize((canvas_px, canvas_px), Image.LANCZOS)
    layer = Image.new("RGBA", (canvas_px, canvas_px), (255, 255, 255, 0))
    layer.putalpha(full)
    return layer

def legacy(px):
    """Flat rounded-square icon for Android 7 and older (design = whole icon)."""
    tilt, S, cx, cy = OPTIONS[OPTION]
    ss = px * 4
    layer = ink_canvas(int(ss * 1.5))
    off = int(ss * 0.25)
    crop = layer.crop((off, off, off + ss, off + ss))
    base = Image.new("RGBA", (ss, ss), BG + (255,))
    base.alpha_composite(crop)
    mask = Image.new("L", (ss, ss), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, ss - 1, ss - 1), radius=int(ss * 0.22), fill=255)
    base.putalpha(mask)
    return base.resize((px, px), Image.LANCZOS)

DENSITY = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
for name, scale in DENSITY.items():
    d = RES / f"mipmap-{name}"; d.mkdir(parents=True, exist_ok=True)
    ink_canvas(int(108 * scale)).save(d / "ic_launcher_foreground.png")
    legacy(int(48 * scale)).save(d / "ic_launcher.png")

(RES / "mipmap-anydpi-v26").mkdir(exist_ok=True)
(RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
'''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
(RES / "values/ic_launcher_background.xml").write_text(
'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#121214</color>
</resources>
''')
print("Android icons written to", RES)
