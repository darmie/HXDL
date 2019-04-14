import hxdl.KeyModifier;
import hxdl.KeyCode;
import hxdl.Application;
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