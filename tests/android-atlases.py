#!/usr/bin/env python3
"""Check texture limits and lossless frames, including rotated/aliased frames."""

import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest
import xml.etree.ElementTree as ET

from PIL import Image


REPO = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("android_atlases", REPO / "scripts/prepare-android-assets.py")
packer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packer)


def crop(image, frame):
    x, y, w, h = (int(frame.get(k)) for k in ("x", "y", "width", "height"))
    return image.crop((x, y, x + w, y + h)).tobytes()


class AtlasTest(unittest.TestCase):
    def verify_frames(self, original, packed, limit):
        manifest = json.loads(packed.with_suffix(".pages.json").read_text())
        old_frames = list(ET.parse(original.with_suffix(".xml")).getroot())
        self.assertEqual(manifest["frames"], [f.get("name") for f in old_frames])
        frames = {}
        for page in manifest["pages"]:
            with Image.open(packed.with_name(page + ".png")) as image:
                self.assertLessEqual(max(image.size), limit)
                for frame in ET.parse(packed.with_name(page + ".xml")).getroot():
                    x, y, w, h = (int(frame.get(k)) for k in ("x", "y", "width", "height"))
                    self.assertGreaterEqual(min(x, y), 0)
                    self.assertLessEqual(x + w, image.width)
                    self.assertLessEqual(y + h, image.height)
                    self.assertNotIn(frame.get("name"), frames)
                    frames[frame.get("name")] = (frame, crop(image.convert("RGBA"), frame))
        self.assertEqual(len(frames), len(old_frames))
        with Image.open(original) as source:
            source = source.convert("RGBA")
            for old in old_frames:
                new, pixels = frames[old.get("name")]
                self.assertEqual({k: v for k, v in old.attrib.items() if k not in ("x", "y")},
                                 {k: v for k, v in new.attrib.items() if k not in ("x", "y")})
                self.assertEqual(crop(source, old), pixels, old.get("name"))

    def test_rotated_alias_and_multiple_pages(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = root / "original.png"
            image = Image.new("RGBA", (12, 6), "red")
            image.paste(Image.new("RGBA", (6, 6), "blue"), (6, 0))
            image.putpixel((1, 2), (1, 2, 3, 4))
            image.save(original)
            original.with_suffix(".xml").write_text('''<TextureAtlas>
              <SubTexture name="idle0" x="0" y="0" width="6" height="6" frameX="-2" frameY="-1" frameWidth="9" frameHeight="8"/>
              <SubTexture name="idle1" x="6" y="0" width="6" height="6" rotated="true"/>
              <SubTexture name="idle2" x="0" y="0" width="6" height="6" frameX="-3" frameY="0" frameWidth="10" frameHeight="6"/>
            </TextureAtlas>''')
            packed = root / "packed.png"
            shutil.copyfile(original, packed)
            shutil.copyfile(original.with_suffix(".xml"), packed.with_suffix(".xml"))
            self.assertEqual(packer.repack(packed, limit=8), 2)
            self.verify_frames(original, packed, 8)

    def test_mod_atlases_fit_without_changing_pixels(self):
        with tempfile.TemporaryDirectory() as directory:
            packed = Path(directory) / "mods"
            packer.prepare(REPO / "example_mods", packed)
            self.assertFalse((packed / "modTemplate.zip").exists())
            manifests = list(packed.rglob("*.pages.json"))
            self.assertEqual(len(manifests), 5)
            for manifest in manifests:
                path = manifest.with_name(manifest.name.replace(".pages.json", ".png"))
                original = REPO / "example_mods" / path.relative_to(packed)
                self.verify_frames(original, path, packer.LIMIT)
                self.assertFalse(path.exists())
            for path in packed.rglob("*.png"):
                with Image.open(path) as image:
                    self.assertLessEqual(max(image.size), packer.LIMIT)


if __name__ == "__main__":
    unittest.main()
