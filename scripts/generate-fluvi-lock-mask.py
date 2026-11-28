#!/usr/bin/env python3
"""Render the native lockscreen mask from the canonical Fluvi mark.

Regenerate with Inkscape and the Python svgpathtools package installed.
The committed drawable is used directly by the Android build.
"""
import argparse
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
from xml.etree import ElementTree as ET

from svgpathtools import parse_path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/fluvi/brand/fluvi_mark.svg"
DRAWABLE = ROOT / "android/wa-lockscreen/src/main/res/drawable-nodpi/wa_fluvi_logo_mask.png"
SVG = "{http://www.w3.org/2000/svg}"
DIAMETER = 640


def artwork():
    source_paths = ET.parse(SOURCE).getroot().findall(SVG + "path")
    paths = [element.attrib["d"] for element in source_paths]
    if len(paths) != 4 or any("transform" in element.attrib for element in source_paths):
        raise ValueError("The canonical mark must provide four paths in the same coordinate space.")
    bounds = [parse_path(path).bbox() for path in paths]
    left = min(item[0] for item in bounds)
    right = max(item[1] for item in bounds)
    top = min(item[2] for item in bounds)
    bottom = max(item[3] for item in bounds)
    middle_x, middle_y = (left + right) / 2, (top + bottom) / 2
    scale = 600 / (bottom - top)
    # Painting every path black in the luminance mask computes their union.
    # Overlapping paint must not toggle a hole closed.
    strokes = "\n".join(f'<path d="{path}"/>' for path in paths)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{DIAMETER}" height="{DIAMETER}" viewBox="0 0 1000 1000">
      <defs>
        <mask id="mark" maskUnits="userSpaceOnUse" x="0" y="0" width="1000" height="1000">
          <rect width="1000" height="1000" fill="white"/>
          <g fill="black" transform="translate(500 500) scale({scale:.12f}) translate({-middle_x:.12f} {-middle_y:.12f})">
            {strokes}
          </g>
        </mask>
      </defs>
      <circle cx="500" cy="500" r="500" fill="#F0F0F0" mask="url(#mark)"/>
    </svg>'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify the committed drawable.")
    args = parser.parse_args()
    with TemporaryDirectory(prefix="fluvi-lock-mask-") as temp:
        directory = Path(temp)
        svg = directory / "mask.svg"
        png = directory / "mask.png"
        svg.write_text(artwork(), encoding="utf-8")
        env = dict(os.environ, XDG_CONFIG_HOME=str(directory / "config"))
        subprocess.run(["inkscape", str(svg), "--export-type=png", f"--export-filename={png}"],
                       env=env, check=True)
        pixels = png.read_bytes()
        if args.check:
            if pixels != DRAWABLE.read_bytes():
                raise SystemExit("The native drawable differs from the canonical mark.")
        else:
            DRAWABLE.parent.mkdir(parents=True, exist_ok=True)
            DRAWABLE.write_bytes(pixels)


if __name__ == "__main__":
    main()
