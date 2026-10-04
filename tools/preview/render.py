#!/usr/bin/env python3
"""Renders a vehicle or weapon model file to a PNG contact sheet of orthographic views.

Usage:
  python3 tools/preview/render.py src/server/vehicleModels/<id>.luau [out.png]
      [--views front34,rear34,left,front,top,rear] [--panel 640x420]
      [--focus x,y,z,radius] [--no-overlay]
  python3 tools/preview/render.py src/server/weaponModels/<id>.luau [out.png] [--weapon]
      [--views left,front,top,front34] ...

Files under a `weaponModels` folder render as weapons without --weapon.

Needs `lune` (rokit) and Pillow. Shapes follow Roblox: Block, Ball (diameter = smallest size),
Cylinder (axis along local X, diameter = smaller of Y and Z), WedgePart (full bottom and +Z back
faces, slope rising from the -Z bottom edge to the +Z top edge).

Overlays, drawn on top of the model so they show through it:
  cyan    the skid (footprint, ground to 1 stud)
  orange  collision boxes
  green   seat blocks
  red     the seated avatar envelope above each seat (torso and head, then legs forward)

Weapons render in the wielder's frame after the hold (WeaponModel.grip): the tool-hold pose's
right arm points straight ahead along -Z, +Y is up, +X is the wielder's right. "front" looks back
at the wielder from the target. Overlays:
  red      the fist, a 0.5 stud box at the grip origin
  orange   the forearm, 0.5 x 0.5 x 2.5 studs running from the fist back toward the wielder (+Z)
  magenta  the muzzle (where shot effects start), if the model sets one
"""

import argparse
import json
import math
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EXPORT = os.path.join(ROOT, "tools", "preview", "export.luau")

SS = 2  # supersampling
LIGHT = None

# Seated avatar envelope above a seat's top face, in seat space (-Z forward).
# Assumed R15 proportions: hips on the seat, head top 4 studs above it, legs 2.6 studs forward.
AVATAR_BODY = ((-1.0, 0.0, -0.5), (1.0, 4.0, 0.6))
AVATAR_LEGS = ((-1.0, 0.0, -2.6), (1.0, 1.0, -0.5))

