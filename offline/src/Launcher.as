package
{
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Loader;
   import flash.display.LoaderInfo;
   import flash.display.Sprite;
   import flash.display.StageAlign;
   import flash.display.StageQuality;
   import flash.display.StageScaleMode;
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
   import flash.utils.getTimer;

   [SWF(width="940", height="590", frameRate="24", backgroundColor="#000000")]
   public class Launcher extends Sprite
   {
      private var loader:Loader;
      private var hold:LocalHold;
      private var game:Object;
      private var toolbox:Toolbox;
      private var autoMode:Boolean = false;

      private var newGameDone:Boolean = false;
      private var simpleDone:Boolean = false;
      private var startDone:Boolean = false;
      private var saveDone:Boolean = false;
      private var stageDone:Boolean = false;
      private var stageWait:int = 0;
      private var ticks:int = 0;

      private var fpsText:TextField;
      private var fpsFrames:int = 0;
      private var fpsLast:int = 0;

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

         if (config != null)
         {
            toolbox = new Toolbox(config);
            addChild(toolbox);
         }

         applyDisplayOptions();

         if (autoMode)
         {
            var t:Timer = new Timer(1200, 1);
            t.addEventListener(TimerEvent.TIMER, onAutoStart);
            t.start();
         }
      }

      // ---------------- display options ----------------

      private function applyDisplayOptions() : void
      {
         var q:String = loaderInfo.parameters["q"];
         if (q == null) q = "best";
         stage.quality = q;
         stage.scaleMode = StageScaleMode.SHOW_ALL;
         stage.align = StageAlign.TOP_LEFT;

         var smooth:String = loaderInfo.parameters["smooth"];
         if (smooth == "0")
         {
            // 关掉位图平滑，放大时保持像素锐利
            var st:Timer = new Timer(500, 8);
            st.addEventListener(TimerEvent.TIMER, function(ev:TimerEvent):void {
               disableSmoothing(stage);
            });
            st.start();
            disableSmoothing(stage);
         }

         if (loaderInfo.parameters["fps"] != null)
         {
            createFpsMeter();
         }
      }

      private function disableSmoothing(o:DisplayObjectContainer) : void
      {
         var i:int = 0;
         while (i < o.numChildren)
         {
            var c:DisplayObject = o.getChildAt(i);
            if (c is Bitmap)
            {
               (c as Bitmap).smoothing = false;
            }
            if (c is DisplayObjectContainer)
            {
               disableSmoothing(c as DisplayObjectContainer);
            }
            i++;
         }
      }

      private function createFpsMeter() : void
      {
         fpsText = new TextField();
         fpsText.width = 120;
         fpsText.height = 22;
         fpsText.x = stage.stageWidth - 126;
         fpsText.y = 4;
         fpsText.selectable = false;
         fpsText.mouseEnabled = false;
         fpsText.background = true;
         fpsText.backgroundColor = 0x000000;
         fpsText.alpha = 0.7;
         fpsText.textColor = 0x00FF66;
         fpsText.setTextFormat(new TextFormat("Consolas", 14, 0x00FF66));
         addChild(fpsText);
         fpsLast = getTimer();
         addEventListener(Event.ENTER_FRAME, onFpsFrame);
      }

      private function onFpsFrame(e:Event) : void
      {
         fpsFrames++;
         var now:int = getTimer();
         var dt:int = now - fpsLast;
         if (dt >= 1000)
         {
            var fps:Number = fpsFrames * 1000 / dt;
            fpsText.text = "FPS " + fps.toFixed(1) + "  Q:" + stage.quality;
            fpsFrames = 0;
            fpsLast = now;
         }
      }

      // ---------------- auto test driver ----------------

      private function onAutoStart(e:TimerEvent) : void
      {
         var t:Timer = new Timer(900, 120);
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
            if (saveDone && !stageDone)
            {
               stageWait++;
               if (stageWait > 5)
               {
                  var sp:DisplayObject = findByName(stage, "export::SelectPLace");
                  if (loaderInfo.parameters["stay"] != null)
                  {
                     stageDone = true;
                     diag("tick" + ticks + " stayOnMap");
                  }
                  else if (loaderInfo.parameters["tool"] != null)
                  {
                     if (toolbox != null)
                     {
                        toolbox.open();
                        if (loaderInfo.parameters["tooltest"] != null) toolbox.autoTestAdd();
                     }
                     stageDone = true;
                     diag("tick" + ticks + " openToolbox");
                  }
                  else if (sp != null && sp["s1_1"] != null)
                  {
                     sp["s1_1"].dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                     stageDone = true;
                     diag("tick" + ticks + " clickStage s1_1");
                  }
               }
            }
         }
         catch (err:Error)
         {
            diag("tickErr=" + err.message);
         }
      }

      // ---------------- utils ----------------

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
