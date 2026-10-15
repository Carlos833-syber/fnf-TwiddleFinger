#!/usr/bin/env python3
"""Exercise FunkinLua's actual loading block against the Lua stack API contract."""

from pathlib import Path
import os
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class LuaScriptLoadingTest(unittest.TestCase):
    def test_success_and_error_paths(self):
        source = (REPO / "source/psychlua/FunkinLua.hx").read_text()
        marker = source.index("checkpoint('Executando arquivo Lua: '")
        start = source.rfind("\n\t\ttry", 0, marker)
        end = source.index("\n\t\ttrace('lua file loaded succesfully:'", marker)
        self.assertGreater(start, 0)
        block = source[start:end]
        with tempfile.TemporaryDirectory(prefix="twiddle-lua-test-") as temp:
            root = Path(temp)
            (root / "script.lua").write_text("function onEvent() end\n")
            (root / "Test.hx").write_text('''
import sys.FileSystem;
class Test {
    var lua:Null<Int> = 1;
    var scriptName:String;
    var loaded = false;
    var message:String;
    function new(script:String) { scriptName = script; }
    function luaTrace(text:String, force:Bool, debug:Bool, color:Int) {
        message = text;
    }
    function load() {
''' + block + '''
        loaded = true;
    }
    static function main() {
        var status = Std.parseInt(Sys.getEnv("LUA_STATUS"));
        var fromFile = Sys.getEnv("LUA_FILE") == "yes";
        var t = new Test(fromFile ? "script.lua" : "function onEvent() end");
        t.load();
        if (LuaL.usedFile != fromFile) throw "Wrong input path";
        if (status == 0) {
            if (!t.loaded || Lua.reads != 0 || Lua.closed) throw "Success was mishandled";
        } else {
            if (t.loaded || !Lua.closed || t.lua != null || Lua.reads != 1)
                throw "Error was mishandled";
            var expected = Sys.getEnv("LUA_NULL_ERROR") == "yes"
                ? "Lua script failed with status " + status : "top-of-stack error";
            if (t.message.indexOf(expected) < 0) throw "Lost error message";
        }
    }
}
class LuaL {
    public static var usedFile = false;
    public static function dofile(lua:Int, path:String):Int {
        usedFile = true; return Std.parseInt(Sys.getEnv("LUA_STATUS"));
    }
    public static function dostring(lua:Int, code:String):Int {
        return Std.parseInt(Sys.getEnv("LUA_STATUS"));
    }
}
class Lua {
    public static var reads = 0;
    public static var closed = false;
    public static function tostring(lua:Int, index:Int):String {
        // Enforce the native API contract, including an empty stack on success.
        if (Sys.getEnv("LUA_STATUS") == "0" || index != -1) Sys.exit(17);
        reads++;
        return Sys.getEnv("LUA_NULL_ERROR") == "yes" ? null : "top-of-stack error";
    }
    public static function close(lua:Int) { closed = true; }
}
class FlxColor { public static inline var RED = 0xff0000; }
''')
            for from_file in ("yes", "no"):
                for status, null_error in (("0", "no"), ("1", "no"), ("2", "no"), ("1", "yes")):
                    with self.subTest(file=from_file, status=status, null_error=null_error):
                        env = dict(os.environ, LUA_STATUS=status, LUA_FILE=from_file,
                                   LUA_NULL_ERROR=null_error)
                        result = subprocess.run(
                            ["haxe", "-cp", temp, "-main", "Test", "--interp"],
                            cwd=root, env=env, capture_output=True, text=True, timeout=30,
                        )
                        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
