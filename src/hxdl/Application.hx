package hxdl;

// Copyright (c) 2019 Zenturi Software Co.
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT
import cpp.RawPointer;
import sdl.Keycodes;
import sdl.SDL;
import hxdl.events.*;
import hxdl.inputs.Joystick as SDLJoystick;
import hxdl.inputs.Gamepad as SDLGamepad;
import hxdl.events.ApplicationEvent;

#if mac
@:headerCode('
    #include <CoreFoundation/CoreFoundation.h>
')
#end
#if android
@:headerCode('
    int SDL_main (int argc, char *argv[]) { return 0; }
')
#end
class Application {
	public static var callback:Application->Void;
	public static var currentApplication:Application;
	private static var active:Bool;

	private var gamepadsAxisMap:Map<Int, Map<Int, Int>>;
	private var inBackground:Bool = false;
	private var framePeriod:Float;
	private var currentUpdate:Int;
	private var lastUpdate:Int;
	private var nextUpdate:Int;
	private var joystickEvent:JoystickEvent;
	private var keyEvent:KeyEvent;
	private var mouseEvent:MouseEvent;
	private var touchEvent:TouchEvent;
	private var sensorEvent:SensorEvent;
	private var textEvent:TextEvent;
	private var windowEvent:WindowEvent;
	private var applicationEvent:ApplicationEvent;
	private var renderEvent:RenderEvent;
	private var clipboardEvent:ClipboardEvent;
	private var dropEvent:DropEvent;
	private var gamepadEvent:GamepadEvent;
	private var analogAxisDeadZone:Int = 1000;

	public var onUpdate = new Event<Int->Void>();
	public var onExit = new Event<Int->Void>();

	public function new() {
		var initFlags:SDLInitFlags = SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_TIMER | SDL_INIT_JOYSTICK;

		#if HXDL_OPENALSOFT
		initFlags |= SDL_INIT_AUDIO;
		#end

		if (SDL.init(initFlags) != 0) {
			throw 'Could not initialize SDL : ${SDL.getError()}';
		}

		SDL.logSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_WARN);

		Application.currentApplication = this;

		framePeriod = 1000.0 / 60.0;

		currentUpdate = 0;
		lastUpdate = 0;
		nextUpdate = 0;

		this.applicationEvent = new ApplicationEvent();
		this.renderEvent = new RenderEvent();
		this.dropEvent = new DropEvent();
		this.gamepadEvent = new GamepadEvent();
		this.clipboardEvent = new ClipboardEvent();
		this.joystickEvent = new JoystickEvent();
		this.keyEvent = new KeyEvent();
		this.touchEvent = new TouchEvent();
		this.mouseEvent = new MouseEvent();
		this.sensorEvent = new SensorEvent();
		this.textEvent = new TextEvent();
		this.windowEvent = new WindowEvent();

		SDL.eventState(SDL_DROPFILE, SDL_ENABLE);

		SDLJoystick.init();

		#if mac
		untyped __cpp__('CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL (CFBundleGetMainBundle ())');
		untyped __cpp__('char path[PATH_MAX]');
		untyped __cpp__('
                if (CFURLGetFileSystemRepresentation (resourcesURL, TRUE, (UInt8 *)path, PATH_MAX)) {

                    chdir (path);

                }

                CFRelease (resourcesURL)');

		#end


		ApplicationEvent.callback = function(event:ApplicationEvent) {
			switch (event.eventType) {
				case EXIT:
					{};
				case UPDATE:
					{
						onUpdate.dispatch(event.deltaTime);
					}
			}
		};
	}

	/**
	 * Start the application life cycle
	 * @return Int
	 */
	public function exec():Int {
		init();

		#if ios
		return 0;
		#else
		while (active) {
			update();
		}
		return quit();
		#end
	}

	/**
	 * Handle all possible application events
	 * @param event
	 */
	public function handleEvent(event:sdl.Event) {
		switch (event.type) {
			case SDL_USEREVENT:
				{
					if (!inBackground) {
						currentUpdate = SDL.getTicks();
						applicationEvent.eventType = UPDATE;
						applicationEvent.deltaTime = currentUpdate - lastUpdate;
						lastUpdate = currentUpdate;

						nextUpdate += Std.int(framePeriod);
						while (nextUpdate <= currentUpdate) {
							nextUpdate += Std.int(framePeriod);
						}
						
						
						ApplicationEvent.dispatch(applicationEvent);
						RenderEvent.dispatch(renderEvent);
					}
				}
			case SDL_APP_WILLENTERBACKGROUND:
				{
					inBackground = true;

					windowEvent.eventType = WINDOW_DEACTIVATE;
					WindowEvent.dispatch(windowEvent);
				}

			case SDL_APP_WILLENTERFOREGROUND | SDL_APP_DIDENTERFOREGROUND:
				{
					windowEvent.eventType = WINDOW_ACTIVATE;
					WindowEvent.dispatch(windowEvent);

					inBackground = false;
				}
			case SDL_CLIPBOARDUPDATE:
				processClipboardEvent(event);

			case SDL_CONTROLLERAXISMOTION | SDL_CONTROLLERBUTTONDOWN | SDL_CONTROLLERBUTTONUP | SDL_CONTROLLERDEVICEADDED | SDL_CONTROLLERDEVICEREMOVED:
				{
					processGamepadEvent(event);
				}
			case SDL_DROPFILE:
				processDropEvent(event);

			case SDL_FINGERMOTION | SDL_FINGERDOWN | SDL_FINGERUP:
				{
					#if mac
					processTouchEvent(event);
					#end
				}
			case SDL_JOYAXISMOTION:
				{
					if (SDLJoystick.isAccelerometer(event.jaxis.which)) {
						processSensorEvent(event);
					} else {
						processJoystickEvent(event);
					}
				}
			case SDL_JOYBALLMOTION | SDL_JOYBUTTONDOWN | SDL_JOYBUTTONUP | SDL_JOYHATMOTION | SDL_JOYDEVICEADDED | SDL_JOYDEVICEREMOVED:
				{
					processJoystickEvent(event);
				}
			case SDL_KEYDOWN | SDL_KEYUP:
				{
					processKeyEvent(event);
				}
			case SDL_MOUSEMOTION | SDL_MOUSEBUTTONDOWN | SDL_MOUSEBUTTONUP | SDL_MOUSEWHEEL:
				{
					processMouseEvent(event);
				}

			#if EMSCRIPTEN
			case SDL_RENDER_DEVICE_RESET:
				{
					renderEvent.eventType = RENDER_CONTEXT_LOST;
					RenderEvent.dispatch(renderEvent);

					renderEvent.eventType = RENDER_CONTEXT_RESTORED;
					RenderEvent.dispatch(renderEvent);

					renderEvent.eventType = RENDER;
				}
			#end

			case SDL_TEXTINPUT | SDL_TEXTEDITING:
				processTextEvent(event);

			case SDL_WINDOWEVENT:
				switch (event.window.event) {
					case SDL_WINDOWEVENT_ENTER | SDL_WINDOWEVENT_LEAVE | SDL_WINDOWEVENT_SHOWN | SDL_WINDOWEVENT_HIDDEN | SDL_WINDOWEVENT_FOCUS_GAINED | SDL_WINDOWEVENT_FOCUS_LOST | SDL_WINDOWEVENT_MAXIMIZED | SDL_WINDOWEVENT_MINIMIZED | SDL_WINDOWEVENT_MOVED | SDL_WINDOWEVENT_RESTORED: processWindowEvent(event);

					case SDL_WINDOWEVENT_EXPOSED:
						{
							processWindowEvent(event);

							if (!inBackground) {
								RenderEvent.dispatch(renderEvent);
							}
						}

					case SDL_WINDOWEVENT_SIZE_CHANGED:
						{
							processWindowEvent(event);

							if (!inBackground) {
								RenderEvent.dispatch(renderEvent);
							}
						}

					case SDL_WINDOWEVENT_CLOSE:
						{
							processWindowEvent(event);

							// Avoid handling SDL_QUIT if in response to window.close
							var event:sdl.Event = SDL.pollEvent();

							if (untyped __cpp__('SDL_PollEvent (&event)')) {
								if (event.type != SDL_QUIT) {
									handleEvent(event);
								}
							}
						}
					case _:
				}
			case SDL_QUIT:
				{
					active = false;
				}
			case _:
		}
	}

	/**
	 * Initialize Application
	 */
	public function init() {
		active = true;
		lastUpdate = SDL.getTicks();
		nextUpdate = lastUpdate;
	}

	/**
	 * Process Joystick Event
	 * @param event
	 */
	public function processJoystickEvent(event:sdl.Event) {
		if (JoystickEvent.callback != null) {
			switch (event.type) {
				case SDL_JOYAXISMOTION:
					{
						if (!SDLJoystick.isAccelerometer(event.jaxis.which)) {
							joystickEvent.eventType = JOYSTICK_AXIS_MOVE;
							joystickEvent.index = event.jaxis.axis;
							joystickEvent.x = event.jaxis.value / (event.jaxis.value > 0 ? 32767.0 : 32768.0);
							joystickEvent.id = event.jaxis.which;

							JoystickEvent.dispatch(joystickEvent);
						}
					}
				case SDL_JOYBALLMOTION:
					{
						if (!SDLJoystick.isAccelerometer(event.jball.which)) {
							joystickEvent.eventType = JOYSTICK_TRACKBALL_MOVE;
							joystickEvent.index = event.jball.ball;
							joystickEvent.x = event.jball.xrel / (event.jball.xrel > 0 ? 32767.0 : 32768.0);
							joystickEvent.y = event.jball.yrel / (event.jball.yrel > 0 ? 32767.0 : 32768.0);
							joystickEvent.id = event.jball.which;

							JoystickEvent.dispatch(joystickEvent);
						}
					}
				case SDL_JOYBUTTONDOWN:
					{
						if (!SDLJoystick.isAccelerometer(event.jbutton.which)) {
							joystickEvent.eventType = JOYSTICK_BUTTON_DOWN;
							joystickEvent.index = event.jbutton.button;
							joystickEvent.id = event.jbutton.which;

							JoystickEvent.dispatch(joystickEvent);
						}
					}
				case SDL_JOYBUTTONUP:
					{
						if (!SDLJoystick.isAccelerometer(event.jbutton.which)) {
							joystickEvent.eventType = JOYSTICK_BUTTON_UP;
							joystickEvent.index = event.jbutton.button;
							joystickEvent.id = event.jbutton.which;

							JoystickEvent.dispatch(joystickEvent);
						}
					}
				case SDL_JOYHATMOTION:
					{
						if (!SDLJoystick.isAccelerometer(event.jhat.which)) {
							joystickEvent.eventType = JOYSTICK_HAT_MOVE;
							joystickEvent.index = event.jhat.hat;
							joystickEvent.eventValue = event.jhat.value;
							joystickEvent.id = event.jhat.which;

							JoystickEvent.dispatch(joystickEvent);
						}
					}
				case SDL_JOYDEVICEADDED:
					{
						if (SDLJoystick.connect(event.jdevice.which)) {
							joystickEvent.eventType = JOYSTICK_CONNECT;
							joystickEvent.id = SDLJoystick.getInstanceID(event.jdevice.which);

							JoystickEvent.dispatch(joystickEvent);
						}
					}
				case SDL_JOYDEVICEREMOVED:
					{
						if (SDLJoystick.connect(event.jdevice.which)) {
							joystickEvent.eventType = JOYSTICK_DISCONNECT;
							joystickEvent.id = event.jdevice.which;

							JoystickEvent.dispatch(joystickEvent);
							SDLJoystick.disconnect(event.jdevice.which);
						}
					}
				case _:
			}
		}
	}

	/**
	 * Process key events
	 * @param event
	 */
	public function processKeyEvent(event:sdl.Event) {
		if (KeyEvent.callback != null) {
			switch (event.type) {
				case SDL_KEYDOWN:
					{
						keyEvent.eventType = KEY_DOWN;
					}
				case SDL_KEYUP:
					{
						keyEvent.eventType = KEY_UP;
					}
				case _:
			}

			keyEvent.keyCode = event.key.keysym.sym;
			keyEvent.modifier = event.key.keysym.mod;
			keyEvent.windowID = event.key.windowID;

			if (keyEvent.eventType == KEY_DOWN) {
				if (keyEvent.keyCode == /*SDLK_CAPSLOCK*/ Keycodes.capslock)
					keyEvent.modifier |= KMOD_CAPS;
				if (keyEvent.keyCode == /*SDLK_LALT*/ Keycodes.lalt)
					keyEvent.modifier |= KMOD_LALT;
				if (keyEvent.keyCode == /*SDLK_LCTRL*/ Keycodes.lctrl)
					keyEvent.modifier |= KMOD_LCTRL;
				if (keyEvent.keyCode == /*SDLK_LGUI*/ Keycodes.lmeta)
					keyEvent.modifier |= KMOD_LGUI;
				if (keyEvent.keyCode == /*SDLK_LSHIFT*/ Keycodes.lshift)
					keyEvent.modifier |= KMOD_LSHIFT;
				if (keyEvent.keyCode == /*SDLK_MODE*/ Keycodes.mode)
					keyEvent.modifier |= KMOD_MODE;
				if (keyEvent.keyCode == /*SDLK_NUMLOCKCLEAR*/ Keycodes.numlockclear)
					keyEvent.modifier |= KMOD_NUM;
				if (keyEvent.keyCode == /*SDLK_RALT*/ Keycodes.ralt)
					keyEvent.modifier |= KMOD_RALT;
				if (keyEvent.keyCode == /*SDLK_RCTRL*/ Keycodes.rctrl)
					keyEvent.modifier |= KMOD_RCTRL;
				if (keyEvent.keyCode == /*SDLK_RGUI*/ Keycodes.rmeta)
					keyEvent.modifier |= KMOD_RGUI;
				if (keyEvent.keyCode == /*SDLK_RSHIFT*/ Keycodes.rshift)
					keyEvent.modifier |= KMOD_RSHIFT;
			}

			KeyEvent.dispatch(keyEvent);
		}
	}

	/**
	 * Process mouse event
	 * @param event
	 */
	public function processMouseEvent(event:sdl.Event) {
		if (MouseEvent.callback != null) {
			switch (event.type) {
				case SDL_MOUSEMOTION:
					{
						mouseEvent.eventType = MOUSE_MOVE;
						mouseEvent.x = event.motion.x;
						mouseEvent.y = event.motion.y;
						mouseEvent.movementX = event.motion.xrel;
						mouseEvent.movementY = event.motion.yrel;
					}
				case SDL_MOUSEBUTTONDOWN:
					{
						SDL.captureMouse(true);
						mouseEvent.eventType = MOUSE_DOWN;
						mouseEvent.button = event.button.button - 1;
						mouseEvent.x = event.button.x;
						mouseEvent.y = event.button.y;
					}
				case SDL_MOUSEBUTTONUP:
					{
						SDL.captureMouse(false);
						mouseEvent.eventType = MOUSE_UP;
						mouseEvent.button = event.button.button - 1;
						mouseEvent.x = event.button.x;
						mouseEvent.y = event.button.y;
					}
				case SDL_MOUSEWHEEL:
					{
						mouseEvent.eventType = MOUSE_WHEEL;

						if (event.wheel.direction == SDL_MOUSEWHEEL_FLIPPED) {
							mouseEvent.x = -event.wheel.x;
							mouseEvent.y = -event.wheel.y;
						} else {
							mouseEvent.x = event.wheel.x;
							mouseEvent.y = event.wheel.y;
						}
					}
				case _:
			}
			mouseEvent.windowID = event.button.windowID;
			MouseEvent.dispatch(mouseEvent);
		}
	}

	/**
	 * Process sensor event
	 * @param event
	 */
	public function processSensorEvent(event:sdl.Event) {
		if (SensorEvent.callback != null) {
			var value:Float = event.jaxis.value / 32767.0;

			switch (event.jaxis.axis) {
				case 0:
					sensorEvent.x = value;
				case 1:
					sensorEvent.y = value;
				case 2:
					sensorEvent.z = value;
				case _:
			}

			SensorEvent.dispatch(sensorEvent);
		}
	}

	/**
	 * Proccess text event
	 * @param event
	 */
	public function processTextEvent(event:sdl.Event) {
		if (TextEvent.callback != null) {
			switch (event.type) {
				case SDL_TEXTINPUT:
					{
						textEvent.eventType = TEXT_INPUT;
					}
				case SDL_TEXTEDITING:
					{
						textEvent.eventType = TEXT_EDIT;
						textEvent.start = event.edit.start;
						textEvent.length = event.edit.length;
					}
				case _:
			}

			if (textEvent.text != null || textEvent.text != "") {
				textEvent.text = null;
			}

			textEvent.text = event.text.text;
			textEvent.windowID = event.text.windowID;

			TextEvent.dispatch(textEvent);
		}
	}

	public function processWindowEvent(event:sdl.Event) {
		if (WindowEvent.callback != null) {
			switch (event.window.event) {
				case SDL_WINDOWEVENT_SHOWN:
					windowEvent.eventType = WINDOW_ACTIVATE;
				case SDL_WINDOWEVENT_CLOSE:
					windowEvent.eventType = WINDOW_CLOSE;
				case SDL_WINDOWEVENT_HIDDEN:
					windowEvent.eventType = WINDOW_DEACTIVATE;
				case SDL_WINDOWEVENT_ENTER:
					windowEvent.eventType = WINDOW_ENTER;
				case SDL_WINDOWEVENT_FOCUS_GAINED:
					windowEvent.eventType = WINDOW_FOCUS_IN;
				case SDL_WINDOWEVENT_FOCUS_LOST:
					windowEvent.eventType = WINDOW_FOCUS_OUT;
				case SDL_WINDOWEVENT_LEAVE:
					windowEvent.eventType = WINDOW_LEAVE;
				case SDL_WINDOWEVENT_MAXIMIZED:
					windowEvent.eventType = WINDOW_MAXIMIZE;
				case SDL_WINDOWEVENT_MINIMIZED:
					windowEvent.eventType = WINDOW_MINIMIZE;
				case SDL_WINDOWEVENT_EXPOSED:
					windowEvent.eventType = WINDOW_EXPOSE;

				case SDL_WINDOWEVENT_MOVED:
					windowEvent.eventType = WINDOW_MOVE;
					windowEvent.x = event.window.data1;
					windowEvent.y = event.window.data2;

				case SDL_WINDOWEVENT_SIZE_CHANGED:
					windowEvent.eventType = WINDOW_RESIZE;
					windowEvent.width = event.window.data1;
					windowEvent.height = event.window.data2;

				case SDL_WINDOWEVENT_RESTORED:
					windowEvent.eventType = WINDOW_RESTORE;
				case _:
			}

			windowEvent.windowID = event.window.windowID;
			WindowEvent.dispatch(windowEvent);
		}
	}

	public function processClipboardEvent(event:sdl.Event) {
		if (ClipboardEvent.callback != null) {
			clipboardEvent.eventType = CLIPBOARD_UPDATE;

			ClipboardEvent.dispatch(clipboardEvent);
		}
	}

	public function processDropEvent(event:sdl.Event) {
		if (DropEvent.callback != null) {
			dropEvent.eventType = DROP_FILE;
			dropEvent.file = event.drop.file;

			DropEvent.dispatch(dropEvent);
			dropEvent.file = null;
		}
	}

	public function processGamepadEvent(event:sdl.Event) {
		if (GamepadEvent.callback != null) {
			switch (event.type) {
				case SDL_CONTROLLERAXISMOTION:
					if (gamepadsAxisMap.exists(event.caxis.which)) {
						gamepadsAxisMap.get(event.caxis.which).set(event.caxis.axis, event.caxis.value);
					} else if (gamepadsAxisMap.get(event.caxis.which).get(event.caxis.axis) == event.caxis.value) {
						return;
					}

					gamepadEvent.eventType = GAMEPAD_AXIS_MOVE;
					gamepadEvent.axis = event.caxis.axis;
					gamepadEvent.id = event.caxis.which;

					if (event.caxis.value > -analogAxisDeadZone && event.caxis.value < analogAxisDeadZone) {
						if (gamepadsAxisMap.get(event.caxis.which).get(event.caxis.axis) != 0) {
							gamepadsAxisMap.get(event.caxis.which).set(event.caxis.axis, 0);
							gamepadEvent.axisValue = 0;
							GamepadEvent.dispatch(gamepadEvent);
						}
					}

					gamepadsAxisMap.get(event.caxis.which).set(event.caxis.axis, event.caxis.value);
					gamepadEvent.axisValue = event.caxis.value / (event.caxis.value > 0 ? 32767.0 : 32768.0);

					GamepadEvent.dispatch(gamepadEvent);

				case SDL_CONTROLLERBUTTONDOWN:
					gamepadEvent.eventType = GAMEPAD_BUTTON_DOWN;
					gamepadEvent.button = event.cbutton.button;
					gamepadEvent.id = event.cbutton.which;

					GamepadEvent.dispatch(gamepadEvent);

				case SDL_CONTROLLERBUTTONUP:
					gamepadEvent.eventType = GAMEPAD_BUTTON_UP;
					gamepadEvent.button = event.cbutton.button;
					gamepadEvent.id = event.cbutton.which;

					GamepadEvent.dispatch(gamepadEvent);

				case SDL_CONTROLLERDEVICEADDED:
					if (SDLGamepad.connect(event.cdevice.which)) {
						gamepadEvent.eventType = GAMEPAD_CONNECT;
						gamepadEvent.id = SDLGamepad.getInstanceID(event.cdevice.which);

						GamepadEvent.dispatch(gamepadEvent);
					}

				case SDL_CONTROLLERDEVICEREMOVED:
					{
						gamepadEvent.eventType = GAMEPAD_DISCONNECT;
						gamepadEvent.id = event.cdevice.which;

						GamepadEvent.dispatch(gamepadEvent);
						SDLGamepad.disconnect(event.cdevice.which);
					}
				case _:
			}
		}
	}

	public function processTouchEvent(event:sdl.Event) {
		if (TouchEvent.callback != null) {
			switch (event.type) {
				case SDL_FINGERMOTION:
					touchEvent.eventType = TOUCH_MOVE;

				case SDL_FINGERDOWN:
					touchEvent.eventType = TOUCH_START;

				case SDL_FINGERUP:
					touchEvent.eventType = TOUCH_END;

				case _:
			}

			touchEvent.x = event.tfinger.x;
			touchEvent.y = event.tfinger.y;
			touchEvent.id = event.tfinger.fingerId;
			touchEvent.dx = event.tfinger.dx;
			touchEvent.dy = event.tfinger.dy;
			touchEvent.pressure = event.tfinger.pressure;
			touchEvent.device = event.tfinger.touchId;

			TouchEvent.dispatch(touchEvent);
		}
	}

	/**
	 * Quit the application
	 * @return Int
	 */
	public function quit():Int {
		applicationEvent.eventType = EXIT;
		ApplicationEvent.dispatch(applicationEvent);
		SDL.quit();

		return 0;
	}

	public function registerWindow(window:Window) {
		#if (ios || tvos)
		SDL.iPhoneSetAnimationCallback(window.sdlWindow, 1, updateFrame, NULL);
		#end
	}

	/**
	 * Set frame rate
	 * @param frameRate
	 */
	public function setFrameRate(frameRate:Float) {
		if (frameRate > 0) {
			framePeriod = 1000.0 / frameRate;
		} else {
			framePeriod = 1000.0;
		}
	}

	private static var timerID = 0;
	private var timerActive = false;
	private var firstTime = true;

	public function onTimer(interval:Int, v:Dynamic):Int {
		var event:sdl.Event = untyped __cpp__('{}');
		var userevent:sdl.Event.UserEvent =  untyped __cpp__('{}');

		userevent.type = SDL_USEREVENT;
		userevent.code = 0;
		userevent.data1 = null;
		userevent.data2 = null;
		event.type = SDL.registerEvents(1);
		event.user = userevent;
		timerActive = false;
		Application.timerID = 0;
		untyped __cpp__('SDL_PushEvent(&event)');
		return 0;
	}

	public function update():Bool {
		var event:sdl.Event = untyped __cpp__('{}');
		event.type = -1;
		
		#if !ios
		if (active && (firstTime || untyped __cpp__('waitEvent (&event)'))) {
			firstTime = false;
			handleEvent(event);
			event.type = -1;
			if (!active)
				return active;
		#end
			// event = SDL.pollEvent();
			while (untyped __cpp__('SDL_PollEvent (&event)')) {
				handleEvent(event);
				event.type = -1;
				if (!active)
					return active;
			}

			currentUpdate = SDL.getTicks();

		#if ios
			if (currentUpdate >= nextUpdate) {
				event.type = SDL_USEREVENT;
				handleEvent(event);
				event.type = -1;
			}
		#else
			if (currentUpdate >= nextUpdate) {
				SDL.removeTimer(Application.timerID);
				onTimer(0, 0);
			} else if (!timerActive) {
				timerActive = true;
				Application.timerID = SDL.addTimer(nextUpdate - currentUpdate, onTimer, 0);
			}
		}
		#end

		return active;
	}

	public function updateFrame() {
		currentApplication.update();
	}

	public function waitEvent(event:cpp.RawPointer<sdl.Event>):Int {
		#if mac
		cpp.vm.Gc.enterGCFreeZone();
		var result = untyped __cpp__('SDL_WaitEvent(event)');
		cpp.vm.Gc.exitGCFreeZone();
		return result;
		#else
		var isBlocking = false;

		while (true) {
			SDL.pumpEvents();

			switch (SDL.peepEvents(event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT)) {
				case -1:
					{
						if (isBlocking)
							cpp.vm.Gc.exitGCFreeZone();
						return 0;
					}
				case 1:
					{
						if (isBlocking)
							cpp.vm.Gc.exitGCFreeZone();
						return 1;
					}
				default:
					{
						if (!isBlocking)
							cpp.vm.Gc.enterGCFreeZone();
						isBlocking = true;
						SDL.delay(1);
					}
			}
		}
		#end
	}

	public static function createApplication():Application {
		return new Application();
	}
}
