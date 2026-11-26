package
{
   import flash.events.Event;

   /**
    * Minimal stand-in for unit4399.events.SaveEvent.
    * The game dispatches/listens by event *type string*, so a custom class
    * with the same `data` / `ret` accessors is enough.
    */
   public class Evt extends Event
   {
      public var _d:Object;

      public function Evt(type:String, data:Object)
      {
         super(type);
         _d = data;
      }

      public function get data() : Object
      {
         return _d;
      }

      public function get ret() : Object
      {
         return _d;
      }

      override public function clone() : Event
      {
         return new Evt(type, _d);
      }
   }
}
