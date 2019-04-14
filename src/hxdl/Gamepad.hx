package hxdl;

import hxdl.inputs.Gamepad as SDLGamepad;
import hxdl.GamepadButton;
import hxdl.events.GamepadEvent;

class Gamepad {
	public static var devices = new Map<Int, Gamepad>();
	public static var onConnect = new Event<Gamepad->Void>();

	public var connected(default, null):Bool;
	public var guid(get, never):String;
	public var id(default, null):Int;
	public var name(get, never):String;
	public var onAxisMove = new Event<GamepadAxis->Float->Void>();
	public var onButtonDown = new Event<GamepadButton->Void>();
	public var onButtonUp = new Event<GamepadButton->Void>();
	public var onDisconnect = new Event<Void->Void>();

	public function new(id:Int) {
		this.id = id;
		connected = true;

		GamepadEvent.callback = function(event:GamepadEvent) {
			switch (event.eventType) {
				case GAMEPAD_AXIS_MOVE: {
                    onAxisMove.dispatch(event.axis, event.axisValue);
                }
				case GAMEPAD_BUTTON_DOWN: {
                    onButtonDown.dispatch(event.button);
                }
				case GAMEPAD_BUTTON_UP: {
                    onButtonUp.dispatch(event.button);
                }
				case GAMEPAD_CONNECT: {
                    Gamepad.__connect(event.id);
                }
				case GAMEPAD_DISCONNECT: {
                    Gamepad.__disconnect(event.id);
                }
                default:
			}
		};
	}

	public static function addMappings(mappings:String):Void {
		SDLGamepad.addMapping(mappings);
	}

	@:noCompletion private static function __connect(id:Int):Void {
		if (!devices.exists(id)) {
			var gamepad = new Gamepad(id);
			devices.set(id, gamepad);
			onConnect.dispatch(gamepad);
		}
	}

	@:noCompletion private static function __disconnect(id:Int):Void {
		var gamepad = devices.get(id);
		if (gamepad != null)
			gamepad.connected = false;
		devices.remove(id);
		if (gamepad != null)
			gamepad.onDisconnect.dispatch();
	}

	// Get & Set Methods
	@:noCompletion private inline function get_guid():String {
		return SDLGamepad.getDeviceGUID(this.id);
	}

	@:noCompletion private inline function get_name():String {
		return SDLGamepad.getDeviceName(this.id);
	}
}
