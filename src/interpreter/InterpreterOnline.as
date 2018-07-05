package interpreter
{
   import blocks.Block;
   import flash.external.ExternalInterface;
   import flash.utils.Dictionary;
   import primitives.PrimitivesOnline;
   
   public class InterpreterOnline extends Interpreter
   {
       
      
      private var opCount:uint;
      
      public function InterpreterOnline(param1:ScratchOnline)
      {
         super(param1);
         this.opCount = 0;
         if(ScratchOnline.app.debugOps && ScratchOnline.app.jsEnabled)
         {
            debugFunc = this.debugBlock;
         }
      }
      
      override public function stopAllThreads() : void
      {
         super.stopAllThreads();
         this.opCount = 0;
      }
      
      private function debugBlock(param1:Block) : void
      {
         var _loc2_:Array = param1.args;
         var _loc3_:Array = new Array(_loc2_.length);
         var _loc4_:uint = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc3_[_loc4_] = arg(param1,_loc4_);
            _loc4_++;
         }
         ExternalInterface.call(ScratchOnline.app.debugOpCmd,this.opCount,param1.op,_loc3_);
         this.opCount++;
      }
      
      override protected function primVarSet(param1:Block) : Variable
      {
         var _loc2_:Variable = super.primVarSet(param1);
         if(_loc2_ && _loc2_.isPersistent)
         {
            ScratchOnline.app.persistenceManager.updateVariable(_loc2_.name,_loc2_.value);
         }
         return _loc2_;
      }
      
      override protected function primVarChange(param1:Block) : Variable
      {
         var _loc2_:Variable = super.primVarChange(param1);
         if(_loc2_ && _loc2_.isPersistent)
         {
            ScratchOnline.app.persistenceManager.updateVariable(_loc2_.name,_loc2_.value);
         }
         return _loc2_;
      }
      
      override protected function addOtherPrims(param1:Dictionary) : void
      {
         new PrimitivesOnline(ScratchOnline.app,this).addPrimsTo(param1);
      }
   }
}
