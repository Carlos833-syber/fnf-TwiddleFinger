#!/usr/bin/env bash
set -euo pipefail

# Replace linc_luajit's legacy Android archive with a reproducible NDK build.
revision=2a8e017ef1ece6a95b983ffca073d30609dce7c4
checksum=54705d4b1de50a9c668539b9cf0dc3170d94ffdad51fafd1cf4477e498be7144
: "${ANDROID_NDK_ROOT:?Set ANDROID_NDK_ROOT to the repository-pinned NDK}"
ndkbin="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin"
test -x "$ndkbin/aarch64-linux-android23-clang"
library=$(haxelib path linc_luajit | sed -n '1p')
test -d "$library/lib/lua/lib/Android"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
curl --fail --location --retry 3 \
  "https://github.com/LuaJIT/LuaJIT/archive/$revision.tar.gz" -o "$work/source.tar.gz"
printf '%s  %s\n' "$checksum" "$work/source.tar.gz" | sha256sum --check
mkdir "$work/source"
tar -xzf "$work/source.tar.gz" --strip-components=1 -C "$work/source"
# Verify the shipped event with a host build from the identical source revision.
make -C "$work/source" -j2 BUILDMODE=static CC="gcc -B/usr/bin/" HOST_CC="gcc -B/usr/bin/"
"$work/source/src/luajit" tests/lua/infryzoom-smoke.lua
make -C "$work/source" clean
make -C "$work/source" -j2 BUILDMODE=static HOST_CC="gcc -B/usr/bin/" \
  CROSS="$ndkbin/aarch64-linux-android-" \
  STATIC_CC="$ndkbin/aarch64-linux-android23-clang" \
  DYNAMIC_CC="$ndkbin/aarch64-linux-android23-clang -fPIC" \
  TARGET_LD="$ndkbin/aarch64-linux-android23-clang" \
  TARGET_AR="$ndkbin/llvm-ar rcus" TARGET_STRIP="$ndkbin/llvm-strip" XCFLAGS=-fPIC
cp "$work/source/src/libluajit.a" "$library/lib/lua/lib/Android/libluajit-64.a"
# The binding includes these public headers; keep them aligned with the archive.
for header in lua.h lauxlib.h lualib.h luaconf.h luajit.h lua.hpp; do
  cp "$work/source/src/$header" "$library/lib/lua/src/$header"
done
printf 'Android ARM64 LuaJIT built from %s\n' "$revision"

# VLC exports another Lua ABI. Pull in every LuaJIT object and bind it locally.
python3 - "$library/linc/linc_lua.xml" <<'PYXML'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
marker = "--exclude-libs,libluajit-64.a"
if marker not in text:
    original = "<lib name='${LINC_LUA_PATH}/lib/lua/lib/Android/libluajit-64.a' if='HXCPP_ARM64' />"
    if text.count(original) != 1:
        raise SystemExit("Unexpected linc_luajit ARM64 link configuration")
    replacement = """<section if="HXCPP_ARM64">
                <lib name="-Wl,--whole-archive" />
                <lib name="${LINC_LUA_PATH}/lib/lua/lib/Android/libluajit-64.a" />
                <lib name="-Wl,--no-whole-archive" />
                <flag value="-Wl,--exclude-libs,libluajit-64.a" />
            </section>"""
    path.write_text(text.replace(original, replacement))
PYXML
