package
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Loader;
   import flash.display.LoaderInfo;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;

   [SWF(width="940", height="590", frameRate="24", backgroundColor="#000000")]
   public class Launcher extends Sprite
   {
      private var loader:Loader;
      private var hold:LocalHold;
      private var game:Object;
      private var autoMode:Boolean = false;

      private var newGameDone:Boolean = false;
      private var simpleDone:Boolean = false;
      private var startDone:Boolean = false;
      private var saveDone:Boolean = false;
      private var ticks:int = 0;

      public function Launcher()
      {
         addEventListener(Event.ADDED_TO_STAGE, onAdded);
      }

      private function onAdded(e:Event) : void
      {
         removeEventListener(Event.ADDED_TO_STAGE, onAdded);
         autoMode = loaderInfo.parameters["auto"] != null;
         loader = new Loader();
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
         var ctx:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
         loader.load(new URLRequest("gamefile.swf"), ctx);
      }

      private function onIoError(e:IOErrorEvent) : void
      {
         var tf:TextField = new TextField();
         tf.text = "无法加载 gamefile.swf，请确认它和启动器在同一目录。\n" + e.text;
         tf.textColor = 0xFFFFFF;
         tf.setTextFormat(new TextFormat("SimHei", 18));
         tf.width = 900;
         tf.height = 200;
         tf.x = 20;
         tf.y = 200;
         addChild(tf);
      }

      private function onLoaded(e:Event) : void
      {
         game = LoaderInfo(e.target).content;
         var config:Object = findConfig();
         hold = new LocalHold(stage, config);
         if (config != null)
         {
            try { config.logInfo = hold.isLog; } catch (err:Error) { }
         }
         try { game.setHold(hold); } catch (err2:Error) { trace("setHold failed: " + err2); }
         addChild(game as DisplayObject);
         if (autoMode)
         {
            var t:Timer = new Timer(1200, 1);
            t.addEventListener(TimerEvent.TIMER, onAutoStart);
            t.start();
         }
      }

      private function onAutoStart(e:TimerEvent) : void
      {
         var t:Timer = new Timer(900, 80);
         t.addEventListener(TimerEvent.TIMER, onTick);
         t.start();
      }

      private function onTick(e:TimerEvent) : void
      {
         ticks++;
         try
         {
            var menu:DisplayObject = findByName(stage, "export::GameMenu");
            if (menu != null)
            {
               if (!newGameDone)
               {
                  menu["newGame"].dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                  newGameDone = true;
                  diag("tick" + ticks + " newGame");
               }
               else if (!simpleDone && menu["simpleGame"].visible)
               {
                  menu["simpleGame"].dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                  simpleDone = true;
                  diag("tick" + ticks + " simpleGame");
               }
            }
            if (simpleDone && !startDone)
            {
               var sr:DisplayObject = findByName(stage, "export::SelectRole");
               if (sr != null && sr["startBtn"] != null)
               {
                  sr["btn1"].dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                  sr["startBtn"].dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                  startDone = true;
                  diag("tick" + ticks + " startGame");
               }
            }
            var ct:DisplayObject = findByName(stage, "export.cartoon::GameCartoon");
            if (ct != null)
            {
               ct.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            }
            if (startDone && !saveDone)
            {
               var si:DisplayObject = findByName(stage, "export.saveInterface::SaveInter");
               if (si != null && si["btn_1"] != null)
               {
                  si["btn_1"].dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                  saveDone = true;
                  diag("tick" + ticks + " saveSlot");
               }
            }
            if (ticks == 75)
            {
               diag("tree:" + dumpTree(stage, 0));
            }
         }
         catch (err:Error)
         {
            diag("tickErr=" + err.message);
         }
      }

      private function dumpTree(o:DisplayObjectContainer, depth:int) : String
      {
         if (depth > 6) return "";
         var s:String = "";
         var i:int = 0;
         while (i < o.numChildren)
         {
            var c:DisplayObject = o.getChildAt(i);
            var cn:String = getQualifiedClassName(c);
            s += "|" + cn;
            if (c is DisplayObjectContainer)
            {
               var sub:String = dumpTree(c as DisplayObjectContainer, depth + 1);
               if (sub.length > 3000) sub = sub.substring(0, 3000);
               s += sub;
            }
            i++;
         }
         return s;
      }

      private function findByName(o:DisplayObjectContainer, className:String) : DisplayObject
      {
         var i:int = 0;
         while (i < o.numChildren)
         {
            var c:DisplayObject = o.getChildAt(i);
            if (getQualifiedClassName(c) == className) return c;
            if (c is DisplayObjectContainer)
            {
               var r:DisplayObject = findByName(c as DisplayObjectContainer, className);
               if (r != null) return r;
            }
            i++;
         }
         return null;
      }

      private function diag(msg:String) : void
      {
         try
         {
            var r:URLRequest = new URLRequest("http://127.0.0.1:8765/diag?m=" + encodeURIComponent(msg));
            var l:Loader = new Loader();
            l.load(r);
         }
         catch (e:Error) { }
      }

      private function findConfig() : Object
      {
         try
         {
            var c:Class = getDefinitionByName("config.Config") as Class;
            return c.getInstance();
         }
         catch (err:Error)
         {
            trace("Config not found: " + err);
         }
         return null;
      }
   }
}
