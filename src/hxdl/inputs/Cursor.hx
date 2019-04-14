package hxdl.inputs;

import sdl.Cursor as SDLCursor;


enum ECursor {
	HIDDEN;
	ARROW;
	CROSSHAIR;
	DEFAULT;
	MOVE;
	POINTER;
	RESIZE_NESW;
	RESIZE_NS;
	RESIZE_NWSE;
	RESIZE_WE;
	TEXT;
	WAIT;
	WAIT_ARROW;
	CUSTOM;
}
class Cursor {
	public static var arrowCursor:SDLCursor;
	public static var crosshairCursor:SDLCursor;
	public static var moveCursor:SDLCursor;
	public static var pointerCursor:SDLCursor;
	public static var resizeNESWCursor:SDLCursor;
	public static var resizeNSCursor:SDLCursor;
	public static var resizeNWSECursor:SDLCursor;
	public static var resizeWECursor:SDLCursor;
	public static var textCursor:SDLCursor;
	public static var waitCursor:SDLCursor;
	public static var waitArrowCursor:SDLCursor;
}