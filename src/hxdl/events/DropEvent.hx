// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

import sdl.SDL;
import sdl.Event;

enum DropEventType {
	DROP_FILE;
}

class DropEvent {
	public static var callback:DropEvent->Void;
	public static var eventObject:DropEvent;

	public var file:String;

	public var eventType:DropEventType;


	public function new(){
		file = null;
		this.eventType = DROP_FILE;
	}

	public static function dispatch(event:DropEvent){
		if(callback != null){
			eventObject = event;
			callback(eventObject);
		}
	}


    
}
