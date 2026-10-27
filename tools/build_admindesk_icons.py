#!/usr/bin/env python3
"""Render Admin Desk platform icons from res/admindesk-logo.svg.

Usage (repository root): python3 tools/build_admindesk_icons.py
Dependencies: pillow>=10, cairosvg>=2.7
Only image assets are generated. No connection, server or FFI code is touched.
"""
from __future__ import annotations

import io
import json
from pathlib import Path
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "res/admindesk-logo.svg"
RES = ROOT / "res"
ANDROID = ROOT / "flutter/android/app/src/main/res"
IOS = ROOT / "flutter/ios/Runner/Assets.xcassets"

def png(svg: bytes, size: int) -> Image.Image:
    data = cairosvg.svg2png(bytestring=svg, output_width=size, output_height=size)
    return Image.open(io.BytesIO(data)).convert("RGBA")

def resize(im: Image.Image, n: int) -> Image.Image:
    return im.resize((n, n), Image.Resampling.LANCZOS)

def save(im: Image.Image, path: Path, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im = im.convert("RGBA")
    if opaque:
        base = Image.new("RGBA", im.size, (9, 112, 231, 255))
        base.alpha_composite(im)
        im = base.convert("RGB")
    im.save(path, optimize=True)

def ico(im: Image.Image, path: Path, sizes: tuple[int, ...]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, format="ICO", sizes=[(s, s) for s in sizes])

def main() -> None:
    raw = SOURCE.read_bytes()
    image = png(raw, 1024)
    for size, name in [
        (32, "32x32.png"), (64, "64x64.png"),
        (128, "128x128.png"), (256, "128x128@2x.png"),
        (1024, "icon.png"), (1024, "mac-icon.png")
    ]:
        save(resize(image, size), RES / name)
    ico(image, RES / "icon.ico", (16, 24, 32, 48, 64, 128, 256))
    ico(image, RES / "tray-icon.ico", (16, 24, 32, 48, 64))
    ico(image, ROOT / "flutter/windows/runner/resources/app_icon.ico",
        (16, 24, 32, 48, 64, 128, 256))
    save(resize(image, 512), ROOT / "flutter/assets/icon.png")
    macicon = ROOT / "flutter/macos/Runner/AppIcon.icns"
    macicon.parent.mkdir(parents=True, exist_ok=True)
    image.save(macicon, format="ICNS")
    root = ET.fromstring(raw)
    white_paths = [
        el.attrib["d"] for el in root.iter()
        if el.tag.endswith("path") and el.attrib.get("fill") == "white"
    ]
    if len(white_paths) != 1:
        raise ValueError("Expected one white AD monogram path")
    template = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="120 105 1010 1030">'
        '<path fill="black" d="' + white_paths[0] + '"/></svg>'
    ).encode()
    for name in ("mac-tray-dark-x2.png", "mac-tray-light-x2.png"):
        save(png(template, 44), RES / name)
    catalog = IOS / "AppIcon.appiconset"
    for entry in json.loads((catalog / "Contents.json").read_text())["images"]:
        name = entry.get("filename")
        if name:
            pt = float(entry["size"].split("x")[0])
            factor = int(entry["scale"].replace("x", ""))
            save(resize(image, round(pt * factor)), catalog / name, opaque=True)
    for n, name in [(1, "LaunchImage.png"), (2, "LaunchImage@2x.png"),
                    (3, "LaunchImage@3x.png")]:
        save(resize(image, 160 * n), IOS / "LaunchImage.imageset" / name)
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for density, factor in densities.items():
        folder = ANDROID / ("mipmap-" + density)
        icon_size = round(48 * factor)
        save(resize(image, icon_size), folder / "ic_launcher.png")
        save(resize(image, icon_size), folder / "ic_launcher_round.png")
        fg_size = round(72 * factor)
        fg = png(template.replace(b'fill="black"', b'fill="white"'), fg_size)
        canvas = Image.new("RGBA", (round(108 * factor),) * 2)
        margin = (canvas.width - fg.width) // 2
        canvas.alpha_composite(fg, (margin, margin))
        save(canvas, folder / "ic_launcher_foreground.png")
        stat = png(template.replace(b'fill="black"', b'fill="white"'),
                   round(24 * factor))
        save(stat, folder / "ic_stat_logo.png")
    save(resize(image, 192), ANDROID / "drawable-nodpi/admindesk_splash.png")
    print("Rendered Admin Desk icons for Windows, Mac, iOS, Android and Linux")

if __name__ == "__main__":
    main()
