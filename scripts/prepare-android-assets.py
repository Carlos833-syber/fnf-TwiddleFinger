#!/usr/bin/env python3
"""Repack oversized Sparrow atlases for Android without resizing any frames.

Requires Pillow. Desktop assets remain untouched; Lime packages export/android-mods.
"""

from copy import deepcopy
import json
from pathlib import Path
import shutil
import xml.etree.ElementTree as ET

from PIL import Image


LIMIT = 4096
PADDING = 2
REPO = Path(__file__).resolve().parents[1]


def repack(path, limit=LIMIT):
    tree = ET.parse(path.with_suffix(".xml"))
    frames = list(tree.getroot())
    # Repeated animation frames share pixels, but keep their individual names/offsets.
    rectangles = {}
    for frame in frames:
        rect = tuple(int(frame.get(k)) for k in ("x", "y", "width", "height"))
        rectangles.setdefault(rect, []).append(frame)
    def pack(page_width):
        pages = []
        for rect, aliases in sorted(rectangles.items(), key=lambda item: -item[0][3]):
            _, _, width, height = rect
            if min(width, height) <= 0 or max(width, height) > limit:
                raise ValueError(f"Frame cannot fit {limit}px texture: {path}: {aliases[0].get('name')}")
            placement = None
            for page in pages:
                for shelf in page["shelves"]:
                    if height <= shelf["height"] and shelf["x"] + width <= page_width:
                        placement = page, shelf
                        break
                if placement:
                    break
                if page["bottom"] + height <= limit:
                    shelf = {"x": 0, "y": page["bottom"], "height": height}
                    page["shelves"].append(shelf)
                    placement = page, shelf
                    break
            if placement is None:
                page = {"shelves": [], "bottom": 0, "width": 0, "height": 0, "items": []}
                pages.append(page)
                shelf = {"x": 0, "y": 0, "height": height}
                page["shelves"].append(shelf)
                placement = page, shelf
            page, shelf = placement
            x, y = shelf["x"], shelf["y"]
            page["items"].append((rect, aliases, x, y))
            shelf["x"] += width + PADDING
            page["width"] = max(page["width"], x + width)
            page["height"] = max(page["height"], y + height)
            page["bottom"] = max(page["bottom"], y + shelf["height"] + PADDING)
        return pages

    widths = {limit, max(rect[2] for rect in rectangles), limit // 2, 3 * limit // 4}
    candidates = [pack(width) for width in sorted(widths) if width >= max(rect[2] for rect in rectangles)]
    # Sparse scenic atlases are often cheaper as separate frames. Penalize extra
    # pages lightly to retain batching when its memory cost is small.
    candidates.append([
        {"width": rect[2], "height": rect[3], "items": [(rect, aliases, 0, 0)]}
        for rect, aliases in rectangles.items()
    ])
    pages = min(candidates, key=lambda pages: sum(p["width"] * p["height"] for p in pages) + len(pages) * 262144)
    with Image.open(path) as source:
        source = source.convert("RGBA")
        for index, page in enumerate(pages):
            name = f"{path.stem}__page{index}"
            image = Image.new("RGBA", (page["width"], page["height"]))
            atlas = ET.Element("TextureAtlas", imagePath=name + ".png")
            mapped = {}
            for (sx, sy, width, height), aliases, x, y in page["items"]:
                image.paste(source.crop((sx, sy, sx + width, sy + height)), (x, y))
                for frame in aliases:
                    copy = deepcopy(frame)
                    copy.set("x", str(x))
                    copy.set("y", str(y))
                    mapped[frame.get("name")] = copy
            for frame in frames:
                if frame.get("name") in mapped:
                    atlas.append(mapped[frame.get("name")])
            image.save(path.with_name(name + ".png"))
            ET.ElementTree(atlas).write(path.with_name(name + ".xml"), encoding="utf-8", xml_declaration=True)
    path.with_suffix(".pages.json").write_text(json.dumps({
        "pages": [f"{path.stem}__page{i}" for i in range(len(pages))],
        "frames": [frame.get("name") for frame in frames],
    }), encoding="utf-8")
    path.unlink()
    path.with_suffix(".xml").unlink()
    return len(pages)


def prepare(source, destination):
    shutil.copytree(source, destination, ignore=shutil.ignore_patterns("*.zip"))
    for path in sorted(destination.rglob("*.png")):
        with Image.open(path) as image:
            oversized = max(image.size) > LIMIT
        if oversized:
            if not path.with_suffix(".xml").exists():
                raise ValueError(f"Oversized image has no Sparrow atlas: {path}")
            count = repack(path)
            print(f"Android atlas: {path.relative_to(destination)} -> {count} page(s) <= {LIMIT}px")


def main():
    destination = REPO / "export/android-mods"
    temporary = REPO / "export/android-mods-preparing"
    if temporary.exists():
        shutil.rmtree(temporary)
    try:
        prepare(REPO / "example_mods", temporary)
        if destination.exists():
            shutil.rmtree(destination)
        temporary.rename(destination)
        # Lime's incremental copy does not remove assets deleted from its input.
        # Clear only its generated mod asset folders before the next build.
        for mode in ("release", "debug"):
            cached = REPO / f"export/{mode}/android/bin/app/src/main/assets/mods"
            if cached.exists():
                shutil.rmtree(cached)
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)


if __name__ == "__main__":
    main()
