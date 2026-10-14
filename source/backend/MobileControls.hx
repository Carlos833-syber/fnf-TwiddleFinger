package backend;

#if android
import flixel.group.FlxGroup;
import flixel.FlxBasic;

/** Touch input sampled before states update, including paused substates. */
class MobileControls extends FlxBasic
{
	public static var current:MobileControls;

	var controlCamera:FlxCamera;
	var sprites:FlxGroup;
	var buttons:Array<FlxSprite> = [];
	var actions:Array<String> = [];
	var held:Map<String, Bool> = [];
	var previous:Map<String, Bool> = [];
	var fingers:Map<Int, String> = [];
	var gameplay:Bool = false;
	var initialized:Bool = false;

	public function new()
	{
		super();
		visible = false; // State draws the overlay last, above paused substates.
		current = this;
		controlCamera = new FlxCamera();
		controlCamera.bgColor = 0;
		FlxG.cameras.add(controlCamera, false);
		sprites = new FlxGroup();
		FlxG.plugins.add(this);
	}

	function layout(isGame:Bool)
	{
		for (sprite in sprites.members)
			if (sprite != null)
				sprite.destroy();
		sprites.clear();
		buttons = [];
		actions = [];
		// A finger already down must not activate a different screen's button.
		fingers.clear();
		held.clear();
		previous.clear();
		gameplay = isGame;
		initialized = true;
		var names = isGame ? ['LEFT', 'DOWN', 'UP', 'RIGHT'] : ['LEFT', 'DOWN', 'UP', 'RIGHT', 'OK', 'BACK'];
		var keys = isGame ? ['note_left', 'note_down', 'note_up', 'note_right'] : ['ui_left', 'ui_down', 'ui_up', 'ui_right', 'accept', 'back'];
		var width = FlxG.width / names.length;
		for (i in 0...names.length)
			addButton(i * width + 4, FlxG.height - 112, width - 8, 108, names[i], keys[i]);
		if (isGame)
			addButton(FlxG.width - 144, 8, 136, 64, 'PAUSE', 'pause');
	}

	function addButton(x:Float, y:Float, width:Float, height:Int, label:String, action:String)
	{
		var button = new FlxSprite(x, y).makeGraphic(Std.int(width), height, 0xFF202030);
		button.alpha = 0.55;
		button.scrollFactor.set();
		button.cameras = [controlCamera];
		sprites.add(button);
		buttons.push(button);
		actions.push(action);
		var text = new FlxText(x, y + (height - 28) / 2, width, label, 22);
		text.alignment = CENTER;
		text.scrollFactor.set();
		text.cameras = [controlCamera];
		sprites.add(text);
	}

	override public function update(elapsed:Float):Void
	{
		var play:PlayState = Std.isOfType(FlxG.state, PlayState) ? cast FlxG.state : null;
		var isGame = play != null && !play.paused && !play.isDead;
		if (!initialized || gameplay != isGame)
			layout(isGame);
		previous = held;
		held = [];
		var active:Map<Int, String> = [];
		for (touch in FlxG.touches.list)
		{
			if (!touch.pressed)
				continue;
			var action = fingers.get(touch.touchPointID);
			if (action == null && touch.justPressed)
			{
				for (i in 0...buttons.length)
					if (touch.overlaps(buttons[i], controlCamera))
					{
						action = actions[i];
						break;
					}
			}
			if (action != null)
			{
				active.set(touch.touchPointID, action);
				held.set(action, true);
			}
		}
		fingers = active;
		for (i in 0...buttons.length)
			buttons[i].alpha = held.exists(actions[i]) ? 0.85 : 0.55;
	}

	public static function pressed(key:String):Bool
		return current != null && current.held.exists(key);

	public static function justPressed(key:String):Bool
		return pressed(key) && !current.previous.exists(key);

	public static function justReleased(key:String):Bool
		return current != null && current.previous.exists(key) && !pressed(key);

	public function drawOverlay()
		sprites.draw();

	override public function destroy():Void
	{
		FlxG.plugins.remove(this);
		sprites.destroy();
		if (current == this)
			current = null;
		super.destroy();
	}
}
#end
