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
	public var x:Float;
	public var y:Float;
	public var width:Int;
	public var height:Int;
	public var alpha:Float;
	public var scrollFactor = new Pair();
	public var cameras:Array<FlxCamera>;

	public function new(x:Float, y:Float)
	{
		super();
		this.x = x;
		this.y = y;
	}

	public function makeGraphic(w:Int, h:Int, c:Int)
	{
		width = w;
		height = h;
		return this;
	}
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
