package hxdl;

import hxdl.inputs.Joystick as SDLJoystick;
import hxdl.inputs.JoystickHatPosition;
import hxdl.events.JoystickEvent;

class Joystick {
	public static var devices = new Map<Int, Joystick>();
	public static var onConnect = new Event<Joystick->Void>();

	public var connected(default, null):Bool;
	public var guid(get, never):String;
	public var id(default, null):Int;
	public var name(get, never):String;
	public var numAxes(get, never):Int;
	public var numButtons(get, never):Int;
	public var numHats(get, never):Int;
	public var numTrackballs(get, never):Int;
	public var onAxisMove = new Event<Int->Float->Void>();
	public var onButtonDown = new Event<Int->Void>();
	public var onButtonUp = new Event<Int->Void>();
	public var onDisconnect = new Event<Void->Void>();
	public var onHatMove = new Event<Int->JoystickHatPosition->Void>();
	public var onTrackballMove = new Event<Int->Float->Float->Void>();

	public function new(id:Int = 0) {
		this.id = id;
		
		JoystickEvent.callback = function(event:JoystickEvent) {
			switch (event.eventType) {
				case JOYSTICK_AXIS_MOVE: {
                    onAxisMove.dispatch(event.index, event.x);
                }
				case JOYSTICK_HAT_MOVE: {
                   
                    onHatMove.dispatch(event.index, event.eventValue);
                }
				case JOYSTICK_TRACKBALL_MOVE: {
                    onTrackballMove.dispatch(event.index, event.x, event.y);
                }
				case JOYSTICK_BUTTON_DOWN: {
                    onButtonDown.dispatch(event.index);
                }
				case JOYSTICK_BUTTON_UP:{
                    onButtonUp.dispatch(event.index);
                }
				case JOYSTICK_CONNECT: {
                    connected = true;
                    Joystick.__connect(event.id);
                }
				case JOYSTICK_DISCONNECT: {
                    Joystick.__disconnect(event.id);
                }
                default:
			}
		};
	}

	@:noCompletion private static function __connect(id:Int):Void {
		if (!devices.exists(id)) {
			var joystick = new Joystick(id);
			devices.set(id, joystick);
			onConnect.dispatch(joystick);
		}
	}

	@:noCompletion private static function __disconnect(id:Int):Void {
		var joystick = devices.get(id);
		if (joystick != null)
			joystick.connected = false;
		devices.remove(id);
		if (joystick != null)
			joystick.onDisconnect.dispatch();
	}

	// Get & Set Methods
	@:noCompletion private inline function get_guid():String {
		return SDLJoystick.getDeviceGUID(this.id);
	}

	@:noCompletion private inline function get_name():String {
		return SDLJoystick.getDeviceName(this.id);
	}

	@:noCompletion private inline function get_numAxes():Int {
		return SDLJoystick.getNumAxes(this.id);
	}

	@:noCompletion private inline function get_numButtons():Int {
		return SDLJoystick.getNumButtons(this.id);
	}

	@:noCompletion private inline function get_numHats():Int {
		return SDLJoystick.getNumHats(this.id);
	}

	@:noCompletion private inline function get_numTrackballs():Int {
		return SDLJoystick.getNumTrackBalls(this.id);
	}
}
