package flixel.group;

class FlxGroup
{
	public var members:Array<flixel.FlxBasic> = [];

	public function new()
	{
	}

	public function add(v:flixel.FlxBasic)
		members.push(v);

	public function clear()
		members = [];

	public function destroy()
	{
	}

	public function draw()
	{
	}
}
