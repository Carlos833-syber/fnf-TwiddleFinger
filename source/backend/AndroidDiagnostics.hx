package backend;

#if android
import haxe.CallStack;
import haxe.io.Path;
import lime.system.Clipboard;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;

class AndroidDiagnostics
{
	static var store:AndroidDiagnosticStore;
	static var overlay:Sprite;

	static public function install():Void
	{
		store = new AndroidDiagnosticStore(Path.join([lime.system.System.applicationStorageDirectory, 'diagnostics']));
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
		if (store.previous != null && store.previous.length > 0)
			show(store.previous, false);
		begin('Preparando recursos do APK');
	}

	static public function begin(step:String):Void
	{
		if (store != null)
			store.begin(step);
	}

	static public function checkpoint(step:String):Void
	{
		if (store != null)
			store.checkpoint(step);
	}

	static public function finish():Void
	{
		if (store != null)
			store.finish();
	}

	static function onError(event:UncaughtErrorEvent):Void
	{
		event.preventDefault();
		event.stopImmediatePropagation();
		store.fail(Std.string(event.error), CallStack.toString(CallStack.exceptionStack(true)));
		// Stop the broken game loop, leaving the independent OpenFL report usable.
		if (FlxG.game != null)
		{
			@:privateAccess Lib.current.stage.removeEventListener(Event.ENTER_FRAME, FlxG.game.onEnterFrame);
		}
		show(store.report, true);
	}

	static function show(report:String, fatal:Bool):Void
	{
		if (overlay != null && overlay.parent != null)
			overlay.parent.removeChild(overlay);
		overlay = new Sprite();
		var stage = Lib.current.stage;
		var width = stage.stageWidth;
		var height = stage.stageHeight;
		var unit = height / 720;
		overlay.graphics.beginFill(0x111820);
		overlay.graphics.drawRect(0, 0, width, height);
		overlay.graphics.endFill();

		function text(value:String, x:Float, y:Float, w:Float, h:Float, size:Int):TextField
		{
			var field = new TextField();
			field.defaultTextFormat = new TextFormat('_sans', Std.int(size * unit), 0xFFFFFF);
			field.x = x;
			field.y = y;
			field.width = w;
			field.height = h;
			field.multiline = field.wordWrap = true;
			field.text = value;
			overlay.addChild(field);
			return field;
		}

		text('RELATORIO DO JOGO - tire uma captura ou copie o texto', 24 * unit, 15 * unit, width - 48 * unit, 45 * unit, 26);
		var body = text(report, 24 * unit, 70 * unit, width - 48 * unit, height - 165 * unit, 20);
		// A finger drag scrolls long stack traces without requiring file access or ADB.
		var startY:Float = 0;
		var scroll:Int = 1;
		body.addEventListener(TouchEvent.TOUCH_BEGIN, function(event:TouchEvent)
		{
			startY = event.stageY;
			scroll = body.scrollV;
		});
		body.addEventListener(TouchEvent.TOUCH_MOVE, function(event:TouchEvent)
		{
			body.scrollV = scroll + Std.int((startY - event.stageY) / (24 * unit));
		});

		function button(label:String, x:Float, run:Void->Void):Void
		{
			var button = new Sprite();
			button.graphics.beginFill(0x315B82);
			button.graphics.drawRect(0, 0, 330 * unit, 60 * unit);
			button.graphics.endFill();
			button.x = x;
			button.y = height - 80 * unit;
			var field = new TextField();
			field.defaultTextFormat = new TextFormat('_sans', Std.int(24 * unit), 0xFFFFFF);
			field.width = 320 * unit;
			field.height = 50 * unit;
			field.x = field.y = 10 * unit;
			field.text = label;
			field.mouseEnabled = false;
			button.addChild(field);
			button.addEventListener(MouseEvent.CLICK, function(_) run());
			overlay.addChild(button);
		}

		button('Copiar relatorio', 24 * unit, function() Clipboard.text = report);
		button(fatal ? 'Fechar jogo' : 'Continuar', width - 354 * unit, function()
		{
			if (fatal)
				lime.system.System.exit(1);
			else if (overlay.parent != null)
				overlay.parent.removeChild(overlay);
		});
		overlay.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent) event.stopPropagation());
		overlay.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent) event.stopPropagation());
		overlay.addEventListener(TouchEvent.TOUCH_BEGIN, function(event:TouchEvent) event.stopPropagation());
		overlay.addEventListener(TouchEvent.TOUCH_END, function(event:TouchEvent) event.stopPropagation());
		stage.addChild(overlay);
	}
}
#end
