package hxdl;

import hxdl.events.KeyEvent;

class Keyboard {
    public var onKeyDown = new Event<KeyCode->KeyModifier->Void>();
	public var onKeyUp = new Event<KeyCode->KeyModifier->Void>();

    public function new() {
        KeyEvent.callback = function(event:KeyEvent){
            switch(event.eventType){
                case KEY_DOWN:{
                    onKeyDown.dispatch(event.keyCode, event.modifier);
                }
	            case KEY_UP: {
                    onKeyUp.dispatch(event.keyCode, event.modifier);
                }
                default:
            }
        };
    }
}