package flixel.graphics.frames;

class FlxTileFrames
{
	public static function fromFrame(frame:Dynamic, size:Dynamic):Dynamic
		return {width: size.x, height: size.y};
}
