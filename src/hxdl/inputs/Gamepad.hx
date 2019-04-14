package hxdl.inputs;

import haxe.io.Bytes;
import haxe.io.BytesData;
import sdl.Joystick;
import sdl.GameController;
import sdl.SDL;

@:headerCode('
    #include <map>
')
@:cppFileCode('std::map<int, SDL_GameController*> gameControllers = std::map<int, SDL_GameController*> ();')
class Gamepad {
	private static var gameControllerIDs:Map<Int, Int> = new Map<Int, Int>();

	// private static var joysticks:Map<Int, GameController> = new Map<Int, GameController>();

	@:functionCode('
        return gameControllers[deviceID];
    ')
	public static function getGameController(deviceID:Int):GameController {
		return null;
	}

	@:functionCode('
        gameControllers[deviceID] = joystick;
    ')
	public static function setGameController(deviceID:Int, joystick:GameController) {}

	public static function connect(deviceID:Int):Bool {
		if (SDL.isGameController(deviceID)) {
			var gameController:GameController = SDL.gameControllerOpen(deviceID);

			if (gameController != null) {
				var joystick:sdl.Joystick = SDL.gameControllerGetJoystick(gameController);
				var id = SDL.joystickInstanceID(joystick);
				setGameController(id, gameController);
				gameControllerIDs.set(deviceID, id);

				return true;
			}
		}

		return false;
	}

	public static function disconnect(id:Int):Bool {
		var check:Bool = untyped __cpp__('gameControllers.find (id) != gameControllers.end ()');

		if (check) {
			var controller = getGameController(id);
			SDL.gameControllerClose(controller);
			untyped __cpp__('gameControllers.erase (id)');
			return true;
		}

		return false;
	}

	public static function getInstanceID(deviceID:Int):Int {
		return gameControllerIDs.get(deviceID);
	}

	public static function getDeviceGUID(id:Int):String {
		var joystick = SDL.gameControllerGetJoystick(getGameController(id));

		if (joystick != null) {
			var guid = SDL.joystickGetGUID(joystick);
			return guid.toString();
		}

		return null;
	}

	public static function addMapping(content:String){
		SDL.gameControllerAddMapping(content);
	}

	public static function getDeviceName(id:Int):String {
		return SDL.gameControllerName(getGameController(id));
	}
}
