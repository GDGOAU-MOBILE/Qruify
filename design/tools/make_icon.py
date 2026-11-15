"""Builds the Qruify app icon as an Apple Icon Composer bundle.

The icon is a real QR code (encodes TEXT) that is rotated so its one corner
without a finder pattern points at the bottom-left of the icon, then tilted.
The icon edge clips that corner, and the code still scans.

Usage: python3 make_icon.py [option]   (option: 1, 2 or 3; default 1)
"""
import json, sys
from pathlib import Path
import qrcode

TEXT = "Qruify"
# option: (tilt degrees, QR side px, center x, center y) on a 1024 canvas.
# Each was checked with Apple's Vision framework to still decode on light,
# dark and colored backgrounds.
OPTIONS = {
    1: (-20, 560, 225, 700),   # small, sharp tilt, mostly white icon
    2: (10, 680, 300, 700),    # bolder
    3: (-10, 740, 375, 700),   # largest
}

def matrix():
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_H, border=0, box_size=1)
    qr.add_data(TEXT); qr.make(fit=True)
    return qr.get_matrix()

def qr_svg(option, color):
    tilt, side, cx, cy = OPTIONS[option]
    m = matrix(); n = len(m); u = side / n
    # Rotating 90 degrees clockwise puts the finder-free corner at the bottom-left,
    # then `tilt` is the extra tilt. (SVG rotates clockwise for positive angles.)
    angle = 90 - tilt
    rects = []
    for r, row in enumerate(m):
        for c, dark in enumerate(row):
            if dark:
                # tiny overlap hides hairline seams between neighbouring modules
                rects.append(f'<rect x="{c*u - side/2:.3f}" y="{r*u - side/2:.3f}" width="{u+0.4:.3f}" height="{u+0.4:.3f}"/>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'
            f'<g fill="{color}" transform="translate({cx} {cy}) rotate({angle})">' + "".join(rects) + '</g></svg>')

def build(option, out):
    out = Path(out); (out / "Assets").mkdir(parents=True, exist_ok=True)
    (out / "Assets" / "qr.svg").write_text(qr_svg(option, "#000000"))
    icon = {
        "fill": {"solid": "display-p3:1.00000,1.00000,1.00000,1.00000"},
        "fill-specializations": [
            {"value": {"solid": "display-p3:1.00000,1.00000,1.00000,1.00000"}},
            {"appearance": "dark", "value": {"solid": "display-p3:0.07000,0.07000,0.08000,1.00000"}},
        ],
        "groups": [{
            "layers": [{
                "image-name": "qr.svg",
                "name": "qr",
                "glass": False,
                "fill-specializations": [
                    {"value": {"solid": "display-p3:0.00000,0.00000,0.00000,1.00000"}},
                    {"appearance": "dark", "value": {"solid": "display-p3:1.00000,1.00000,1.00000,1.00000"}},
                ],
            }],
            "shadow": {"kind": "none", "opacity": 0},
            "translucency": {"enabled": False, "value": 0},
        }],
        "supported-platforms": {"squares": "shared"},
    }
    (out / "icon.json").write_text(json.dumps(icon, indent=2))

if __name__ == "__main__":
    opt = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    build(opt, Path(__file__).resolve().parent.parent / "AppIcon.icon")
    print("wrote AppIcon.icon for option", opt)
