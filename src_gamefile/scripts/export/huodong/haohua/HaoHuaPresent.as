package export.huodong.haohua
{
   import export.huodong.miaomiaoBase.MiaoMiaoBaseInterface;
   import flash.events.MouseEvent;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   
   public class HaoHuaPresent extends MiaoMiaoBaseInterface
   {
       
      
      public function HaoHuaPresent()
      {
         super();
      }
      
      override protected function gClick(e:MouseEvent) : void
      {
         navigateToURL(new URLRequest("https://my.4399.com/forums/thread-64526876"),"_blank");
      }
   }
}
