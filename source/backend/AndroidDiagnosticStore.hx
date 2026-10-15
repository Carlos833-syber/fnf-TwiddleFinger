package backend;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** A bounded, synchronous breadcrumb survives native exits that Haxe cannot catch. */
class AndroidDiagnosticStore
{
	public var previous(default, null):String;
	public var report(default, null):String = '';

	var file:String;
	var active:Bool = false;
	var steps:Array<String> = [];

	public function new(directory:String)
	{
		file = Path.join([directory, 'android-diagnostic.txt']);
		try
		{
			FileSystem.createDirectory(directory);
			if (FileSystem.exists(file))
			{
				previous = File.getContent(file);
				FileSystem.deleteFile(file);
			}
		}
		catch (_:Dynamic)
		{
		}
	}

	public function begin(step:String):Void
	{
		active = true;
		steps = [];
		checkpoint(step);
	}

	public function checkpoint(step:String):Void
	{
		if (!active || (steps.length > 0 && steps[steps.length - 1] == step))
			return;
		steps.push(step);
		if (steps.length > 12)
			steps.shift();
		report = 'TwiddleFinger Android - diagnostico 3\n'
			+ 'Carregamento interrompido em '
			+ Date.now().toString()
			+ '\n'
			+ 'Ultima etapa: '
			+ step
			+ '\n\n'
			+ 'Etapas recentes:\n'
			+ steps.join('\n')
			+ '\n\n'
			+ 'Sem erro capturado: pode ser falha nativa, encerramento pelo sistema ou fechamento manual.';
		save();
	}

	public function fail(error:String, stack:String):Void
	{
		report = 'TwiddleFinger Android - diagnostico 3\nErro: ' + error + '\n\n' + stack + '\n\nEtapas recentes:\n' + steps.join('\n');
		active = false;
		save();
	}

	public function finish():Void
	{
		active = false;
		try
		{
			if (FileSystem.exists(file))
				FileSystem.deleteFile(file);
		}
		catch (_:Dynamic)
		{
		}
	}

	function save():Void
	{
		try
		{
			File.saveContent(file + '.tmp', report);
			FileSystem.rename(file + '.tmp', file);
		}
		catch (_:Dynamic)
		{
		}
	}
}
