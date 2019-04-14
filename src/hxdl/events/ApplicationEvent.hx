package hxdl.events;

enum ApplicationEventType {

		UPDATE;
		EXIT;

	}

class ApplicationEvent{
	public var deltaTime:Int;
	public var eventType:ApplicationEventType;

	public static var eventObject:ApplicationEvent;
	public static var callback:ApplicationEvent->Void;


	public function new(){
		deltaTime = 0;
		eventType = UPDATE;
	}

	public static function dispatch(event:ApplicationEvent){
		if(ApplicationEvent.callback != null){
			eventObject = event;
			callback(eventObject);
		}
	}
}