package hxdl.events;


enum TouchEventType {

		TOUCH_START;
		TOUCH_END;
		TOUCH_MOVE;

	}
class TouchEvent {
    public var id:Int;
    public var device:Int;

    public static var eventObject:TouchEvent;
	public static var callback:TouchEvent->Void;


    public var eventType:TouchEventType;

    public var dx:Float;
    public var dy:Float;

    public var x:Float;
    public var y:Float;

    public var pressure:Float;


    public function new(){
        eventType = TOUCH_START;
		x = 0;
		y = 0;
		id = 0;
		dx = 0;
		dy = 0;
		pressure = 0;
		device = 0;
    }



    public static function dispatch(event:TouchEvent){
        if(TouchEvent.callback != null){
            eventObject = event;
			
            callback(event);
        }
    }
    



}