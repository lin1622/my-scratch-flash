package scratch
{
   import interpreter.PersistenceManager;
   import uiwidgets.DialogBox;
   import uiwidgets.VariableSettings;
   import uiwidgets.VariableSettingsOnline;
   
   public class PaletteBuilderOnline extends PaletteBuilder
   {
       
      
      public function PaletteBuilderOnline(param1:Scratch)
      {
         super(param1);
      }
      
      override protected function createVar(param1:String, param2:VariableSettings) : *
      {
         var app:ScratchOnline = null;
         var name:String = null;
         var settings:VariableSettings = null;
         var varSettings:VariableSettingsOnline = null;
         var callback:Function = null;
         callback = function():void
         {
            name = "☁ " + name;
            var obj:ScratchObj = !!varSettings.isLocal?app.viewedObj():app.stageObj();
            if(obj.hasName(name))
            {
               DialogBox.notify("Cannot Add","That name is already in use.");
               return;
            }
            app.persistentDataCount++;
            if(!app.usesPersistentData)
            {
               app.usesPersistentData = true;
               app.persistenceManager.addEventListener(PersistenceManager.READY,function():void
               {
                  if(settings.isList)
                  {
                     app.persistenceManager.setList(name,[]);
                  }
                  else
                  {
                     app.persistenceManager.createVariable(name);
                  }
               });
               app.persistenceManager.connect(app.serverSettings.cloud_data_host);
            }
            else if(settings.isList)
            {
               app.persistenceManager.setList(name,[]);
            }
            else
            {
               app.persistenceManager.createVariable(name);
            }
         };
         app = null;
         var v:* = undefined;
         name = param1;
         settings = param2;
         varSettings = settings as VariableSettingsOnline;
         app = ScratchOnline.app;
         if(!app.projectId && varSettings.isPersistent)
         {
            app.saveProjectToServer(false,callback);
         }
         else if(app.projectId && varSettings.isPersistent)
         {
            callback();
         }
         else if(!varSettings.isPersistent)
         {
            v = super.createVar(name,varSettings);
            return v;
         }
      }
      
      override protected function makeVarSettings(param1:Boolean, param2:Boolean) : VariableSettings
      {
         return new VariableSettingsOnline(param1,param2,ScratchOnline.app.isLoggedIn(),ScratchOnline.app.isScratcher());
      }
   }
}
