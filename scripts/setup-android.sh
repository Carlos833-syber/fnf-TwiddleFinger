#!/usr/bin/env bash
set -euo pipefail

# Keep this stack aligned with Project.xml; unpinned hmm.json is for legacy builds.
haxelib newrepo
for dependency in \
  'hxcpp 4.3.2' \
  'lime 8.1.3' \
  'openfl 9.3.3' \
  'flixel 5.8.0' \
  'flixel-addons 3.2.2' \
  'flixel-ui 2.6.1' \
  'tjson 1.4.0' \
  'SScript 7.7.0' \
  'hxvlc 1.5.4'; do
  read -r library version <<< "$dependency"
  haxelib install "$library" "$version" --always --skip-dependencies
done
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git daf0664aee99aa8b8d6bdd1eda993a1c3a399067 --always
haxelib git flxanimate https://github.com/ShadowMario/flxanimate.git 6d11b11f65f822a2a2ad01018fa8bcea0437bf5a --always
# SScript 7.7.0 otherwise prompts and exits during the first release compilation.
# Serialized settings disable version prompts; preserve existing local choices.
if [[ ! -f "$HOME/settings.cocoa" ]]; then
  printf '%s' 'oy9:showMacrofy8:loopCosti25y10:includeAllfg' > "$HOME/settings.cocoa"
fi
