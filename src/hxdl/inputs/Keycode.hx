package hxdl.inputs;

import sdl.SDL;

class Keycode {
    public static function fromScanCode(scancode:SDLScancode):SDLKeycode {
        return SDL.getKeyFromScancode(untyped __cpp__('SDL_Scancode(scancode)'));
    }

    public static function toScanCode(keycode:SDLKeycode):SDLScancode {
        return SDL.getScancodeFromKey(keycode);
    }
}