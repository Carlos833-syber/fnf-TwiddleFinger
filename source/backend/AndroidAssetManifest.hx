package backend;

/** Build-time inventory of files that native mod/script/video loaders need on disk. */
class AndroidAssetManifest
{
	public static macro function build():haxe.macro.Expr
	{
		// Haxe's interpreted SHA-256 takes minutes for the video bundle. Use the
		// host utility on Linux builders, retaining a portable fallback elsewhere.
		function digest(path:String):String
		{
			if (Sys.systemName() == 'Linux')
			{
				var process:sys.io.Process = null;
				try
				{
					process = new sys.io.Process('sha256sum', ['--', path]);
					var output = process.stdout.readAll().toString();
					var success = process.exitCode() == 0;
					process.close();
					process = null;
					if (success && ~/^[0-9a-f]{64}  /.match(output))
						return output.substr(0, 64);
				}
				catch (_:Dynamic)
				{
					if (process != null)
						process.close();
				}
			}
			return haxe.crypto.Sha256.make(sys.io.File.getBytes(path)).toHex();
		}

		var entries:Array<{id:String, hash:String, size:Int}> = [];
		function visit(directory:String, target:String, all:Bool):Void
		{
			var names = sys.FileSystem.readDirectory(directory);
			names.sort(Reflect.compare);
			for (name in names)
			{
				var source = directory + '/' + name;
				var id = target + '/' + name;
				if (sys.FileSystem.isDirectory(source))
					visit(source, id, all);
				else if (all || ['json', 'txt', 'hx', 'lua', 'frag', 'vert'].indexOf(haxe.io.Path.extension(name)) != -1)
				{
					if (haxe.io.Path.extension(name) == 'zip')
						continue;
					entries.push({id: id, hash: digest(source), size: sys.FileSystem.stat(source).size});
				}
			}
		}
		visit('example_mods', 'mods', true);
		visit('assets/videos', 'assets/videos', true);
		visit('assets/shared', 'assets/shared', false);
		return haxe.macro.Context.makeExpr(entries, haxe.macro.Context.currentPos());
	}
}
