// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

enum WindowEventType {
	WINDOW_ACTIVATE;
	WINDOW_CLOSE;
	WINDOW_DEACTIVATE;
	WINDOW_ENTER;
	WINDOW_EXPOSE;
	WINDOW_FOCUS_IN;
	WINDOW_FOCUS_OUT;
	WINDOW_LEAVE;
	WINDOW_MAXIMIZE;
	WINDOW_MINIMIZE;
	WINDOW_MOVE;
	WINDOW_RESIZE;
	WINDOW_RESTORE;
}

class WindowEvent {
	public var height:Int;
	public var eventType:WindowEventType;
	public var width:Int;
	public var windowID:Int;
	public var x:Int;
	public var y:Int;

	public static var eventObject:WindowEvent;
	public static var callback:WindowEvent->Void;

	public function new() {
		eventType = WINDOW_ACTIVATE;

		width = 0;
		height = 0;
		windowID = 0;
		x = 0;
		y = 0;
	}

	public static function dispatch(event:WindowEvent) {
		if (WindowEvent.callback != null) {
			eventObject = new WindowEvent();
			eventObject.eventType = event.eventType;
			eventObject.windowID = event.windowID;

			switch (event.eventType) {
				case WINDOW_MOVE:
					eventObject.x = event.x;
					eventObject.y = event.y;

				case WINDOW_RESIZE:
					eventObject.width = event.width;
					eventObject.height = event.height;

				case _:
			}

            callback(eventObject);
		}
	}
}
