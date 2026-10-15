package backend;

#if android
import flixel.group.FlxGroup;
import flixel.FlxBasic;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;

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
	var hint:FlxSprite;
	var blockedFingers:Map<Int, Bool> = [];

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
		blockedFingers.clear();
		for (touch in FlxG.touches.list)
			if (touch.pressed && !touch.justPressed)
				blockedFingers.set(touch.touchPointID, true);
		hint = null;
		gameplay = isGame;
		initialized = true;
		if (isGame)
		{
			var names = ['left', 'down', 'up', 'right'];
			for (i in 0...names.length)
			{
				var button = new FlxSprite(i * FlxG.width / 4, 0);
				button.loadGraphic(FlxGraphic.fromFrame(Paths.getSparrowAtlas('androidcontrols/hitbox').getByName(names[i])));
				button.setGraphicSize(Std.int(FlxG.width / 4), FlxG.height);
				button.updateHitbox();
				registerButton(button, 'note_' + names[i]);
			}
			hint = new FlxSprite().loadGraphic(Paths.image('androidcontrols/hitbox_hint'));
			hint.setGraphicSize(FlxG.width, FlxG.height);
			hint.updateHitbox();
			hint.scrollFactor.set();
			hint.cameras = [controlCamera];
			hint.alpha = 0.75;
			sprites.add(hint);
			addButton(FlxG.width / 2 - 68, 8, 136, 64, 'PAUSE', 'pause');
		}
		else
		{
			// Psych 0.6.3 virtual D-pad and A/B positions on a 1280x720 canvas.
			addPadButton(0, FlxG.height - 243, 'left', 'ui_left');
			addPadButton(105, FlxG.height - 135, 'down', 'ui_down');
			addPadButton(105, FlxG.height - 348, 'up', 'ui_up');
			addPadButton(207, FlxG.height - 243, 'right', 'ui_right');
			addPadButton(FlxG.width - 132, FlxG.height - 135, 'a', 'accept');
			addPadButton(FlxG.width - 258, FlxG.height - 135, 'b', 'back');
		}
	}

	function registerButton(button:FlxSprite, action:String)
	{
		button.scrollFactor.set();
		button.cameras = [controlCamera];
		button.antialiasing = ClientPrefs.data.antialiasing;
		sprites.add(button);
		buttons.push(button);
		actions.push(action);
	}

	function addPadButton(x:Float, y:Float, name:String, action:String)
	{
		var button = new FlxSprite(x, y);
		button.frames = FlxTileFrames.fromFrame(Paths.getPackerAtlas('androidcontrols/virtualpad').getByName(name), FlxPoint.get(132, 135));
		button.animation.add('idle', [0]);
		button.animation.add('pressed', [1]);
		button.animation.play('idle');
		registerButton(button, action);
	}

	function addButton(x:Float, y:Float, width:Float, height:Int, label:String, action:String)
	{
		var button = new FlxSprite(x, y).makeGraphic(Std.int(width), height, 0xFF202030);
		button.alpha = 0.55;
		registerButton(button, action);
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
		var blocked:Map<Int, Bool> = [];
		for (touch in FlxG.touches.list)
		{
			if (!touch.pressed)
				continue;
			if (blockedFingers.exists(touch.touchPointID))
			{
				blocked.set(touch.touchPointID, true);
				continue;
			}
			var action:String = null;
			if (touch.justPressed || fingers.exists(touch.touchPointID))
			{
				// Pause takes precedence over the full-height note hitboxes beneath it.
				for (offset in 0...buttons.length)
				{
					var i = buttons.length - 1 - offset;
					if (touch.overlaps(buttons[i], controlCamera))
					{
						action = actions[i];
						break;
					}
				}
				active.set(touch.touchPointID, action);
			}
			if (action != null)
			{
				active.set(touch.touchPointID, action);
				held.set(action, true);
			}
		}
		fingers = active;
		blockedFingers = blocked;
		for (i in 0...buttons.length)
		{
			var note = StringTools.startsWith(actions[i], 'note_');
			buttons[i].visible = !note || ClientPrefs.data.showHitboxes;
			buttons[i].alpha = note ? (held.exists(actions[i]) ? 0.75 : 0) : 0.75;
			if (!gameplay)
				buttons[i].animation.play(held.exists(actions[i]) ? 'pressed' : 'idle');
		}
		if (hint != null)
			hint.visible = ClientPrefs.data.showHitboxes;
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
