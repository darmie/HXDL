// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

enum GamepadEventType {
	GAMEPAD_AXIS_MOVE;
	GAMEPAD_BUTTON_DOWN;
	GAMEPAD_BUTTON_UP;
	GAMEPAD_CONNECT;
	GAMEPAD_DISCONNECT;
}

class GamepadEvent {
	public var axis:Int;
	public var button:Int;
	public var id:Int;
	public var axisValue:Float;
	public var eventType:GamepadEventType;

	public static var eventObject:GamepadEvent;
	public static var callback:GamepadEvent->Void;

	public function new() {
		axis = 0;
		axisValue = 0;
		button = 0;
		id = 0;
		eventType = GAMEPAD_AXIS_MOVE;
	}

	public static function dispatch(event:GamepadEvent) {
		if (callback != null) {
			eventObject = new GamepadEvent();
			eventObject.axis = event.axis;
			eventObject.button = event.button;
			eventObject.id = event.id;
			eventObject.eventType = event.eventType;
			eventObject.axisValue = event.axisValue;

            callback(eventObject);
		}
	}
}
