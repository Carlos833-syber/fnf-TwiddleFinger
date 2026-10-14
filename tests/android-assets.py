#!/usr/bin/env python3
"""Exercise real Android extraction code with tiny packaged-asset fixtures.

Run: python3 tests/android-assets.py (Haxe 4.3.4 must be on PATH).
No Android SDK, Lime installation, or repository assets are modified.
"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class AndroidAssetsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="twiddle-assets-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.storage = self.root / "private/game-content"
        for name in ("AndroidAssets.hx", "AndroidAssetManifest.hx"):
            target = self.root / "source/backend" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO / "source/backend" / name, target)
        self.write("source/lime/system/System.hx", """
package lime.system;
class System {
    public static var applicationStorageDirectory:String = Sys.getEnv('TEST_STORAGE');
}
""")
        self.write("source/lime/utils/Assets.hx", """
package lime.utils;
class Assets {
    public static function getBytes(id:String):haxe.io.Bytes {
        if (id == Sys.getEnv('TEST_MISSING')) return null;
        var path = StringTools.startsWith(id, 'mods/')
            ? 'example_mods/' + id.substr(5) : id;
        var bytes = sys.io.File.getBytes(Sys.getEnv('TEST_PACKAGE') + '/' + path);
        return bytes.length == 0 ? null : bytes;
    }
}
""")
        self.write("source/Test.hx", """
class Test {
    public static function main():Void backend.AndroidAssets.prepare();
}
""")
        self.write("example_mods/stages/test.hx", "stage-v1")
        self.write("example_mods/images/test.png", "image-bytes")
        self.write("example_mods/template.zip", "not-installed")
        self.write("assets/videos/test.mp4", "video-bytes")
        self.write("assets/shared/data/test.json", '{"v":1}')
        self.write("assets/shared/data/empty.txt", "")
        self.write("assets/shared/images/base.png", "managed-by-lime")

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def extract(self, missing="", success=True):
        env = dict(os.environ, TEST_STORAGE=str(self.storage.parent),
                   TEST_PACKAGE=str(self.root), TEST_MISSING=missing)
        result = subprocess.run(
            ["haxe", "-cp", "source", "-main", "Test", "--interp", "-D", "android"],
            cwd=self.root, env=env, capture_output=True, text=True, timeout=60,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Missing packaged Android asset", result.stderr)

    def test_install_keep_existing_repair_and_update(self):
        self.extract()
        expected = {
            "mods/stages/test.hx": "stage-v1",
            "mods/images/test.png": "image-bytes",
            "assets/videos/test.mp4": "video-bytes",
            "assets/shared/data/test.json": '{"v":1}',
            "assets/shared/data/empty.txt": "",
        }
        for path, content in expected.items():
            self.assertEqual((self.storage / path).read_text(), content)
        self.assertFalse((self.storage / "mods/template.zip").exists())
        self.assertFalse((self.storage / "assets/shared/images/base.png").exists())
        marker = self.storage / ".bundled-assets.json"
        old_manifest = marker.read_text()

        # A matching version preserves already-installed files and repairs omissions.
        script = self.storage / "mods/stages/test.hx"
        script.write_text("local edit")
        (self.storage / "assets/videos/test.mp4").unlink()
        self.extract()
        self.assertEqual(script.read_text(), "local edit")
        self.assertEqual((self.storage / "assets/videos/test.mp4").read_text(), "video-bytes")

        # Recompile the manifest to simulate installing a new APK of equal file sizes.
        self.write("example_mods/stages/test.hx", "stage-v2")
        self.extract()
        self.assertEqual(script.read_text(), "stage-v2")
        self.assertNotEqual(marker.read_text(), old_manifest)
        self.assertFalse(list(self.storage.rglob("*.installing")))

    def test_interrupted_install_retries_before_recording_success(self):
        self.extract(missing="assets/videos/test.mp4", success=False)
        self.assertFalse((self.storage / ".bundled-assets.json").exists())
        self.assertTrue((self.storage / "mods/stages/test.hx").exists())
        self.extract()
        self.assertTrue((self.storage / ".bundled-assets.json").exists())
        self.assertEqual((self.storage / "assets/videos/test.mp4").read_text(), "video-bytes")


if __name__ == "__main__":
    unittest.main()
