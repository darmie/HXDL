package hxdl;

import cpp.Pointer;
import sdl.SDL.SDL_WindowFlags;
import sdl.Renderer;
import sdl.Texture;
import sdl.SDL;
import hxdl.inputs.Cursor;
import hxdl.events.WindowEvent;
#if HXDL_OPENGL
import sdl.GLContext;
import opengl.GL;
import opengl.WebGL;
#end

@:enum abstract WindowFlags(Int) to Int {
	var WINDOW_FLAG_FULLSCREEN = 0x00000001;
	var WINDOW_FLAG_BORDERLESS = 0x00000002;
	var WINDOW_FLAG_RESIZABLE = 0x00000004;
	var WINDOW_FLAG_HARDWARE = 0x00000008;
	var WINDOW_FLAG_VSYNC = 0x00000010;
	var WINDOW_FLAG_HW_AA = 0x00000020;
	var WINDOW_FLAG_HW_AA_HIRES = 0x00000060;
	var WINDOW_FLAG_ALLOW_SHADERS = 0x00000080;
	var WINDOW_FLAG_REQUIRE_SHADERS = 0x00000100;
	var WINDOW_FLAG_DEPTH_BUFFER = 0x00000200;
	var WINDOW_FLAG_STENCIL_BUFFER = 0x00000400;
	var WINDOW_FLAG_ALLOW_HIGHDPI = 0x00000800;
	var WINDOW_FLAG_HIDDEN = 0x00001000;
	var WINDOW_FLAG_MINIMIZED = 0x00002000;
	var WINDOW_FLAG_MAXIMIZED = 0x00004000;
	var WINDOW_FLAG_ALWAYS_ON_TOP = 0x00008000;
	var WINDOW_FLAG_COLOR_DEPTH_32_BIT = 0x00010000;
}

