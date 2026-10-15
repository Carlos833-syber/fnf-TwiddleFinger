import backend.MobileControls;
import TestTypes.Touch;

class Test
{
	static function check(ok:Bool, name:String)
	{
		if (!ok)
			throw name;
	}

	static function main()
	{
		var play = new PlayState();
		FlxG.state = play;
		var controls = new MobileControls();
		controls.update(0);
		var left = new Touch(1, 100, 100);
		var down = new Touch(2, 400, 350);
		FlxG.touches.list = [left, down];
		controls.update(0);
		check(MobileControls.justPressed('note_left') && MobileControls.justPressed('note_down'), 'chord');
		TestTypes.ClientPrefs.data.showHitboxes = false;
		controls.update(0);
		check(MobileControls.pressed('note_left') && MobileControls.pressed('note_down'), 'hidden hitboxes still accept notes');
		check(!TestTypes.FlxSprite.instances[0].visible && !TestTypes.FlxSprite.instances[4].visible, 'hidden lanes and hint');
		TestTypes.ClientPrefs.data.showHitboxes = true;
		controls.update(0);
		check(TestTypes.FlxSprite.instances[0].visible && TestTypes.FlxSprite.instances[4].visible, 'show hitboxes again');
		left.justPressed = false;
		down.justPressed = false;
		controls.update(0);
		check(MobileControls.pressed('note_left') && !MobileControls.justPressed('note_left'), 'sustain');
		var secondLeft = new Touch(3, 100, 650);
		FlxG.touches.list = [left, secondLeft];
		controls.update(0);
		check(!MobileControls.justReleased('note_left') && MobileControls.justReleased('note_down'), 'independent release');
		secondLeft.justPressed = false;
		FlxG.touches.list = [secondLeft];
		controls.update(0);
		check(MobileControls.pressed('note_left'), 'same lane two fingers');
		FlxG.touches.list = [];
		controls.update(0);
		check(MobileControls.justReleased('note_left'), 'last finger release');
		var pause = new Touch(4, 640, 40);
		var right = new Touch(7, 1180, 650);
		FlxG.touches.list = [pause, right];
		controls.update(0);
		check(MobileControls.justPressed('pause'), 'pause');
		check(!MobileControls.pressed('note_up') && !MobileControls.pressed('note_down'), 'pause does not hit underlying note');
		pause.justPressed = false;
		right.justPressed = false;
		play.paused = true;
		controls.update(0);
		check(!MobileControls.pressed('pause')
			&& !MobileControls.justPressed('accept')
			&& !MobileControls.justPressed('back'), 'mode reset');
		var ok = new Touch(5, 1210, 650);
		FlxG.touches.list = [ok];
		controls.update(0);
		check(MobileControls.justPressed('accept'), 'menu accept');
		var back = new Touch(6, 1060, 650);
		FlxG.touches.list = [back];
		controls.update(0);
		check(MobileControls.justPressed('back'), 'menu back');
		back.justPressed = false;
		play.paused = false;
		controls.update(0);
		check(!MobileControls.pressed('note_right'), 'resume ignores held menu finger');
		back.x = 100;
		controls.update(0);
		check(!MobileControls.pressed('note_left'), 'held menu finger remains blocked after dragging');
		var moved = new Touch(8, 100, 650);
		FlxG.touches.list = [moved];
		controls.update(0);
		moved.justPressed = false;
		moved.x = 800;
		controls.update(0);
		check(MobileControls.justReleased('note_left') && MobileControls.justPressed('note_up'), 'drag switches columns');
		play.isDead = true;
		controls.update(0);
		check(!MobileControls.pressed('note_left'), 'death clears note input');
		var retry = new Touch(9, 1210, 650);
		FlxG.touches.list = [retry];
		controls.update(0);
		check(MobileControls.justPressed('accept'), 'game over retry');
		controls.destroy();
		check(!MobileControls.pressed('back'), 'destroy clears input');
		trace('PASS: multitouch chord, sustain, shared lane, releases, pause, menu, lifecycle');
	}
}
