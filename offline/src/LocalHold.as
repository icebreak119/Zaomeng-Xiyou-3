package
{
   import flash.display.Stage;
   import flash.net.SharedObject;
   import flash.utils.setTimeout;
   import flash.net.URLRequest;
   import flash.events.Event;
   import flash.display.Loader;

   /**
    * Offline replacement for the 4399 platform "hold" object.
    * GMain.serviceHold expects an object with the 4399 save/pay/union API;
    * everything except save/load is a harmless no-op here.
    */
   public class LocalHold
   {
      private var st:Stage;
      private var gc:Object;
      private var so:SharedObject;
      private var logInfo:Object;
      private var slotCount:int = 6;

      public function LocalHold(stage:Stage, config:Object)
      {
         st = stage;
         gc = config;
         so = SharedObject.getLocal("zmxy3_offline");
         if (!so.data.slots) so.data.slots = {};
         logInfo = {uid: 243377837, name: "local", nickName: "本地玩家", status: 0};
      }

      /* ---------- account ---------- */

      public function get isLog() : Object
      {
         return logInfo;
      }

      public function get isSecondaryLog() : Object
      {
         return null;
      }

      public function showLogPanel() : void {}
      public function showSecondaryLogPanel() : void {}
      public function secondaryLogOut() : void {}

      public function userLogOut() : void
      {
         later(function():void { st.dispatchEvent(new Evt("userLoginOut", null)); });
      }

      /* ---------- save / load ---------- */

      public function getData(ui:Boolean = true, index:int = 0) : void
      {
         var rec:Object = so.data.slots[String(index)];
         later(function():void { st.dispatchEvent(new Evt("getuserdata", {index: index, data: rec ? rec.data : null})); });
      }

      public function getSecondaryData(index:int = 0) : void
      {
         later(function():void { st.dispatchEvent(new Evt("getuserdata", {index: index, data: null})); });
      }

      public function saveData(title:String, data:Object, ui:Boolean = true, index:int = 0) : void
      {
         if (index < 0) index = 0;
         var now:String = timeString();
         var rec:Object = {title: title, datetime: now, data: data};
         so.data.slots[String(index)] = rec;
         so.data["title_" + index] = title;
         so.data["date_" + index] = now;
         try { so.flush(); } catch (e:Error) { }
         diag("save: isnew=" + gc.isnew + " logInfo=" + (gc.logInfo != null) + " saveInter=" + (gc.saveInter != null) + " lij=" + (gc.luanqibazaojiami != null) + " idx=" + index);
         later(function():void {
            st.dispatchEvent(new Evt("saveuserdata", true));
            cleanupSave();
         });
      }

      public function saveSecondaryData(title:String, data:Object, index:int = 0) : void
      {
         later(function():void { st.dispatchEvent(new Evt("saveuserdata", true)); });
      }

      public function getList() : void
      {
         later(function():void { st.dispatchEvent(new Evt("getuserdatalist", buildList())); });
      }

      public function getSecondarySaveList() : void
      {
         later(function():void { st.dispatchEvent(new Evt("getuserdatalist", [])); });
      }

      public function openSaveUI(title:String, data:Object) : void {}

      private function buildList() : Array
      {
         var list:Array = [];
         var i:int = 0;
         while (i < slotCount)
         {
            var rec:Object = so.data.slots[String(i)];
            if (rec)
            {
               list.push({index: i, title: rec.title, datetime: rec.datetime, status: 0});
            }
            i++;
         }
         return list;
      }

      /* ---------- time / score ---------- */

      public function getServerTime() : void
      {
         later(function():void { st.dispatchEvent(new Evt("serverTimeEvent", timeString())); });
      }

      public function changeScore(v:int) : void {}
      public function submitScore(v:int) : void {}

      /* ---------- shop / pay ---------- */

      public function getBalance() : void {}
      public function getStoreState() : void {}
      public function showShopUi() : void {}
      public function getPackageInfoFun(...args) : void {}
      public function getFreePacInfoFun(...args) : void {}
      public function getPayPacInfoFun(...args) : void {}
      public function buyProFun(...args) : void {}
      public function modifyExFun(...args) : void {}
      public function clearItemsByExTypeFun(...args) : void {}
      public function removeItemsFun(...args) : void {}
      public function consumeItemFun(...args) : void {}
      public function addItemsFun(...args) : void {}
      public function updateItemProFun(...args) : void {}
      public function getShopItemsFun(...args) : void {}
      public function getShopList() : void {}
      public function buyPropNd(...args) : void {}
      public function incMoney_As3(...args) : void {}
      public function decMoney_As3(...args) : void {}
      public function decMoney_statistic(...args) : void {}
      public function getTotalPaiedFun(...args) : void {}
      public function getTotalRechargedFun(...args) : void {}
      public function payMoney_As3(...args) : void {}
      public function set _exValue(v:Array) : void {}

      /* ---------- rank ---------- */

      public function getOneRankInfo(...args) : void {}
      public function getRankListByOwn(...args) : void {}
      public function submitScoreToRankLists(...args) : void {}
      public function getRankListsData(...args) : void {}
      public function getUserData(...args) : void {}

      /* ---------- union (all offline no-ops) ---------- */

      public function unionCreate(...args) : void {}
      public function getUnionList(...args) : void {}
      public function applyUnion(...args) : void {}
      public function getOwnUnion(...args) : void {}
      public function getUnionDetail(...args) : void {}
      public function getUnionMembers(...args) : void {}
      public function getUnionLog(...args) : void {}
      public function quitUion(...args) : void {}
      public function doTask(...args) : void {}
      public function doExchange(...args) : void {}
      public function getTaskValue(...args) : void {}
      public function getApplyList(...args) : void {}
      public function auditMember(...args) : void {}
      public function removeMember(...args) : void {}
      public function dissolveUnion(...args) : void {}
      public function getVariables(...args) : void {}
      public function doVariable(...args) : void {}
      public function getRoleList(...args) : void {}
      public function setRole(...args) : void {}
      public function usePersonalContribution(...args) : void {}
      public function useUnionContribution(...args) : void {}
      public function applyMultiAudit(...args) : void {}
      public function transferUnion(...args) : void {}
      public function setMemberExtra(...args) : void {}
      public function setUnionExtra(...args) : void {}
      public function setRoleRevised(...args) : void {}
      public function setMemberExtraRevised(...args) : void {}
      public function auditMemberRevised(...args) : void {}
      public function removeMemberRevised(...args) : void {}
      public function transferUnionRevised(...args) : void {}

      /* ---------- misc ---------- */

      public function setMouseVisible(v:Boolean) : void {}
      public function showGameList() : void {}
      public function setFocusManager() : void {}

      private function cleanupSave() : void
      {
         try { gc.isnew = false; } catch (e1:Error) { }
         try
         {
            if (gc.saveInter != null && gc.saveInter.parent != null)
            {
               gc.saveInter.parent.removeChild(gc.saveInter);
            }
         }
         catch (e2:Error) { }
         try
         {
            var m:* = st.getChildByName("SavingGameMask");
            if (m != null) st.removeChild(m);
            var m2:* = gc.saveInter != null ? gc.saveInter.getChildByName("SavingGameMask") : null;
            if (m2 != null) gc.saveInter.removeChild(m2);
         }
         catch (e3:Error) { }
         try { gc.eventManger.dispatchEvent(new Event("SAVESEVENTSUCCESS")); } catch (e4:Error) { }
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

      private function later(fn:Function) : void
      {
         setTimeout(fn, 40);
      }

      private function timeString() : String
      {
         var d:Date = new Date();
         return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
            + " " + pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds());
      }

      private function pad(n:int) : String
      {
         return n < 10 ? "0" + n : "" + n;
      }
   }
}
