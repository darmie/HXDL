// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

enum ClipboardEventType {
	CLIPBOARD_UPDATE;
}

class ClipboardEvent {
	public static var eventObject:ClipboardEvent;
	public static var callback:ClipboardEvent->Void;

    public var eventType:ClipboardEventType;


    public function new(){
        this.eventType = CLIPBOARD_UPDATE;
    }


    public static function dispatch(event:ClipboardEvent){
        if(callback != null){
            eventObject = event;
            callback(eventObject);
        }
    }


}
