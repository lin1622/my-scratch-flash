package scratch
{
   import interpreter.Interpreter;
   import interpreter.Variable;
   import uiwidgets.DialogBox;
   
   public class ScratchRuntimeOnline extends ScratchRuntime
   {
       
      
      public function ScratchRuntimeOnline(param1:Scratch, param2:Interpreter)
      {
         super(param1,param2);
      }
      
      override public function deleteVariable(param1:String) : void
      {
         var _loc2_:Variable = app.viewedObj().lookupVar(param1);
         if(_loc2_.isPersistent)
         {
            ScratchOnline.app.persistenceManager.deleteVariable(param1);
            ScratchOnline.app.persistentDataCount--;
            ScratchOnline.app.saveProjectToServer();
         }
         super.deleteVariable(param1);
      }
      
      override public function renameVariable(param1:String, param2:String) : void
      {
         if(param1 == param2)
         {
            return;
         }
         var _loc3_:ScratchObj = app.viewedObj();
         if(!_loc3_.ownsVar(param1))
         {
            _loc3_ = app.stagePane;
         }
         if(_loc3_.hasName(param2))
         {
            DialogBox.notify("Cannot Rename","That name is already in use.");
            return;
         }
         var _loc4_:Variable = app.viewedObj().lookupVar(param1);
         if(_loc4_.isPersistent)
         {
            ScratchOnline.app.persistenceManager.renameVariable(param1,param2);
            ScratchOnline.app.saveProjectToServer();
         }
         super.renameVariable(param1,param2);
      }
      
      override public function updateVariable(param1:Variable) : void
      {
         if(param1.isPersistent)
         {
            ScratchOnline.app.persistenceManager.updateVariable(param1.name,param1.value);
         }
      }
      
      override public function makeVariable(param1:Object) : Variable
      {
         var _loc2_:Variable = super.makeVariable(param1);
         if(param1.isPersistent)
         {
            _loc2_.isPersistent = true;
            ScratchOnline.app.usesPersistentData = true;
            ScratchOnline.app.persistentDataCount++;
         }
         return _loc2_;
      }
   }
}
