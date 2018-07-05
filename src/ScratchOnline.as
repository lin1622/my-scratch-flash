package
{
   import flash.external.ExternalInterface;
   import interpreter.InterpreterOnline;
   import interpreter.PersistenceManager;
   import scratch.PaletteBuilder;
   import scratch.PaletteBuilderOnline;
   import scratch.ScratchRuntimeOnline;
   import translation.Translator;
   
   public class ScratchOnline extends Scratch
   {
      
      public static var app:ScratchOnline;
       
      
      public var persistenceManager:PersistenceManager;
      
      public var persistentDataCount:int = 0;
      
      public var serverSettings:Object;
      
      public var usesPersistentData:Boolean;
      
      public function ScratchOnline()
      {
         this.serverSettings = {};
         super();
      }
      
      override protected function initialize() : void
      {
         Scratch.app = ScratchOnline.app = this;
//         this.persistenceManager = new PersistenceManager(this);
         this.getServerSettings();
         super.initialize();
      }
      
      override protected function initInterpreter() : void
      {
         interp = new InterpreterOnline(this);
      }
      
      override protected function initRuntime() : void
      {
         runtime = new ScratchRuntimeOnline(this,interp);
      }
      
//      override public function getPaletteBuilder() : PaletteBuilder
//      {
//         return new PaletteBuilderOnline(this);
//      }
      
      override public function projectLoaded() : void
      {
         super.projectLoaded();
         if(this.usesPersistentData)
         {
            if(this.isLoggedIn() && app.projectId)
            {
               this.persistenceManager.connect(this.serverSettings.cloud_data_host);
            }
            else
            {
               this.jsSetProjectBanner("This project uses Cloud data ‒ a feature that is available only to signed in users.");
            }
         }
      }
      
      public function isCloudDataEnabled() : Boolean
      {
         return false;
      }
      
      public function jsSetProjectBanner(param1:String, param2:Boolean = false) : void
      {
         if(jsEnabled){
            ExternalInterface.call("JSsetProjectBanner",Translator.map(param1),param2);
         }
      }
      
      public function isUserStaff() : Boolean
      {
         if(!this.serverSettings)
         {
            return false;
         }
         return this.serverSettings.user_admin;
      }
      
      public function isLoggedIn() : Boolean
      {
         return this.isLogin;
      }
      
      public function isScratcher() : Boolean
      {
         return this.isLoggedIn();
      }
      
      private function getServerSettings() : void
      {
         this.serverSettings.cloud_data_host = loaderInfo.parameters["cloud_data_host"];
      }
   }
}
