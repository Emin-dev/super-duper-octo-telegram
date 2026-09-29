#!/usr/bin/env python3
"""
Extract SF Symbols as clean, Figma-ready SVG path data.

Requires: SF Symbols.app installed (free from Apple), and svgelements.
    python3 -m venv venv && venv/bin/pip install svgelements

Usage:
    venv/bin/python tools/sfsymbols.py car.fill house.fill bolt.fill
    venv/bin/python tools/sfsymbols.py --file symbols.txt

Emits compact JSON {name: {vb, d[]}} to stdout, ready to paste into a
`use_figma` call and feed to figma.createNodeFromSvg().

Why this exists: SF Pro does NOT render in the Figma MCP environment, so SF
Symbols cannot be created as font glyphs. Exporting them as VECTORS removes the
font dependency entirely.
"""
import re, subprocess, sys, os, json, tempfile
from svgelements import Path

CLI = "/Applications/SF Symbols.app/Contents/Executables/sfsymbols"

def round_nums(s, nd=1):
    def r(m):
        v = round(float(m.group(0)), nd)
        return str(int(v)) if v == int(v) else ("%.*f" % (nd, v)).rstrip('0').rstrip('.')
    return re.sub(r'-?\d+\.?\d*', r, s)

def extract(name, weight="regular"):
    if not os.path.exists(CLI):
        return None, "SF Symbols.app not installed"
    tmp = os.path.join(tempfile.gettempdir(), "sf_%s.svg" % name.replace('.', '_'))
    r = subprocess.run([CLI, "export", name, "--format", "svg",
                        "--weight", weight, "--output", tmp],
                       capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(tmp):
        return None, (r.stderr or r.stdout).strip()[:140]
    s = open(tmp).read()
    os.unlink(tmp)

    # The export is Apple's DESIGN TEMPLATE (3300x2200, every weight/scale,
    # guides and notes). Regular-S is the single clean variant we want.
    m = re.search(r'<g id="Regular-S"[^>]*>(.*?)</g>', s, re.S)
    if not m:
        return None, "no Regular-S group"
    ds = re.findall(r'\sd="([^"]+)"', m.group(1))
    if not ds:
        return None, "no path data"

    xs, ys = [], []
    for d in ds:
        bb = Path(d).bbox()
        if bb:
            xs += [bb[0], bb[2]]; ys += [bb[1], bb[3]]
    if not xs:
        return None, "no bbox"
    x0, y0 = min(xs), min(ys)
    w, h = max(xs) - x0, max(ys) - y0
    return {"vb": round_nums("%.2f %.2f %.2f %.2f" % (x0, y0, w, h)),
            "d": [round_nums(d) for d in ds]}, None

if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--file":
        names = [l.strip() for l in open(args[1]) if l.strip() and not l.startswith('#')]
    else:
        names = args
    out, errs = {}, []
    for n in names:
        spec, err = extract(n)
        if err: errs.append("%s :: %s" % (n, err))
        else: out[n] = spec
    if errs:
        sys.stderr.write("FAILED:\n  " + "\n  ".join(errs) + "\n")
    sys.stderr.write("extracted %d/%d\n" % (len(out), len(names)))
    print(json.dumps(out, separators=(',', ':')))

