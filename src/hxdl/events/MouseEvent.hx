// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

enum MouseEventType {
	MOUSE_DOWN;
	MOUSE_UP;
	MOUSE_MOVE;
	MOUSE_WHEEL;
}

class MouseEvent {
	public var button:Int;
	public var movementX:Float;
	public var movementY:Float;
	public var eventType:MouseEventType;
	public var x:Float;
	public var y:Float;

    public var windowID:Int;

	public static var callback:MouseEvent->Void;
	public static var eventObject:MouseEvent;


    public function new(){
        button = 0;
		eventType = MOUSE_DOWN;
		windowID = 0;
		x = 0.0;
		y = 0.0;
		movementX = 0.0;
		movementY = 0.0;
    }

	public static function dispatch(event:MouseEvent) {
		if (MouseEvent.callback != null) {
			eventObject = event;
			callback(event);
		}
	}
}
