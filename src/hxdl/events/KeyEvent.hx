// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

import sdl.Event;

enum KeyEventType {
	KEY_DOWN;
	KEY_UP;
}

class KeyEvent {
	public var keyCode:Int;
	public var modifier:Int;
	public var eventType:KeyEventType;
	public var windowID:Int;

	public static var callback:KeyEvent->Void;
	public static var eventObject:KeyEvent;

	public function new() {
		keyCode = 0;
		modifier = 0;
		eventType = KEY_DOWN;
		windowID = 0;
	}

	public static function dispatch(event:KeyEvent) {
		if (KeyEvent.callback != null) {
			eventObject = event;
            callback(eventObject);
		}
	}
}
