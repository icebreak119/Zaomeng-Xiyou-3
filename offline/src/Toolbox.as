package
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;

   /**
    * 地图界面工具箱：自选全部道具 + DIY 属性。
    * 通过反射访问游戏类（Config / MyEquipObj），由 Launcher 注入。
    */
   public class Toolbox extends Sprite
   {
      private static const W:Number = 920;
      private static const H:Number = 580;

      private var gc:Object;
      private var btn:Sprite;
      private var panel:Sprite;
      private var listLayer:Sprite;
      private var searchTf:TextField;
      private var statusTf:TextField;
      private var pageTf:TextField;
      private var detailTf:TextField;
      private var rowSprites:Array = [];
      private var tabButtons:Array = [];

      private var allItems:Array = [];
      private var viewItems:Array = [];
      private var page:int = 0;
      private var pageSize:int = 11;
      private var cat:String = "all";
      private var selected:Object = null;
      private var inputs:Object = {};
      private var built:Boolean = false;
      private var lastMap:Boolean = false;

      private static const CATS:Array = [
         ["all", "全部"], ["weapon", "武器"], ["armor", "防具"], ["acc", "饰品"], ["other", "其他"]
      ];

      private static const FIELDS:Array = [
         ["eatt", "攻击", "int"], ["edef", "防御", "int"],
         ["ehp", "生命", "int"], ["emp", "魔法", "int"],
         ["ecrit", "暴击", "num"], ["emiss", "闪避", "num"],
         ["eahp", "回血", "int"], ["eamp", "回蓝", "int"],
         ["eatblood", "吸血", "num"], ["magicdef", "魔抗", "num"],
         ["deephit", "穿透", "num"], ["num", "数量", "int"]
      ];

      public function Toolbox(config:Object)
      {
         gc = config;
         addEventListener(Event.ADDED_TO_STAGE, onAdded);
      }

      private function onAdded(e:Event) : void
      {
         removeEventListener(Event.ADDED_TO_STAGE, onAdded);
         buildButton();
         buildPanel();
         layout();
         stage.addEventListener(Event.RESIZE, onResize);

         var t:Timer = new Timer(500);
         t.addEventListener(TimerEvent.TIMER, onTick);
         t.start();
      }

      private function onResize(e:Event) : void
      {
         layout();
      }

      private function layout() : void
      {
         if (btn != null)
         {
            btn.x = stage.stageWidth - 104;
            btn.y = stage.stageHeight - 40;
         }
         if (panel != null)
         {
            panel.x = Math.round((stage.stageWidth - W) / 2);
            panel.y = Math.round((stage.stageHeight - H) / 2);
         }
      }

      private function onTick(e:TimerEvent) : void
      {
         var onMap:Boolean = findByName(stage, "export::SelectPLace") != null;
         if (onMap != lastMap)
         {
            lastMap = onMap;
            btn.visible = onMap;
            if (!onMap && panel.visible)
            {
               panel.visible = false;
            }
         }
         if (onMap && !btn.visible)
         {
            btn.visible = true;
         }
      }

      // ---------------- button ----------------

      private function buildButton() : void
      {
         btn = new Sprite();
         btn.graphics.beginFill(0x0d2b45, 0.92);
         btn.graphics.lineStyle(1, 0x59d1ff, 0.9);
         btn.graphics.drawRoundRect(0, 0, 94, 30, 8, 8);
         btn.graphics.endFill();
         var tf:TextField = makeText(13, 0x9fe8ff, true);
         tf.text = "工具箱";
         tf.width = 94;
         tf.height = 20;
         tf.y = 5;
         tf.x = 0;
         tf.selectable = false;
         tf.mouseEnabled = false;
         tf.setTextFormat(new TextFormat("SimHei", 14, 0x9fe8ff, true));
         btn.addChild(tf);
         btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { toggle(); });
         btn.visible = false;
         addChild(btn);
      }

      public function open() : void
      {
         if (!panel.visible) toggle();
      }

      private function toggle() : void
      {
         if (panel.visible)
         {
            panel.visible = false;
            return;
         }
         if (!built)
         {
            buildItems();
            built = true;
         }
         panel.visible = true;
         applyFilter();
         if (allItems.length == 0)
         {
            status("没有读到道具列表", 0xff6666);
         }
      }

      // ---------------- panel ----------------

      private function buildPanel() : void
      {
         panel = new Sprite();
         panel.visible = false;

         var bg:Shape = new Shape();
         bg.graphics.beginFill(0x121820, 0.97);
         bg.graphics.lineStyle(2, 0x4a90d9, 1);
         bg.graphics.drawRoundRect(0, 0, W, H, 12, 12);
         bg.graphics.endFill();
         panel.addChild(bg);

         var title:TextField = makeText(20, 0x7fd6ff, true);
         title.text = "造梦西游3 工具箱 —— 自选道具 / DIY 属性";
         title.x = 24;
         title.y = 14;
         title.width = 600;
         panel.addChild(title);

         var hint:TextField = makeText(12, 0x8fa3b8, false);
         hint.text = "选择左侧道具 → 修改右侧属性 → 加入背包（自动保存）";
         hint.x = 24;
         hint.y = 44;
         hint.width = 700;
         panel.addChild(hint);

         // tabs
         var x:int = 24;
         for (var i:int = 0; i < CATS.length; i++)
         {
            var tb:Sprite = makeTab(CATS[i][1], CATS[i][0]);
            tb.x = x;
            tb.y = 70;
            x += 92;
            tabButtons.push(tb);
            panel.addChild(tb);
         }

         var sLabel:TextField = makeText(13, 0xcfd8e3, false);
         sLabel.text = "搜索";
         sLabel.x = 24;
         sLabel.y = 107;
         sLabel.width = 40;
         panel.addChild(sLabel);

         searchTf = new TextField();
         searchTf.type = TextFieldType.INPUT;
         searchTf.border = true;
         searchTf.background = true;
         searchTf.backgroundColor = 0x0a1018;
         searchTf.textColor = 0xffffff;
         searchTf.borderColor = 0x33506b;
         searchTf.x = 70;
         searchTf.y = 104;
         searchTf.width = 240;
         searchTf.height = 24;
         searchTf.setTextFormat(new TextFormat("SimHei", 13, 0xffffff));
         searchTf.addEventListener(Event.CHANGE, function(e:Event):void { page = 0; applyFilter(); });
         panel.addChild(searchTf);

         listLayer = new Sprite();
         listLayer.x = 24;
         listLayer.y = 140;
         panel.addChild(listLayer);

         // page controls
         var prev:Sprite = makeButton("< 上页", 84, 26, function(e:MouseEvent):void { turnPage(-1); });
         prev.x = 24;
         prev.y = 522;
         panel.addChild(prev);

         pageTf = makeText(12, 0xcfd8e3, false);
         pageTf.x = 120;
         pageTf.y = 526;
         pageTf.width = 120;
         panel.addChild(pageTf);

         var next:Sprite = makeButton("下页 >", 84, 26, function(e:MouseEvent):void { turnPage(1); });
         next.x = 240;
         next.y = 522;
         panel.addChild(next);

         // right side
         detailTf = makeText(14, 0xffd166, true);
         detailTf.x = 570;
         detailTf.y = 108;
         detailTf.width = 330;
         detailTf.height = 48;
         detailTf.multiline = true;
         detailTf.wordWrap = true;
         detailTf.text = "请选择左侧道具";
         panel.addChild(detailTf);

         var fy:int = 164;
         for (var j:int = 0; j < FIELDS.length; j++)
         {
            var f:Array = FIELDS[j];
            var col:int = j % 2;
            var row:int = int(j / 2);
            createField(f[0], f[1], 570 + col * 172, 164 + row * 44, 60, 96);
         }

         var addBtn:Sprite = makeButton("加入背包", 108, 30, function(e:MouseEvent):void { addSelected(); });
         addBtn.x = 570;
         addBtn.y = 470;
         panel.addChild(addBtn);

         var resetBtn:Sprite = makeButton("模板重置", 108, 30, function(e:MouseEvent):void { fillFromTemplate(); });
         resetBtn.x = 688;
         resetBtn.y = 470;
         panel.addChild(resetBtn);

         var saveBtn:Sprite = makeButton("立即保存", 108, 30, function(e:MouseEvent):void { saveNow(); status("已保存"); });
         saveBtn.x = 570;
         saveBtn.y = 510;
         panel.addChild(saveBtn);

         var closeBtn:Sprite = makeButton("关闭", 108, 30, function(e:MouseEvent):void { panel.visible = false; });
         closeBtn.x = 688;
         closeBtn.y = 510;
         panel.addChild(closeBtn);

         statusTf = makeText(13, 0x7CFC9A, false);
         statusTf.x = 24;
         statusTf.y = 552;
         statusTf.width = 600;
         panel.addChild(statusTf);

         addChild(panel);
      }

      private function makeTab(label:String, key:String) : Sprite
      {
         var s:Sprite = new Sprite();
         s.graphics.beginFill(0x1d2a38, 1);
         s.graphics.lineStyle(1, 0x33506b, 1);
         s.graphics.drawRoundRect(0, 0, 84, 28, 6, 6);
         s.graphics.endFill();
         var tf:TextField = makeText(13, 0xbcd6ea, false);
         tf.text = label;
         tf.width = 84;
         tf.height = 20;
         tf.y = 4;
         tf.selectable = false;
         tf.mouseEnabled = false;
         tf.setTextFormat(new TextFormat("SimHei", 13, 0xbcd6ea, false, false, false, null, null, "center"));
         s.addChild(tf);
         s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
            cat = key;
            page = 0;
            applyFilter();
         });
         return s;
      }

      private function makeButton(label:String, w:Number, h:Number, handler:Function) : Sprite
      {
         var s:Sprite = new Sprite();
         s.graphics.beginFill(0x1b4a7a, 1);
         s.graphics.lineStyle(1, 0x59d1ff, 0.9);
         s.graphics.drawRoundRect(0, 0, w, h, 6, 6);
         s.graphics.endFill();
         var tf:TextField = makeText(13, 0xeaf6ff, true);
         tf.text = label;
         tf.width = w;
         tf.height = 18;
         tf.y = (h - 18) / 2;
         tf.selectable = false;
         tf.mouseEnabled = false;
         tf.setTextFormat(new TextFormat("SimHei", 13, 0xeaf6ff, true, false, false, null, null, "center"));
         s.addChild(tf);
         s.addEventListener(MouseEvent.CLICK, handler);
         return s;
      }

      private function createField(key:String, label:String, x:int, y:int, lw:int, iw:int) : void
      {
         var lt:TextField = makeText(13, 0xcfd8e3, false);
         lt.text = label;
         lt.x = x;
         lt.y = y + 3;
         lt.width = lw;
         panel.addChild(lt);

         var tf:TextField = new TextField();
         tf.type = TextFieldType.INPUT;
         tf.border = true;
         tf.background = true;
         tf.backgroundColor = 0x0a1018;
         tf.textColor = 0xffffff;
         tf.borderColor = 0x33506b;
         tf.x = x + lw;
         tf.y = y;
         tf.width = iw;
         tf.height = 22;
         tf.restrict = "0-9.\\-";
         tf.setTextFormat(new TextFormat("Consolas", 13, 0xffffff));
         tf.text = "0";
         panel.addChild(tf);
         inputs[key] = tf;
      }

      // ---------------- data ----------------

      private function buildItems() : void
      {
         allItems = [];
         var seen:Object = {};
         try
         {
            var ae:Object = gc.allEquip;
            var arrs:Array = [ae.otherEquipment, ae.wpEquipment, ae.sutraEquipment, ae.sellEquipment];
            for (var i:int = 0; i < arrs.length; i++)
            {
               var arr:Array = arrs[i] as Array;
               if (arr == null) continue;
               for (var j:int = 0; j < arr.length; j++)
               {
                  var eq:Object = arr[j];
                  if (eq == null) continue;
                  var fill:String = "";
                  try { fill = eq.getFillName(); } catch (e1:Error) { continue; }
                  if (fill == null || fill == "" || seen[fill] == true) continue;
                  seen[fill] = true;
                  allItems.push({eq: eq, name: String(eq.ename), fill: fill, type: String(eq.type)});
               }
            }
         }
         catch (e2:Error)
         {
            trace("buildItems error " + e2);
         }
         allItems.sort(function(a:Object, b:Object):Number {
            return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0);
         });
      }

      private function applyFilter() : void
      {
         viewItems = [];
         var q:String = searchTf != null ? String(searchTf.text).toLowerCase() : "";
         for (var i:int = 0; i < allItems.length; i++)
         {
            var it:Object = allItems[i];
            if (!matchCat(it.type)) continue;
            if (q != "" && (it.name.toLowerCase().indexOf(q) < 0 && it.fill.toLowerCase().indexOf(q) < 0)) continue;
            viewItems.push(it);
         }
         page = 0;
         renderList();
      }

      private function matchCat(t:String) : Boolean
      {
         if (cat == "all") return true;
         if (cat == "weapon") return t == "zbwq";
         if (cat == "armor") return t == "zbfj" || t == "zbfb";
         if (cat == "acc") return t == "zbsp";
         return !(t == "zbwq" || t == "zbwp" || t == "zbfj" || t == "zbfb" || t == "zbsp");
      }

      private function turnPage(d:int) : void
      {
         var maxPage:int = Math.max(0, Math.ceil(viewItems.length / pageSize) - 1);
         page = Math.min(maxPage, Math.max(0, page + d));
         renderList();
      }

      private function renderList() : void
      {
         // 清空
         while (listLayer.numChildren > 0) listLayer.removeChildAt(0);
         rowSprites = [];

         var start:int = page * pageSize;
         var end:int = Math.min(viewItems.length, start + pageSize);
         for (var i:int = start; i < end; i++)
         {
            var it:Object = viewItems[i];
            var row:Sprite = new Sprite();
            row.y = (i - start) * 34;
            row.graphics.beginFill(0x18222e, 1);
            row.graphics.lineStyle(1, 0x2b3d52, 1);
            row.graphics.drawRect(0, 0, 520, 30);
            row.graphics.endFill();
            if (selected != null && selected.fill == it.fill)
            {
               row.graphics.beginFill(0x1b4a7a, 1);
               row.graphics.drawRect(0, 0, 520, 30);
               row.graphics.endFill();
            }

            var name:String = it.name != "" ? it.name : it.fill;
            var tf:TextField = makeText(13, 0xdfe8f2, false);
            tf.text = name + "   (" + it.fill + " / " + it.type + ")";
            tf.x = 8;
            tf.y = 6;
            tf.width = 500;
            tf.selectable = false;
            tf.mouseEnabled = false;
            row.addChild(tf);

            row.addEventListener(MouseEvent.CLICK, (function(item:Object):Function {
               return function(e:MouseEvent):void { selectItem(item); };
            })(it));
            row.buttonMode = true;
            listLayer.addChild(row);
            rowSprites.push(row);
         }

         var maxPage:int = Math.max(1, Math.ceil(viewItems.length / pageSize));
         pageTf.text = "第 " + (page + 1) + " / " + maxPage + " 页   共 " + viewItems.length + " 项";
      }

      private function selectItem(it:Object) : void
      {
         selected = it;
         renderList();
         var t:Object = it.eq;
         detailTf.text = it.name + "\n类型: " + it.type + "   职业: " + (t.user != "" ? t.user : "通用") + "\n模板: " + it.fill;
         fillFromTemplate();
      }

      private function fillFromTemplate() : void
      {
         if (selected == null) return;
         var t:Object = selected.eq;
         setIn("eatt", t.geteatt(true));
         setIn("edef", t.getedef(true));
         setIn("ehp", t.getehp(true));
         setIn("emp", t.getemp(true));
         setIn("ecrit", trim(t.getecrit(true)));
         setIn("emiss", trim(t.getemiss(true)));
         setIn("eahp", t.geteahp(true));
         setIn("eamp", t.geteamp(true));
         setIn("eatblood", trim(t.geteatblood(true)));
         setIn("magicdef", trim(t.getmagicdef(true)));
         setIn("deephit", trim(t.getdeephit(true)));
         setIn("num", 1);
      }

      private function trim(n:Number) : String
      {
         return String(Math.round(n * 1000) / 1000);
      }

      private function setIn(key:String, v:Object) : void
      {
         var tf:TextField = inputs[key] as TextField;
         if (tf != null) tf.text = String(v);
      }

      private function getNum(key:String, isInt:Boolean) : Number
      {
         var tf:TextField = inputs[key] as TextField;
         if (tf == null) return 0;
         var v:Number = isInt ? int(parseInt(tf.text)) : parseFloat(tf.text);
         if (isNaN(v)) v = 0;
         return v;
      }

      // ---------------- add / save ----------------

      private function addSelected() : void
      {
         if (selected == null)
         {
            status("请先选择一个道具", 0xffb86b);
            return;
         }
         try
         {
            var t:Object = selected.eq;
            var C:Class = getDefinitionByName("my.MyEquipObj") as Class;
            var eq:Object = new C(
               t.showid, t.ename, selected.fill, t.type, t.user, t.quality, t.color,
               getNum("ehp", true), getNum("emp", true), getNum("eatt", true), getNum("edef", true),
               getNum("ecrit", false), getNum("emiss", false), getNum("eahp", true), getNum("eamp", true),
               getNum("eatblood", false), getNum("magicdef", false), getNum("deephit", false),
               t.aStrengthen, t.instruction, null, null, t.getMutiLevel()
            );
            try { eq.setELevel(t.getELevel()); } catch (e3:Error) { }
            try { eq.setEupdata(t.getEUpdata()); } catch (e4:Error) { }
            var cnt:int = getNum("num", true);
            if (cnt < 1) cnt = 1;

            var p:Object = gc.player1;
            var cls:String = getQualifiedClassName(eq);
            if (cls.indexOf("PetEquipObj") >= 0)
            {
               p.plist.push(eq);
            }
            else if (eq.type == "zbsz")
            {
               p.szlist.push(eq);
            }
            else if (eq.type == "wpqhs" || eq.type == "zbwp")
            {
               gc.putQhsInBackPack(p, selected.fill, cnt);
            }
            else
            {
               try { eq.setnum(cnt); } catch (e5:Error) { }
               p.zblist.push(eq);
            }

            saveNow();
            status("已添加 " + selected.name + " ×" + cnt + "，已写入存档", 0x7CFC9A);
         }
         catch (err:Error)
         {
            status("添加失败: " + err.message, 0xff6666);
         }
      }

      private function saveNow() : void
      {
         try
         {
            gc.memory.setStorage(gc.luanqibazaojiami.saveId);
         }
         catch (e:Error)
         {
            trace("save fail " + e);
         }
      }

      private function status(msg:String, color:uint = 0x7CFC9A) : void
      {
         if (statusTf == null) return;
         statusTf.text = msg;
         statusTf.setTextFormat(new TextFormat("SimHei", 13, color));
      }

      public function autoTestAdd() : void
      {
         for (var i:int = 0; i < allItems.length; i++)
         {
            var it:Object = allItems[i];
            var eq:Object = it.eq;
            if (eq.geteatt(true) > 0 && (it.type == "zbwq" || it.type == "zbfj"))
            {
               selectItem(it);
               setIn("eatt", 8888);
               setIn("edef", 888);
               setIn("ehp", 8888);
               setIn("emp", 888);
               setIn("ecrit", 0.5);
               setIn("emiss", 0.2);
               setIn("eatblood", 0.1);
               addSelected();
               return;
            }
         }
         status("找不到可测试的装备", 0xff6666);
      }

      // ---------------- utils ----------------

      private function makeText(size:Number, color:uint, bold:Boolean) : TextField
      {
         var tf:TextField = new TextField();
         tf.selectable = false;
         tf.multiline = false;
         tf.textColor = color;
         tf.setTextFormat(new TextFormat("SimHei", size, color, bold));
         return tf;
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
   }
}
