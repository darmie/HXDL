# HXDL - Haxe DirectMedia Library 
HXDL is a haxe wrapper for SDL, this library provides classes for creating a simple SDL window and application.  It also help manage all known input events. 

HXDL is inspired by [Lime](https://github.com/openfl/lime).


### Dependencies

 * [Haxe](https://haxe.org/)
 * [linc_sdl](https://github.com/zenturi/linc_sdl)
 * [linc_opengl](https://github.com/zenturi/linc_opengl)

Run `haxelib install all` to install the dependencies.


### USAGE
```haxe
import hxdl.Keyboard;
import hxdl.Window;

class Test {
    public static function main(){
        
        var app = new Application();
        var window = new Window(app, 600, 600, WINDOW_FLAG_RESIZABLE | WINDOW_FLAG_HARDWARE | WINDOW_FLAG_ALLOW_HIGHDPI , "My App");
        window.onActivate.add((id:Int)->{
        }, true);

        window.onClose.add((id:Int)->{
            Sys.exit(app.quit());
            window.close();
        }, true);

        var keyboard = new Keyboard();
        keyboard.onKeyDown.add((code:KeyCode, modifier:KeyModifier)->{
            trace({code:code, mod:modifier});
        });

        app.onUpdate.add((time)->{
            trace('update dt: ${time}');
        });

        
       var code =  app.exec();
       app.onExit.dispatch(code);
    } 
}
```


### Todo
1. Vulkan context support

