// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

enum TextEventType {
	TEXT_INPUT;
	TEXT_EDIT;
}

class TextEvent {
	public var id:Int;
	public var windowID:Int;
	public var start:Int;
	public var length:Int;
	public var eventType:TextEventType;

	public static var eventObject:TextEvent;
	public static var callback:TextEvent->Void;

    public var text:cpp.ConstCharStar;

	public function new() {
		length = 0;
		start = 0;
		text = "";
		windowID = 0;
	}

    public static function dispatch(event:TextEvent){
        if(TextEvent.callback != null){
            eventObject = event;
            if(event.eventType == TEXT_INPUT){
                eventObject.length = 0;
                eventObject.start = 0;
            }
			
            callback(event);
        }
    }
}
