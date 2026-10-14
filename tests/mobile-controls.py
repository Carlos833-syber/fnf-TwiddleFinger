#!/usr/bin/env python3
"""Test actual MobileControls input transitions against minimal Flixel stubs.

Run: python3 tests/mobile-controls.py (Haxe must be on PATH).
This verifies input state logic, not Android event delivery or rendering.
"""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class MobileControlsTest(unittest.TestCase):
    def test_multitouch_and_menu_transitions(self):
        with tempfile.TemporaryDirectory(prefix="twiddle-touch-") as directory:
            root = Path(directory)
            shutil.copytree(REPO / "tests/mobile-controls", root, dirs_exist_ok=True)
            (root / "backend").mkdir()
            shutil.copyfile(
                REPO / "source/backend/MobileControls.hx",
                root / "backend/MobileControls.hx",
            )
            result = subprocess.run(
                ["haxe", "-cp", str(root), "-D", "android", "-main", "Test", "--interp"],
                cwd=root, capture_output=True, text=True, timeout=60,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("PASS:", result.stdout)


if __name__ == "__main__":
    unittest.main()