@:headerCode('
#ifdef HX_WINDOWS
#include <SDL_syswm.h>
#include <Windows.h>
#undef createWindow
#endif
')
class Window {
	private static var displayModeSet = false;

	#if HXDL_OPENGL
	private var context:GLContext;
	#elseif HXDL_VULKAN
	private var context:Dynamic; // use Vulkan context type
	#else
	private var context:Dynamic;
	#end
	private var contextHeight:Int;
	private var contextWidth:Int;

	public var sdlTexture:Texture;
	public var sdlRenderer:Renderer;
	public var currentApplication:Application;

	private var flags:Int;
	private var sdlWindow:sdl.Window;

    private var currentCursor:ECursor;

    public var onActivate = new Event<Int->Void>();
    public var onEnter = new Event<Int->Void>();
    public var onLeave = new Event<Int->Void>();
    public var onExpose = new Event<Int->Void>();
    public var onDeactivate = new Event<Int->Void>();
    public var onClose = new Event<Int->Void>();
    public var onFocusIn = new Event<Int->Void>();
    public var onFocusOut = new Event<Int->Void>();

    public var onMaximize = new Event<Int->Int->Int->Void>();
    public var onMinimize = new Event<Int->Void>();
    public var onResize = new Event<Int->Int->Int->Void>();

    public var onMove = new Event<Int->Float->Float->Void>();
    public var onRestore = new Event<Int->Int->Int->Void>();

    public static inline function __init__() {
		Cursor.arrowCursor = null;
		Cursor.crosshairCursor = null;
		Cursor.moveCursor = null;
		Cursor.pointerCursor = null;
		Cursor.resizeNESWCursor = null;
		Cursor.resizeNSCursor = null;
		Cursor.resizeNWSECursor = null;
		Cursor.resizeWECursor = null;
		Cursor.textCursor = null;
		Cursor.waitCursor = null;
		Cursor.waitArrowCursor = null;
	}

	public function new(application:Application, width:Int, height:Int, flags:Int, title:String) {
		sdlTexture = null;
		sdlRenderer = null;
		context = null;

		contextWidth = 0;
		contextHeight = 0;

		currentApplication = application;

		this.flags = flags;

		var sdlWindowFlags:Int = 0;

		if ((flags & WINDOW_FLAG_FULLSCREEN) != 0)
			sdlWindowFlags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
		if ((flags & WINDOW_FLAG_RESIZABLE) != 0) {
			sdlWindowFlags |= SDL_WINDOW_RESIZABLE;
		}
		if ((flags & WINDOW_FLAG_BORDERLESS) != 0)
			sdlWindowFlags |= SDL_WINDOW_BORDERLESS;
		if ((flags & WINDOW_FLAG_HIDDEN) != 0)
			sdlWindowFlags |= SDL_WINDOW_HIDDEN;
		if ((flags & WINDOW_FLAG_MINIMIZED) != 0)
			sdlWindowFlags |= SDL_WINDOW_MINIMIZED;
		if ((flags & WINDOW_FLAG_MAXIMIZED) != 0)
			sdlWindowFlags |= SDL_WINDOW_MAXIMIZED;

		#if windows
		untyped __cpp__('
        #if defined (HX_WINDOWS) && defined (NATIVE_TOOLKIT_SDL_ANGLE) && !defined (HX_WINRT)
		OSVERSIONINFOEXW osvi = { sizeof (osvi), 0, 0, 0, 0, {0}, 0, 0 };
		DWORDLONG const dwlConditionMask = VerSetConditionMask (VerSetConditionMask (VerSetConditionMask (0, VER_MAJORVERSION, VER_GREATER_EQUAL), VER_MINORVERSION, VER_GREATER_EQUAL), VER_SERVICEPACKMAJOR, VER_GREATER_EQUAL);
		osvi.dwMajorVersion = HIBYTE (_WIN32_WINNT_VISTA);
		osvi.dwMinorVersion = LOBYTE (_WIN32_WINNT_VISTA);
		osvi.wServicePackMajor = 0;

		if (VerifyVersionInfoW (&osvi, VER_MAJORVERSION | VER_MINORVERSION | VER_SERVICEPACKMAJOR, dwlConditionMask) == FALSE) {

			flags &= ~WINDOW_FLAG_HARDWARE;

		}
		#endif
        int nothing = 0');

		#end

		#if emscripten
		SDL.setHint(SDL_HINT_ANDROID_TRAP_BACK_BUTTON, "0");
		SDL.setHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");
		#end

		if ((flags & WINDOW_FLAG_HARDWARE) != 0) {
			#if HXDL_OPENGL
			sdlWindowFlags |= SDL_WINDOW_OPENGL;

			if ((flags & WINDOW_FLAG_ALLOW_HIGHDPI) != 0) {
				sdlWindowFlags |= SDL_WINDOW_ALLOW_HIGHDPI;
			}

			#if windows
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
			SDL.setHint(SDL_HINT_VIDEO_WIN_D3DCOMPILER, "d3dcompiler_47.dll");
			#end

			#if raspberrypi
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
			SDL_SetHint(SDL_HINT_RENDER_DRIVER, "opengles2");
			#end

			#if (ios || tvos || appletv)
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
			#end

			if ((flags & WINDOW_FLAG_DEPTH_BUFFER) != 0) {
				SDL.GL_SetAttribute(SDL_GL_DEPTH_SIZE, (32 - (flags & WINDOW_FLAG_STENCIL_BUFFER) != 0) ? 8 : 0);
			}

			if ((flags & WINDOW_FLAG_STENCIL_BUFFER) != 0) {
				SDL.GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
			}

			if ((flags & WINDOW_FLAG_HW_AA_HIRES) != 0) {
				SDL.GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
				SDL.GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
			} else if ((flags & WINDOW_FLAG_HW_AA) != 0) {
				SDL.GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
				SDL.GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 2);
			}

			if ((flags & WINDOW_FLAG_COLOR_DEPTH_32_BIT) != 0) {
				SDL.GL_SetAttribute(SDL_GL_RED_SIZE, 8);
				SDL.GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
				SDL.GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
				SDL.GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
			} else {
				SDL.GL_SetAttribute(SDL_GL_RED_SIZE, 5);
				SDL.GL_SetAttribute(SDL_GL_GREEN_SIZE, 6);
				SDL.GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
			}
			#elseif HXDL_VULKAN
			#end
		}

		sdlWindow = SDL.createWindow(title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlWindowFlags);

		#if ((ios || tvos) && HXDL_OPENGL)
		if (sdlWindow != null && SDL.GL_CreateContext(sdlWindow) != null) {
			SDL.destroyWindow(sdlWindow);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);

			sdlWindow = SDL.createWindow(title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlWindowFlags);
		}
		#elseif ((ios || tvos) && HXDL_VULKAN)
		#end

		if (sdlWindow == null) {
			throw 'Could not create SDL window: ${SDL.getError()}';
		}

		#if windows
		untyped __cpp__('
        #if defined (HX_WINDOWS) && !defined (HX_WINRT)

		HINSTANCE handle = .GetModuleHandle (nullptr);
		HICON icon = .LoadIcon (handle, MAKEINTRESOURCE (1));

		if (icon != nullptr) {

			SDL_SysWMinfo wminfo;
			SDL_VERSION (&wminfo.version);

			if (SDL_GetWindowWMInfo (sdlWindow, &wminfo) == 1) {

				HWND hwnd = wminfo.info.win.window;

				#ifdef _WIN64
				.SetClassLongPtr (hwnd, GCLP_HICON, reinterpret_cast<LONG_PTR>(icon));
				#else
				.SetClassLong (hwnd, GCL_HICON, reinterpret_cast<LONG>(icon));
				#endif

			}

		}

		#endif
        int nothing');

		#end

		var sdlRendererFlags = 0;

		if ((flags & WINDOW_FLAG_HARDWARE) != 0) {
			sdlRendererFlags |= SDL_RENDERER_ACCELERATED;

			#if HXDL_OPENGL
			context = SDL.GL_CreateContext(sdlWindow);

			if (context != null && SDL.GL_MakeCurrent(sdlWindow, context) == 0) {
				if ((flags & WINDOW_FLAG_VSYNC) != 0) {
					SDL.GL_SetSwapInterval(true);
				} else {
					SDL.GL_SetSwapInterval(false);
				}
				#if (linc_opengl_EGL || linc_opengl_GLES || linc_opengl_GLES1 || linc_opengl_GLES2 || linc_opengl_GLES3)
				var version = 0;
				GL.glGetIntegerv(GL.GL_MAJOR_VERSION, [version]);
				if (version == 0) {
					var versionScan = 0;
					untyped __cpp__('sscanf ((const char*)glGetString (GL_VERSION), "%f", &versionScan)');

					version = versionScan;
				}

				if (version < 2 && Pointer.fromRaw(GL.glGetString(GL.GL_VERSION)).get_ref().toString() == "OpenGL ES") {
					SDL.GL_DeleteContext(context);
					context = null;
				}
				#elseif (ios || tvos)
				GL.glGetIntegerv(GL.GL_FRAMEBUFFER_BINDING, [0]);
				GL.glGetIntegerv(GL.GL_RENDERBUFFER_BINDING, [0]);
				#end
			} else {
				SDL.GL_DeleteContext(context);
				context = null;
			}
			#elseif HXDL_VULKAN
			#end
		}

		if (context == null) {
			sdlRendererFlags &= ~SDL_RENDERER_ACCELERATED;
			sdlRendererFlags &= ~SDL_RENDERER_PRESENTVSYNC;

			sdlRendererFlags |= SDL_RENDERER_SOFTWARE;

			sdlRenderer = SDL.createRenderer(sdlWindow, -1, sdlRendererFlags);
		}

		if (context != null || sdlRenderer != null) {
			currentApplication.registerWindow(this);
		} else {
			trace('Could not create SDL renderer: ${SDL.getError()}');
		}

        WindowEvent.callback = function(event:WindowEvent){
            switch(event.eventType){
                	case WINDOW_ACTIVATE: onActivate.dispatch(event.windowID);
                    case WINDOW_CLOSE: onClose.dispatch(event.windowID);
                    case WINDOW_DEACTIVATE: onDeactivate.dispatch(event.windowID);
                    case WINDOW_ENTER: onEnter.dispatch(event.windowID);
                    case WINDOW_EXPOSE: onExpose.dispatch(event.windowID);
                    case WINDOW_FOCUS_IN: onFocusIn.dispatch(event.windowID);
                    case WINDOW_FOCUS_OUT: onFocusOut.dispatch(event.windowID);
                    case WINDOW_LEAVE: onLeave.dispatch(event.windowID);
                    case WINDOW_MAXIMIZE: onMaximize.dispatch(event.windowID, event.width, event.height);
                    case WINDOW_MINIMIZE: onMinimize.dispatch(event.windowID);
                    case WINDOW_MOVE: onMove.dispatch(event.windowID, event.x, event.y);
                    case WINDOW_RESIZE: onResize.dispatch(event.windowID, event.width, event.height);
                    case WINDOW_RESTORE: onRestore.dispatch(event.windowID, event.width, event.height);
            }
        };
	}

	public function alert(message:String, title:String) {
		#if windows
		untyped __cpp__('
		int count = 0;
		int speed = 0;
		bool stopOnForeground = true;

		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);
		SDL_GetWindowWMInfo (sdlWindow, &info);

		FLASHWINFO fi;
		fi.cbSize = sizeof (FLASHWINFO);
		fi.hwnd = info.info.win.window;
		fi.dwFlags = stopOnForeground ? FLASHW_ALL | FLASHW_TIMERNOFG : FLASHW_ALL | FLASHW_TIMER;
		fi.uCount = count;
		fi.dwTimeout = speed;
		FlashWindowEx (&fi)');

		#end
		if (message != null) {
			SDL.showSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, title, message, sdlWindow);
		}
	}

	public function close() {
		if (sdlWindow != null) {
			SDL.destroyWindow(sdlWindow);
			sdlWindow = null;
		}

		if (sdlRenderer != null) {
			SDL.destroyRenderer(sdlRenderer);
		} else if (context != null) {
			#if HXDL_OPENGL
			SDL.GL_DeleteContext(context);
			#elseif HXDL_VULKAN
			context = null;
			#end
		}
	}

	public function contextFlip() {
		if (context != null && sdlRenderer == null) {
			#if HXDL_OPENGL
			SDL.GL_SwapWindow(sdlWindow);
			#elseif HXDL_VULKAN
			// todo
			#end
		} else if (sdlRenderer != null) {
			SDL.renderPresent(sdlRenderer);
		}
	}

	public function contextLock() {
		if (sdlRenderer != null) {
			var size:SDLSize = {
				w: 0,
				h: 0
			};
			size = SDL.getRendererOutputSize(sdlRenderer, size);

			if (size.w != contextWidth || size.h != contextHeight) {
				if (sdlTexture != null) {
					SDL.destroyTexture(sdlTexture);

					sdlTexture = SDL.createTexture(sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, size.w, size.h);

					contextHeight = size.h;
					contextWidth = size.w;
				}
			}
		}
	}

	public function contextMakeCurrent() {
		if (sdlWindow != null && context != null) {
			#if HXDL_OPENGL
			SDL.GL_MakeCurrent(sdlWindow, context);
			#elseif HXDL_VULKAN
			// todo
			#end
		}
	}

	public function contextUnLock() {
		if (sdlTexture != null) {
			SDL.unlockTexture(sdlTexture);
			SDL.renderClear(sdlRenderer);
			SDL.renderCopy(sdlRenderer, sdlTexture, null, null);
		}
	}

	public function focus() {
		SDL.raiseWindow(sdlWindow);
	}

	public function getContext():Dynamic {
		return context;
	}

	public function getContextType():String {
		if (context != null) {
			#if HXDL_OPENGL
			return "opengl";
			#elseif HXDL_VULKAN
			return "vulkan";
			#else
			return "";
			#end
		} else if (sdlRenderer != null) {
			var info:SDLRendererInfo = null;

			info = SDL.getRendererInfo(sdlRenderer);

			if ((info.flags & SDL_RENDERER_SOFTWARE) != 0) {
				return "software";
			} else {
				#if HXDL_OPENGL
				return "opengl";
				#elseif HXDL_VULKAN
				return "vulkan";
				#else
				return "";
				#end
			}
		}

		return "none";
	}


	public function getDisplayMode(displayMode:DisplayMode){
		var mode:SDLDisplayMode = null;
		mode = SDL.getWindowDisplayMode(sdlWindow, mode);

		displayMode.width = mode.w;
		displayMode.height = mode.h;


		switch (mode.format) {

			case SDL_PIXELFORMAT_ARGB8888:
				displayMode.pixelFormat = ARGB32;
			case SDL_PIXELFORMAT_BGRA8888 | SDL_PIXELFORMAT_BGRX8888:
				displayMode.pixelFormat = BGRA32;
			default:
				displayMode.pixelFormat = RGBA32;

		}

		displayMode.refreshRate = mode.refresh_rate;
	}

	public function getHeight(){
		var size:SDLSize =  {
			w: 0,
			h: 0
		}
		size = SDL.getWindowSize(sdlWindow, size);

		return size.h;
	}

	public function getID(){
		return SDL.getWindowID(sdlWindow);
	}

	public function getMouseLock():Bool{
		return SDL.getRelativeMouseMode();
	}

	public function getScale () {

		if (sdlRenderer != null) {

			var outputsize:SDLSize = {
				w: 0,
				h: 0
			}

			outputsize = SDL.getRendererOutputSize (sdlRenderer, outputsize);

			var size:SDLSize = {
				w: 0,
				h: 0
			}

			size = SDL.getWindowSize (sdlWindow, size);

			var scale:Float = outputsize.w / size.w;
			return scale;

		} else if (context != null) {
            #if HXDL_OPENGL
			var outputsize:SDLSize = {
				w: 0,
				h: 0
			}

			outputsize = SDL.GL_GetDrawableSize (sdlWindow, outputsize);

			var size:SDLSize = {
				w: 0,
				h: 0
			}

			size = SDL.getWindowSize (sdlWindow, size);

			var scale:Float = outputsize.w / size.w;
			return scale;
            #elseif HXDL_VULKAN
            return 1;
            #else 
            return 1;
            #end
		}

		return 1;

	}


	public function getTextInputEnabled(){
		return SDL.isTextInputActive();
	}


	public function getWidth(){
		var size:SDLSize = {
			w: 0,
			h: 0
		}
		size = SDL.getWindowSize(sdlWindow, size);

		return size.w;
	}


	public function getX(){
		var pos:SDLPoint  = {
			x: 0,
			y: 0
		}
		pos = SDL.getWindowPosition(sdlWindow, pos);

		return pos.x;
	}

	public function getY(){
		var pos:SDLPoint  = {
			x: 0,
			y: 0
		}
		pos = SDL.getWindowPosition(sdlWindow, pos);

		return pos.y;
	}

	public function move(x:Int, y:Int){
		SDL.setWindowPosition (sdlWindow, x, y);
	}

	public function resize(width:Int, height:Int) {
		SDL.setWindowSize(sdlWindow, width, height);
	}

	public function setBorderless(borderless:Bool) {
		SDL.setWindowBordered(sdlWindow, borderless);

		return borderless;
	}

	public function setCursor(cursor:ECursor) {
		if (cursor != currentCursor) {
			if (currentCursor == HIDDEN) {
				SDL.showCursor(SDL_ENABLE);
			}

			switch (cursor) {
				case HIDDEN:
					{
						SDL.showCursor(SDL_DISABLE);
					}
				case CROSSHAIR:
					{
						if (Cursor.crosshairCursor == null) {
							Cursor.crosshairCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_CROSSHAIR);
						}
						SDL.setCursor(Cursor.crosshairCursor);
					}
				case MOVE:
					{
						if (Cursor.moveCursor == null) {
							Cursor.moveCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_CROSSHAIR);
						}
						SDL.setCursor(Cursor.moveCursor);
					}
				case POINTER:
					{
						if (Cursor.pointerCursor == null) {
							Cursor.pointerCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_HAND);
						}
						SDL.setCursor(Cursor.pointerCursor);
					}
				case RESIZE_NESW:
					if (Cursor.resizeNESWCursor == null) {
						Cursor.resizeNESWCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_SIZENESW);
					}

					SDL.setCursor(Cursor.resizeNESWCursor);

				case RESIZE_NS:
					if (Cursor.resizeNSCursor == null) {
						Cursor.resizeNSCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_SIZENS);
					}

					SDL.setCursor(Cursor.resizeNSCursor);

				case RESIZE_NWSE:
					if (Cursor.resizeNWSECursor == null) {
						Cursor.resizeNWSECursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_SIZENWSE);
					}

					SDL.setCursor(Cursor.resizeNWSECursor);

				case RESIZE_WE:
					if (Cursor.resizeWECursor == null) {
						Cursor.resizeWECursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_SIZEWE);
					}

					SDL.setCursor(Cursor.resizeWECursor);

				case TEXT:
					if (Cursor.textCursor == null) {
						Cursor.textCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_IBEAM);
					}

					SDL.setCursor(Cursor.textCursor);

				case WAIT:
					if (Cursor.waitCursor == null) {
						Cursor.waitCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_WAIT);
					}

					SDL.setCursor(Cursor.waitCursor);

				case WAIT_ARROW:
					if (Cursor.waitArrowCursor == null) {
						Cursor.waitArrowCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_WAITARROW);
					}

					SDL.setCursor(Cursor.waitArrowCursor);

				default:
					if (Cursor.arrowCursor == null) {
						Cursor.arrowCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_ARROW);
					}

					SDL.setCursor(Cursor.arrowCursor);
			}

			currentCursor = cursor;
		}
	}

	public function setDisplayMode(displaymode:DisplayMode) {
		var pixelFormat = 0;

		switch (displaymode.pixelFormat) {
			case ARGB32:
				{
					pixelFormat = SDL_PIXELFORMAT_ARGB8888;
				}
			case BGRA32:
				{
					pixelFormat = SDL_PIXELFORMAT_BGRA8888;
				}
			default:
				{
					pixelFormat = SDL_PIXELFORMAT_RGBA8888;
				}
		}

		var _mode:SDLDisplayMode = {
			w: displaymode.width,
			h: displaymode.height,
			refresh_rate: displaymode.refreshRate,
			format: pixelFormat
		};

		if (SDL.setWindowDisplayMode(sdlWindow, _mode) == 0) {
			displayModeSet = true;
			if ((SDL.getWindowFlags(sdlWindow) & SDL_WINDOW_FULLSCREEN_DESKTOP) != 0) {
				SDL.setWindowFullscreen(sdlWindow, SDL_WINDOW_FULLSCREEN);
			}
		}
	}

	public function setFullscreen(fullscreen:Bool):Bool {
		if (fullscreen) {
			if (displayModeSet) {
				SDL.setWindowFullscreen(sdlWindow, SDL_WINDOW_FULLSCREEN);
			} else {
				SDL.setWindowFullscreen(sdlWindow, SDL_WINDOW_FULLSCREEN_DESKTOP);
			}
		} else {
			SDL.setWindowFullscreen(sdlWindow, 0);
		}

		return fullscreen;
	}

    public function setIcon(data:haxe.io.BytesData, width:Int, height:Int, depth:Int = 0, pitch:Int = 0){
        var surface = SDL.createRGBSurfaceFrom(data, width, height, depth, pitch,  0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
        if (surface != null) {
			SDL.setWindowIcon(sdlWindow, surface);
			SDL.freeSurface(surface);
		}
    }

	public function setMaximized(maximized:Bool) {
		if (maximized) {
			SDL.maximizeWindow(sdlWindow);
		} else {
			SDL.restoreWindow(sdlWindow);
		}
		return maximized;
	}

	public function setMinimized(minimized:Bool) {
		if (minimized) {
			SDL.minimizeWindow(sdlWindow);
		} else {
			SDL.restoreWindow(sdlWindow);
		}
		return minimized;
	}

	public function setMouseLock(mouseLock:Bool) {
		SDL.setRelativeMouseMode(mouseLock);
	}

	public function setResizable(resizable:Bool):Bool {
		#if emscripten
		SDL.setWindowResizable(sdlWindow, resizable);
		return (SDL.getWindowFlags(sdlWindow) & SDL_WINDOW_RESIZABLE != 0);
		#else
		return resizable;
		#end
	}

	public function setTextInputEnabled(enabled:Bool) {
		if (enabled) {
			SDL.startTextInput();
		} else {
			SDL.stopTextInput();
		}
	}

	public function setTitle(title:String):String {
		SDL.setWindowTitle(sdlWindow, title);
		return title;
	}

	public function warpMouse(x:Int, y:Int) {
		SDL.warpMouseInWindow(sdlWindow, x, y);
	}

	public static function createWindow(application:Application, width:Int, height:Int, flags:Int, title:String):Window {
		return new Window(application, width, height, flags, title);
	}

}
