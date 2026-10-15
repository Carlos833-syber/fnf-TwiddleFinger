class Pair
{
	public function new()
	{
	}

	public function set()
	{
	}
}

class FlxCamera
{
	public var bgColor:Int;

	public function new()
	{
	}
}

enum abstract Align(String)
{
	var CENTER = 'center';
}

class FlxSprite extends flixel.FlxBasic
{
	public static var instances:Array<FlxSprite> = [];

	public var antialiasing:Bool;
	public var frames(default, set):Dynamic;
	public var animation = new Animation();

	function set_frames(value:Dynamic):Dynamic
	{
		width = value.width;
		height = value.height;
		return frames = value;
	}

	public var x:Float;
	public var y:Float;
	public var width:Int;
	public var height:Int;
	public var alpha:Float;
	public var scrollFactor = new Pair();
	public var cameras:Array<FlxCamera>;

	public function new(x:Float = 0, y:Float = 0)
	{
		super();
		this.x = x;
		this.y = y;
		instances.push(this);
	}

	public function loadGraphic(value:Dynamic):FlxSprite
	{
		width = value.width;
		height = value.height;
		return this;
	}

	public function setGraphicSize(w:Int, h:Int):Void
	{
		width = w;
		height = h;
	}

	public function updateHitbox():Void
	{
	}

	public function makeGraphic(w:Int, h:Int, c:Int)
	{
		width = w;
		height = h;
		return this;
	}
}

class Animation
{
	public function new()
	{
	}

	public function add(name:String, frames:Array<Int>):Void
	{
	}

	public function play(name:String):Void
	{
	}
}

class Paths
{
	public static function getSparrowAtlas(name:String):Dynamic
		return {getByName: (name:String) -> {width: 320, height: 720}};

	public static function getPackerAtlas(name:String):Dynamic
		return {getByName: (name:String) -> {width: 396, height: 135}};

	public static function image(name:String):Dynamic
		return {width: 1280, height: 720};
}

class ClientPrefs
{
	public static var data = {showHitboxes: true, antialiasing: true};
}

class FlxText extends FlxSprite
{
	public var alignment:Align;

	public function new(x:Float, y:Float, w:Float, t:String, s:Int)
	{
		super(x, y);
	}
}

class Manager
{
	public function new()
	{
	}

	public function add(v:Dynamic, b:Bool = false)
	{
	}

	public function remove(v:Dynamic)
	{
	}
}

class PlayState
{
	public var paused = false;
	public var isDead = false;

	public function new()
	{
	}
}

class Touch
{
	public var touchPointID:Int;
	public var pressed = true;
	public var justPressed = true;
	public var x:Float;
	public var y:Float;

	public function new(id:Int, x:Float, y:Float)
	{
		touchPointID = id;
		this.x = x;
		this.y = y;
	}

	public function overlaps(b:FlxSprite, c:FlxCamera)
		return x >= b.x && x < b.x + b.width && y >= b.y && y < b.y + b.height;
}

class FlxG
{
	public static var width = 1280;
	public static var height = 720;
	public static var state:Dynamic;
	public static var cameras = new Manager();
	public static var plugins = new Manager();
	public static var touches = {list: new Array<Touch>()};
}