# Wielder's fist and forearm in the grip frame (tool-hold pose: arm horizontal, pointing -Z).
FIST = ((-0.25, -0.25, -0.25), (0.25, 0.25, 0.25))
FOREARM = ((-0.25, -0.25, 0.25), (0.25, 0.25, 2.75))
IDENTITY = (0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

VIEWS = {
    "front34": ("front 3/4 (front-left)", (-1.0, 0.65, -1.0)),
    "rear34": ("rear 3/4 (rear-right)", (1.0, 0.6, 1.0)),
    "left": ("left side (-X)", (-1.0, 0.0, 0.0)),
    "right": ("right side (+X)", (1.0, 0.0, 0.0)),
    "front": ("front (-Z)", (0.0, 0.0, -1.0)),
    "rear": ("rear (+Z)", (0.0, 0.0, 1.0)),
    "top": ("top (front up)", (0.0, 1.0, 0.0)),
    "under": ("underside", (0.0, -1.0, 0.0)),
}


class Raster:
    """Z-buffered flat-shaded triangle rasterizer over an RGBA background image."""

    def __init__(self, w, h, background, img):
        self.w, self.h = w, h
        self.pixels = bytearray(img.convert("RGB").tobytes())
        self.depth = [math.inf] * (w * h)

    def triangle(self, a, b, c, fill, write):
        w, h = self.w, self.h
        (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = a, b, c
        area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if abs(area) < 1e-9:
            return
        # Depth plane z = zx * x + zy * y + zc.
        zx = ((z1 - z0) * (y2 - y0) - (z2 - z0) * (y1 - y0)) / area
        zy = ((x1 - x0) * (z2 - z0) - (x2 - x0) * (z1 - z0)) / area
        zc = z0 - zx * x0 - zy * y0
        r, g, bl, alpha = fill
        al = alpha / 255.0
        pixels, depth = self.pixels, self.depth
        ymin = max(0, int(math.ceil(min(y0, y1, y2) - 0.5)))
        ymax = min(h - 1, int(math.floor(max(y0, y1, y2) - 0.5)))
        edges = ((x0, y0, x1, y1), (x1, y1, x2, y2), (x2, y2, x0, y0))
        for py in range(ymin, ymax + 1):
            yc = py + 0.5
            lo, hi = math.inf, -math.inf
            for ax, ay, bx, by in edges:
                if (ay <= yc < by) or (by <= yc < ay):
                    x = ax + (yc - ay) * (bx - ax) / (by - ay)
                    lo = min(lo, x)
                    hi = max(hi, x)
            if lo > hi:
                continue
            xs = max(0, int(math.ceil(lo - 0.5)))
            xe = min(w - 1, int(math.floor(hi - 0.5)))
            if xs > xe:
                continue
            row = py * w
            z = zx * (xs + 0.5) + zy * yc + zc - 1e-4
            for px in range(xs, xe + 1):
                i = row + px
                if z < depth[i]:
                    j = i * 3
                    if write:
                        depth[i] = z
                        pixels[j] = r
                        pixels[j + 1] = g
                        pixels[j + 2] = bl
                    else:
                        pixels[j] = int(pixels[j] + (r - pixels[j]) * al)
                        pixels[j + 1] = int(pixels[j + 1] + (g - pixels[j + 1]) * al)
                        pixels[j + 2] = int(pixels[j + 2] + (bl - pixels[j + 2]) * al)
                z += zx

    def line(self, a, b, color, bias):
        """Depth-tested line; `bias` is in depth units (studs)."""
        w, h = self.w, self.h
        (x0, y0, z0), (x1, y1, z1) = a, b
        steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 1.5) + 1
        pixels, depth = self.pixels, self.depth
        r, g, bl = color
        for k in range(steps + 1):
            t = k / steps
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            px, py = int(x), int(y)
            if 0 <= px < w and 0 <= py < h:
                i = py * w + px
                if z0 + (z1 - z0) * t <= depth[i] + bias:
                    j = i * 3
                    pixels[j], pixels[j + 1], pixels[j + 2] = r, g, bl

    def image(self):
        return Image.frombytes("RGB", (self.w, self.h), bytes(self.pixels)).convert("RGBA")


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def scale(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def norm(a):
    length = math.sqrt(dot(a, a))
    return (a[0] / length, a[1] / length, a[2] / length) if length > 1e-12 else (0.0, 0.0, 0.0)


LIGHT = norm((-0.45, 1.0, -0.6))


def transform(cf, p):
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf
    return (
        x + r00 * p[0] + r01 * p[1] + r02 * p[2],
        y + r10 * p[0] + r11 * p[1] + r12 * p[2],
        z + r20 * p[0] + r21 * p[1] + r22 * p[2],
    )


def box_faces(sx, sy, sz):
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    v = [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
         (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)]
    idx = [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4), (3, 2, 6, 7), (0, 3, 7, 4), (1, 2, 6, 5)]
    return [[v[i] for i in f] for f in idx]


def wedge_faces(sx, sy, sz):
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    return [
        [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz)],  # bottom
        [(-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)],  # back (+Z)
        [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, hz), (-hx, hy, hz)],  # slope
        [(-hx, -hy, -hz), (-hx, -hy, hz), (-hx, hy, hz)],
        [(hx, -hy, -hz), (hx, -hy, hz), (hx, hy, hz)],
    ]


def cylinder_faces(sx, sy, sz, segments=20):
    r = min(sy, sz) / 2
    hx = sx / 2
    ring = [(math.cos(2 * math.pi * i / segments) * r, math.sin(2 * math.pi * i / segments) * r)
            for i in range(segments)]
    faces = [[(-hx, a, b) for a, b in ring], [(hx, a, b) for a, b in ring]]
    for i in range(segments):
        a, b = ring[i], ring[(i + 1) % segments]
        faces.append([(-hx, a[0], a[1]), (hx, a[0], a[1]), (hx, b[0], b[1]), (-hx, b[0], b[1])])
    return faces


def ball_faces(sx, sy, sz, rings=8, segments=14):
    r = min(sx, sy, sz) / 2
    faces = []
    for i in range(rings):
        t0, t1 = math.pi * i / rings, math.pi * (i + 1) / rings
        for j in range(segments):
            p0, p1 = 2 * math.pi * j / segments, 2 * math.pi * (j + 1) / segments
            pts = [(t0, p0), (t0, p1), (t1, p1), (t1, p0)]
            faces.append([(r * math.sin(t) * math.cos(p), r * math.cos(t), r * math.sin(t) * math.sin(p))
                          for t, p in pts])
    return faces


