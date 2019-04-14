// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

import sdl.Event;

enum JoystickEventType {
	JOYSTICK_AXIS_MOVE;
	JOYSTICK_HAT_MOVE;
	JOYSTICK_TRACKBALL_MOVE;
	JOYSTICK_BUTTON_DOWN;
	JOYSTICK_BUTTON_UP;
	JOYSTICK_CONNECT;
	JOYSTICK_DISCONNECT;
}

class JoystickEvent {
	public static var callback:JoystickEvent->Void;
	public static var eventObject:JoystickEvent;

	public var eventType:JoystickEventType;
	public var eventValue:Int;
	public var index:Int;
	public var x:Float;
	public var y:Float;
	public var id:Int;

	public function new() {
		id = 0;
		index = 0;
		eventValue = 0;
		x = 0;
		y = 0;
		eventType = JOYSTICK_AXIS_MOVE;
	}

	public static function dispatch(event:JoystickEvent) {
        if(JoystickEvent.callback != null){
			eventObject = event;
            callback(event);
        }
    }
}
