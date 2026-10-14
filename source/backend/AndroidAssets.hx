package backend;

#if android
import haxe.Json;
import haxe.io.Path;
import lime.utils.Assets;
import sys.FileSystem;
import sys.io.File;

class AndroidAssets
{
	/** Keep native file access inside app-private storage; no storage permission needed. */
	public static function prepare():Void
	{
		// SDL resolves packaged asset IDs relative to the storage root before the APK.
		// Extract below that root so a previous installation cannot shadow new assets.
		var directory = Path.join([lime.system.System.applicationStorageDirectory, 'game-content']);
		FileSystem.createDirectory(directory);
		Sys.setCwd(directory);

		var entries:Array<{id:String, hash:String, size:Int}> = AndroidAssetManifest.build();
		var manifest = Json.stringify(entries);
		var marker = '.bundled-assets.json';
		var current = FileSystem.exists(marker) && File.getContent(marker) == manifest;
		for (entry in entries)
		{
			if (current && FileSystem.exists(entry.id))
				continue;
			// Lime's native file loader returns null for an empty file.
			var bytes = entry.size == 0 ? haxe.io.Bytes.alloc(0) : Assets.getBytes(entry.id);
			if (bytes == null)
				throw 'Missing packaged Android asset: ' + entry.id;
			FileSystem.createDirectory(Path.directory(entry.id));
			// Write then rename so an interrupted first launch can safely retry.
			var temporary = entry.id + '.installing';
			File.saveBytes(temporary, bytes);
			FileSystem.rename(temporary, entry.id);
		}
		// Mark complete only after all packaged files were installed successfully.
		File.saveContent(marker, manifest);
	}
}
#end