def part_faces(part):
    sx, sy, sz = part["size"]
    if part["class"] == "WedgePart":
        local = wedge_faces(sx, sy, sz)
    elif part["shape"] == "Cylinder":
        local = cylinder_faces(sx, sy, sz)
    elif part["shape"] == "Ball":
        local = ball_faces(sx, sy, sz)
    else:
        local = box_faces(sx, sy, sz)
    cf = part["cframe"]
    # Flip normals outward from the shape's vertex centroid (the part center lies on a wedge's slope).
    vertices = {v for face in local for v in face}
    center = transform(cf, scale(tuple(map(sum, zip(*vertices))), 1 / len(vertices)))
    out = []
    for face in local:
        world = [transform(cf, p) for p in face]
        n = norm(cross(sub(world[1], world[0]), sub(world[2], world[0])))
        if n == (0.0, 0.0, 0.0) and len(world) > 3:
            n = norm(cross(sub(world[2], world[0]), sub(world[3], world[0])))
        fc = scale(tuple(map(sum, zip(*world))), 1 / len(world))
        if dot(n, sub(fc, center)) < 0:
            n = scale(n, -1)
        out.append((world, n))
    return out


def box_edges(cf, lo, hi):
    xs, ys, zs = (lo[0], hi[0]), (lo[1], hi[1]), (lo[2], hi[2])
    corners = {(i, j, k): transform(cf, (xs[i], ys[j], zs[k])) for i in (0, 1) for j in (0, 1) for k in (0, 1)}
    edges = []
    for (i, j, k), p in corners.items():
        for d in ((1, 0, 0), (0, 1, 0), (0, 0, 1)):
            q = (i + d[0], j + d[1], k + d[2])
            if q in corners:
                edges.append((p, corners[q]))
    return edges


def camera(direction):
    c = norm(direction)
    d = scale(c, -1)
    if abs(d[1]) > 0.999:
        right = (1.0, 0.0, 0.0)
        up = cross(right, d)
    else:
        right = norm(cross(d, (0.0, 1.0, 0.0)))
        up = cross(right, d)
    return right, up, d


def shade(part, n, d):
    r, g, b = part["color"]
    material = part["material"]
    alpha = 1.0 - part["transparency"]
    if material == "Neon":
        k = 1.25
        col = (min(1, r * k + 0.15), min(1, g * k + 0.15), min(1, b * k + 0.15))
    else:
        lam = max(0.0, dot(n, LIGHT))
        k = 0.42 + 0.58 * lam
        col = [r * k, g * k, b * k]
        if material in ("Metal", "DiamondPlate", "Foil", "Glass"):
            h = norm(add(LIGHT, scale(d, -1)))
            spec = max(0.0, dot(n, h)) ** 24 * 0.45
            col = [min(1, c + spec) for c in col]
        col = tuple(col)
        if material == "Glass" and part["transparency"] == 0:
            alpha = 0.85
    return tuple(int(c * 255) for c in col) + (int(alpha * 255),)


