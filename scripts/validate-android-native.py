#!/usr/bin/env python3
"""Reject ARM64 APKs that reference unavailable HXCPP symbols or Lua imports from other libraries."""

import argparse
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile


def validate(apk, nm):
    with zipfile.ZipFile(apk) as archive, tempfile.TemporaryDirectory() as temp:
        library = Path(temp) / "libApplicationMain.so"
        data = archive.read("lib/arm64-v8a/libApplicationMain.so")
        if data[:5] != b"\x7fELF\x02" or int.from_bytes(data[18:20], "little") != 183:
            raise SystemExit("Application library must be a 64-bit ARM ELF")
        library.write_bytes(data)
        result = subprocess.run(
            [nm, "--dynamic", "--undefined-only", "--demangle", str(library)],
            check=True, capture_output=True, text=True,
        )
        unresolved = [
            line.strip() for line in result.stdout.splitlines()
            if "hx::" in line or "__hxcpp_" in line
            or re.search(r"\b(lua\w*|lj_\w*)\b", line)
        ]
        if unresolved:
            raise SystemExit("Unresolved HXCPP or unbound Lua runtime symbols:\n" + "\n".join(unresolved))
    print("ARM64 native library: HXCPP resolved and Lua runtime bound locally")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--nm", required=True)
    args = parser.parse_args()
    validate(args.apk, args.nm)
