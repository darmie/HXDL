package hxdl.inputs;

import sdl.Joystick as SDLJoystick; 
import sdl.SDL;

@:headerCode('
    #include <map>
')

@:cppFileCode('std::map<int, SDL_Joystick*> joysticks = std::map<int, SDL_Joystick*> ();')
class Joystick {
    private inline static var accelerometer:SDLJoystick = null;
    private inline static var accelerometerID:Int = -1;

    private static var joystickIDs:Map<Int, Int> = new Map<Int, Int>();
    // private static var joysticks:Map<Int, Joystick> = new Map<Int, Joystick>();


    @:functionCode('
        return joysticks[deviceID];
    ')
    public static function getJoystick(deviceID:Int):SDLJoystick {
        return null;
    }

    @:functionCode('
        joysticks[deviceID] = joystick;
    ')
    public static function setJoystick(deviceID:Int,  joystick:SDLJoystick){

    }



    public static function connect(deviceID:Int):Bool{
        if(deviceID != accelerometerID){
            var joystick:SDLJoystick = SDL.joystickOpen(deviceID);
            var id:Int = SDL.joystickInstanceID(joystick);

            if(joystick != null){
                setJoystick(id, joystick);
                joystickIDs.set(deviceID, id);

                return true;
            }
        }

        return false;
    }

    public static function disconnect(id:Int):Bool {
        var check:Bool = untyped  __cpp__('joysticks.find (id) != joysticks.end ()');

        if(check){
            var joystick = getJoystick(id);
            SDL.joystickClose(joystick);
            untyped __cpp__('joysticks.erase (id)');
            return true;
        }

        return false;
    }

    public static function getInstanceID(deviceID:Int):Int{
        return joystickIDs.get(deviceID);
    }

    public static function init(){
        
        #if (ios || android || tvos)
            for(i in 0...SDL.numJoysticks()){
                if(SDL.joystickNameForIndex(i) == "Accelerometer"){
                    accelerometer = SDL.joystickOpen(i);
                    accelerometerID = SDL.joystickInstanceID(accelerometer);
                }
            }
        #end
    }


    public static function isAccelerometer(id:Int):Bool{
        return (id == accelerometerID);
    }

    public static function getDeviceGUID(id:Int):String {
       return SDL.joystickGetGUID(getJoystick(id)).toString();
    }

    public static function getDeviceName(id:Int):String {
        return SDL.joystickName(getJoystick(id));
    }

    public static function getNumAxes(id:Int):Int {
        return SDL.joystickNumAxes(getJoystick(id));
    }

    public static function getNumButtons(id:Int){
        return SDL.joystickNumButtons(getJoystick(id));
    }

    public static function getNumHats(id:Int){
        return SDL.joystickNumHats(getJoystick(id));
    }

    public static function getNumTrackBalls(id:Int){
        return SDL.joystickNumBalls(getJoystick(id));
    }


}