def render_view(data, key, w, h, overlay, focus):
    label, direction = VIEWS[key]
    right, up, d = camera(direction)
    W, H = w * SS, h * SS
    faces = []
    for part in data["parts"]:
        if part["transparency"] >= 0.999:
            continue
        for world, n in part_faces(part):
            if dot(n, d) > 1e-6:  # back face
                continue
            depth = sum(dot(p, d) for p in world) / len(world)
            faces.append((depth, world, n, part))

    weapon = data.get("kind") == "weapon"
    pts = [p for _, world, _, _ in faces for p in world]
    if weapon:
        pts += [(x, y, z) for lo, hi in (FIST, FOREARM) for x in (lo[0], hi[0]) for y in (lo[1], hi[1])
                for z in (lo[2], hi[2])]
    if data.get("footprint"):
        fw, fl = data["footprint"]
        pts += [(sx * fw / 2, y, sz * fl / 2) for sx in (-1, 1) for sz in (-1, 1) for y in (0, 1)]
    if not pts:
        pts = [(0, 0, 0)]
    if focus:
        fx, fy, fz, fr = focus
        cx, cy = dot((fx, fy, fz), right), dot((fx, fy, fz), up)
        span_x = span_y = 2 * fr
    else:
        xs = [dot(p, right) for p in pts]
        ys = [dot(p, up) for p in pts]
        cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        span_x, span_y = max(xs) - min(xs), max(ys) - min(ys)
    margin = 0.88
    s = min(W * margin / max(span_x, 1e-3), (H - 30 * SS) * margin / max(span_y, 1e-3))

    def project(p):
        return (W / 2 + (dot(p, right) - cx) * s, (H + 24 * SS) / 2 - (dot(p, up) - cy) * s)

    img = Image.new("RGBA", (W, H), (236, 238, 242, 255))
    draw = ImageDraw.Draw(img, "RGBA")

    # Ground grid: 1 meter (4 studs). Weapons float in the wielder's frame and get none.
    if not weapon and key not in ("top", "under") and abs(d[1]) < 0.999:
        gy = project((0, 0, 0))[1]
        if abs(d[1]) < 1e-6:
            draw.line([(0, gy), (W, gy)], fill=(120, 130, 140, 255), width=SS)
    extent = int(max(span_x, span_y) / 2 + 12)
    extent -= extent % 4
    if not weapon and key not in ("left", "right", "front", "rear"):
        for t in range(-extent, extent + 1, 4):
            for a, b in (((t, 0, -extent), (t, 0, extent)), ((-extent, 0, t), (extent, 0, t))):
                draw.line([project(a), project(b)], fill=(205, 210, 218, 255), width=SS)

    raster = Raster(W, H, (236, 238, 242), img)
    opaque = [f for f in faces if shade(f[3], f[2], d)[3] == 255]
    clear = sorted((f for f in faces if shade(f[3], f[2], d)[3] < 255), key=lambda f: -f[0])
    for group, write in ((opaque, True), (clear, False)):
        for _, world, n, part in group:
            fill = shade(part, n, d)
            poly = [project(p) + (dot(p, d),) for p in world]
            for i in range(1, len(poly) - 1):
                raster.triangle(poly[0], poly[i], poly[i + 1], fill, write)
    for _, world, n, part in opaque:
        fill = shade(part, n, d)
        edge = tuple(int(c * 0.5) for c in fill[:3])
        poly = [project(p) + (dot(p, d),) for p in world]
        # Outline flat faces; of a cylinder only its caps, of a ball nothing.
        if part["shape"] == "Ball" or (part["shape"] == "Cylinder" and len(poly) == 4):
            continue
        for i in range(len(poly)):
            raster.line(poly[i], poly[(i + 1) % len(poly)], edge, 0.08)
    img = raster.image()
    draw = ImageDraw.Draw(img, "RGBA")

    if overlay:
        lines = []
        if data.get("footprint"):
            fw, fl = data["footprint"]
            lines += [(e, (0, 170, 200, 255)) for e in box_edges((0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                                                                    (-fw / 2, 0, -fl / 2), (fw / 2, 1, fl / 2))]
        for box in data.get("collision", []):
            sx, sy, sz = box["size"]
            lines += [(e, (240, 140, 0, 255)) for e in box_edges(box["cframe"], (-sx / 2, -sy / 2, -sz / 2),
                                                                   (sx / 2, sy / 2, sz / 2))]
        for seat in data.get("seats", []):
            lines += [(e, (20, 170, 60, 255)) for e in box_edges(seat, (-1, -0.5, -1), (1, 0.5, 1))]
            top = list(seat)
            top_pos = transform(seat, (0, 0.5, 0))
            top[0], top[1], top[2] = top_pos
            for lo, hi in (AVATAR_BODY, AVATAR_LEGS):
                lines += [(e, (225, 30, 30, 255)) for e in box_edges(top, lo, hi)]
        labels = []
        if weapon:
            lines += [(e, (225, 30, 30, 255)) for e in box_edges(IDENTITY, *FIST)]
            lines += [(e, (240, 140, 0, 255)) for e in box_edges(IDENTITY, *FOREARM)]
            labels += [((0.3, 0.3, 0), "fist", (225, 30, 30, 255)),
                       ((0.3, 0.3, 2.75), "forearm (to wielder)", (220, 120, 0, 255))]
            if data.get("muzzle"):
                m = tuple(data["muzzle"])
                r = 0.25
                for axis in ((r, 0, 0), (0, r, 0), (0, 0, r)):
                    lines.append(((sub(m, axis), add(m, axis)), (210, 0, 210, 255)))
                labels.append((add(m, (0.3, 0.3, 0)), "muzzle", (190, 0, 190, 255)))
        for (a, b), color in lines:
            draw.line([project(a), project(b)], fill=color, width=SS)
        small = ImageFont.load_default(size=12 * SS)
        placed = []
        for p, text, color in labels:
            x, y = project(p)
            left, top, right_, bottom = draw.textbbox((0, 0), text, font=small)
            x = min(x + 3 * SS, W - (right_ - left) - 4 * SS)
            y -= 14 * SS
            box = (x, y, x + right_ - left, y + bottom - top)
            # Skip a label that would land on one already drawn (e.g. the forearm seen end-on).
            if any(box[0] < o[2] and o[0] < box[2] and box[1] < o[3] and o[1] < box[3] for o in placed):
                continue
            placed.append(box)
            draw.text((x, y), text, fill=color, font=small)

    font = ImageFont.load_default(size=14 * SS)
    draw.text((8 * SS, 6 * SS), f"{label}   {s / SS:.1f} px/stud", fill=(30, 30, 40, 255), font=font)
    return img.resize((w, h), Image.LANCZOS)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    parser.add_argument("out", nargs="?")
    parser.add_argument("--views", help="default: front34,rear34,left,front,top,rear for vehicles, "
                        "left,front,top,front34 for weapons")
    parser.add_argument("--weapon", action="store_true", help="render a weapon model file")
    parser.add_argument("--panel", default="640x420")
    parser.add_argument("--focus", help="x,y,z,radius in vehicle space")
    parser.add_argument("--no-overlay", action="store_true")
    args = parser.parse_args()

    command = ["lune", "run", EXPORT, args.file] + (["--weapon"] if args.weapon else [])
    result = subprocess.run(command, capture_output=True, text=True, cwd=ROOT)
    if result.returncode != 0:
        sys.stderr.write(result.stderr or result.stdout)
        sys.exit(1)
    data = json.loads(result.stdout)

    w, h = (int(v) for v in args.panel.split("x"))
    weapon = data.get("kind") == "weapon"
    views = args.views or ("left,front,top,front34" if weapon else "front34,rear34,left,front,top,rear")
    keys = [k.strip() for k in views.split(",") if k.strip()]
    for k in keys:
        if k not in VIEWS:
            sys.exit(f"unknown view {k}; choose from {', '.join(VIEWS)}")
    focus = tuple(float(v) for v in args.focus.split(",")) if args.focus else None
    cols = min(3, len(keys))
    rows = math.ceil(len(keys) / cols)
    header = 44
    sheet = Image.new("RGB", (cols * w, rows * h + header), (255, 255, 255))
    for i, k in enumerate(keys):
        panel = render_view(data, k, w, h, not args.no_overlay, focus)
        sheet.paste(panel, ((i % cols) * w, header + (i // cols) * h))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=16)
    if weapon:
        muzzle = data.get("muzzle")
        title = (f"{data.get('name')}  |  {len(data['parts']) - 1} pieces  |  hold {data.get('hold')}  |  "
                 f"muzzle {tuple(round(v, 2) for v in muzzle) if muzzle else 'default'}  |  "
                 "wielder frame: -Z forward, +Y up")
    else:
        fw, fl = data.get("footprint") or (0, 0)
        title = (f"{data.get('name')}  |  {len(data['parts'])} pieces  |  footprint {fw} x {fl} studs  |  "
                 f"speed {data.get('speed')}  |  seats {len(data['seats'])}")
    draw.text((10, 4), title, fill=(0, 0, 0), font=font)
    problems = data.get("problems") or []
    draw.text((10, 24), ("PROBLEMS: " + "; ".join(problems)) if problems else "no problems found",
              fill=(200, 0, 0) if problems else (0, 120, 0), font=ImageFont.load_default(size=13))

    out = args.out or os.path.splitext(os.path.basename(args.file))[0] + ".png"
    sheet.save(out)
    print(out)
    for p in problems:
        print("PROBLEM:", p)


if __name__ == "__main__":
    main()
