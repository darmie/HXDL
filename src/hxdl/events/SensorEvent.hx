// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package hxdl.events;

enum SensorEventType {
	SENSOR_ACCELEROMETER;
}

class SensorEvent {
	public static var eventObject:SensorEvent;
	public static var callback:SensorEvent->Void;

	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var id:Int;
	public var eventType:SensorEventType;

	public function new() {
		eventType = SENSOR_ACCELEROMETER;
		id = 0;
		x = 0;
		y = 0;
		z = 0;
	}


    public static function dispatch(event:SensorEvent){
        if(SensorEvent.callback != null){
			eventObject = event;
            callback(event);
        }
    }
}
