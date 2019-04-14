// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

enum RenderEventType {
	RENDER;
	RENDER_CONTEXT_LOST;
	RENDER_CONTEXT_RESTORED;
}

class RenderEvent {
	public static var eventObject:RenderEvent;
	public static var callback:RenderEvent->Void;

    public var eventType:RenderEventType;

    public function new(){
        eventType = RENDER;
    }

    public static function dispatch(event:RenderEvent){
        if(callback != null){
            eventObject = event;

            callback(eventObject);
        }
    }

}
