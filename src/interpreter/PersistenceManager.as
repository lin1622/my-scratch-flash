package interpreter
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.external.ExternalInterface;
   import flash.utils.setTimeout;
   import logging.LogLevel;
   import scratch.ScratchObj;
   import translation.Translator;
   import watchers.ListWatcher;
   import util.*;
   
   public class PersistenceManager extends EventDispatcher
   {
      
      public static var READY:String = "ready";
      
      private static const NULL_CLOUD_TOKEN:String = "00000000-0000-0000-0000-000000000000";
      
      private static const cloudInfo:String = "<b>Information about Cloud variables</b>" + "<br>&nbsp;<br>" + "Currently, only numbers are supported<br>" + "Chat rooms are not allowed, and will be removed<br>" + "For more info, see the cloud data FAQ!";
      
      private static const notProjectOwnerWarning:String = "You cannot edit cloud data in someone else\'s project.<br>" + "Any change that you make in the editor will be temporary and not persistent.";
      
      private static const numberWarning:String = "Currently, only numbers can be stored in Cloud variables.";
       
      
      public var ready:Boolean = false;
      
      private var app:ScratchOnline;
      
      private var server:String = "http://cloud.kada.163.com/cloud";
      
      private var decayTimeout:Number = 1000;
      
      private var connectAttempts = 0;
      
      private var buffer:String = "";
      
      private var cloudDataDisabled:Boolean = false;
      
      private var cloudVariableDisabled:Boolean = false;
      
      private var cloudListDisabled:Boolean = true;
      
      private var cloudVariablesNumeralsOnly:Boolean = false;
      
      private var seenVariables:Array;
      
      private var seenLists:Array;
      
      private var cloudLastConnectEpochMillis:Number = 0;
      
      private var cloudConnectAttempts:int = 0;
      
      public function PersistenceManager(param1:ScratchOnline)
      {
         this.seenVariables = [];
         this.seenLists = [];
         super();
         this.app = param1;
         if(ExternalInterface.available)
         {
            ExternalInterface.addCallback("ASonCloudDataClose",this.onCloudDataClose);
            ExternalInterface.addCallback("ASonCloudDataConnect",this.onCloudDataConnect);
            ExternalInterface.addCallback("ASonCloudDataError",this.onCloudDataError);
            ExternalInterface.addCallback("ASonCloudDataData",this.onCloudDataData);
            ExternalInterface.addCallback("ASclearSeenVariables",this.clearSeenVariables);
         }
      }
      
      public static function strings() : Array
      {
         return ["Cloud data","Connecting to Cloud data server...",cloudInfo,notProjectOwnerWarning,numberWarning];
      }
      
      public function prepareForCopyOrRemix() : void
      {
         var _loc1_:Variable = null;
         var _loc2_:ListWatcher = null;
         for each(_loc1_ in this.app.stagePane.variables)
         {
            if(_loc1_.isPersistent)
            {
               this.writeToServer("set_remix",_loc1_.name,_loc1_.value);
            }
         }
         for each(_loc2_ in this.app.stagePane.lists)
         {
            if(_loc2_.isPersistent)
            {
               this.writeToServer("lset_remix",_loc2_.listName,_loc2_.contents);
            }
         }
      }
      
      public function createVariable(param1:String) : void
      {
         if(!this.verifyOwner(true))
         {
            return;
         }
         this.writeToServer("create",param1);
      }
      
      public function updateVariable(param1:String, param2:*) : void
      {
         var _loc3_:Variable = null;
         if(this.cloudVariablesNumeralsOnly && isNaN(param2))
         {
            this.app.jsSetProjectBanner(numberWarning);
            _loc3_ = this.app.stagePane.lookupVar(param1);
            _loc3_.value = 0;
            param2 = 0;
         }
         if(!this.seenVariable(param1))
         {
            return;
         }
         this.writeToServer("set",param1,param2);
      }
      
      public function renameVariable(param1:String, param2:String) : void
      {
         if(!this.verifyOwner(true))
         {
            return;
         }
         this.writeToServer("rename",param1,undefined,undefined,param2);
      }
      
      public function deleteVariable(param1:String) : void
      {
         if(!this.verifyOwner(true))
         {
            return;
         }
         this.writeToServer("delete",param1);
      }
      
      public function setList(param1:String, param2:*) : void
      {
         this.writeToServer("lset",param1,param2);
      }
      
      public function appendList(param1:String, param2:*) : void
      {
         this.writeToServer("lappend",param1,param2);
      }
      
      public function deleteList(param1:String, param2:Number) : void
      {
         this.writeToServer("ldelete",param1,undefined,param2);
      }
      
      public function insertList(param1:String, param2:*, param3:Number) : void
      {
         this.writeToServer("linsert",param1,param2,param3);
      }
      
      public function replaceList(param1:String, param2:*, param3:Number) : void
      {
         this.writeToServer("lreplace",param1,param2,param3);
      }
      
      public function connect(param1:String) : void
      {
         this.server = param1;
         this.cloudDataDisabled = !this.app.isCloudDataEnabled();
         if(this.cloudDataDisabled)
         {
            return;
         }
         if(!this.app.lp)
         {
            this.app.addLoadProgressBox("Cloud data");
         }
         this.app.lp.setInfo("Connecting to Cloud data server...");
         this.app.log(LogLevel.INFO,"Connecting to cloud data server",{"server":param1});
         if(!this.app.editMode)
         {
         }
         if(ExternalInterface.available)
         {
            this.cloudLastConnectEpochMillis = new Date().time;
            this.cloudConnectAttempts = this.cloudConnectAttempts + 1;
            ExternalInterface.call("JScloudDataConnect",param1);
         }
      }
      
      private function writeToServer(param1:*, param2:* = undefined, param3:* = undefined, param4:* = NaN, param5:* = undefined) : void
      {
         if(this.cloudDataDisabled)
         {
            return;
         }
         if(param1 != "handshake" && !this.verifyOwner())
         {
            return;
         }
         var _loc6_:Object = {};
         _loc6_.method = param1;
         _loc6_.user = this.app.userName;
         _loc6_.project_id = this.app.projectId;
         if(param2 != undefined)
         {
            _loc6_.name = param2;
         }
         if(param3 != undefined)
         {
            _loc6_.value = param3;
         }
         if(!isNaN(param4))
         {
            _loc6_.index = param4;
         }
         if(param5 != undefined)
         {
            _loc6_.new_name = param5;
         }
         var _loc7_:String = util.JSON.stringify(_loc6_,false);
         if(ExternalInterface.available)
         {
            ExternalInterface.call("JScloudDataSend",_loc7_);
         }
      }
      
      private function reconnectCloudDataAfterClose() : void
      {
         if(this.cloudDataDisabled)
         {
            return;
         }
         this.app.log(LogLevel.INFO,"Attempt reconnect to cloud server.");
         if(ExternalInterface.available)
         {
            ExternalInterface.call("JScloudDataConnect",this.server);
         }
      }
      
      private function onCloudDataClose() : void
      {
         this.decayTimeout = 1000 * (Math.random() * (Math.pow(this.connectAttempts,2) - 1) + 1);
         setTimeout(this.reconnectCloudDataAfterClose,this.decayTimeout);
      }
      
      public function onCloudDataConnect() : void
      {
         if(!this.ready)
         {
            this.buffer = "";
            this.writeToServer("handshake");
            this.ready = true;
            dispatchEvent(new Event(PersistenceManager.READY));
            if(this.app.lp && this.app.lp.getTitle() == Translator.map("Cloud data"))
            {
               this.app.removeLoadProgressBox();
            }
         }
         if(this.connectAttempts < 5)
         {
            this.connectAttempts = this.connectAttempts + 1;
         }
         else
         {
            this.connectAttempts = 1;
         }
         this.app.log(LogLevel.INFO,"Successfully connected to cloud data server");
      }
      
      private function onCloudDataError() : void
      {
         this.app.log(LogLevel.WARNING,"Connection Error for Cloud Data Server");
         this.ready = false;
         if(this.app.lp && this.app.lp.getTitle() == Translator.map("Cloud data"))
         {
            this.app.removeLoadProgressBox();
         }
         this.onCloudDataClose();
      }
      
      public function onCloudDataData(param1:String) : void
      {
         this.buffer = this.buffer + param1;
         this.parseBuffer();
      }
      
      private function verifyOwner(param1:Boolean = false) : Boolean
      {
         if(this.cloudDataDisabled)
         {
            return false;
         }
         if(!this.app.isLoggedIn())
         {
            return false;
         }
         if(this.app.isMine)
         {
            return true;
         }
         if(param1)
         {
            return false;
         }
         if(!this.app.isMine && this.app.saveNeeded)
         {
            if(this.app.editMode)
            {
               this.app.jsSetProjectBanner(notProjectOwnerWarning);
            }
            return false;
         }
         if(!this.app.isMine && this.app.editMode)
         {
            this.app.jsSetProjectBanner(notProjectOwnerWarning);
            return false;
         }
         return true;
      }
      
      private function seenVariable(param1:String) : Boolean
      {
         if(this.seenVariables.indexOf(param1) > -1)
         {
            return true;
         }
         return false;
      }
      
      private function clearSeenVariables() : void
      {
         this.seenVariables = [];
      }
      
      private function parseBuffer() : void
      {
         var _loc1_:ListWatcher = null;
         var _loc2_:int = 0;
         var _loc3_:Variable = null;
         var _loc4_:String = null;
         var _loc5_:Object = null;
         var _loc6_:String = null;
         var _loc7_:ScratchObj = null;
         while((_loc2_ = this.buffer.indexOf("\n")) >= 0)
         {
            _loc4_ = this.buffer.slice(0,_loc2_);
            this.buffer = this.buffer.slice(_loc2_ + 1);
            if(_loc4_.length > 0)
            {
               _loc5_ = util.JSON.parse(_loc4_);
               _loc6_ = _loc5_.method;
               if(_loc6_ == "ack")
               {
                  _loc7_ = this.app.stageObj();
                  _loc3_ = _loc7_.lookupOrCreateVar(_loc5_.name);
                  _loc3_.isPersistent = true;
                  this.app.runtime.showVarOrListFor(_loc5_.name,false,_loc7_);
                  this.app.setSaveNeeded();
                  if(this.seenVariables.indexOf(_loc5_.name) < 0)
                  {
                     this.seenVariables.push(_loc5_.name);
                  }
                  this.app.saveProjectToServer();
               }
               if(_loc6_ == "set")
               {
                  if(this.cloudVariableDisabled)
                  {
                     return;
                  }
                  _loc3_ = this.app.stagePane.lookupVar(_loc5_.name);
                  if(_loc3_ && _loc3_.isPersistent)
                  {
                     _loc3_.value = _loc5_.value;
                  }
                  if(this.seenVariables.indexOf(_loc5_.name) < 0)
                  {
                     this.seenVariables.push(_loc5_.name);
                  }
               }
               if(_loc6_ == "lset")
               {
                  if(this.cloudListDisabled)
                  {
                     return;
                  }
                  _loc1_ = this.app.stagePane.lookupOrCreateList(_loc5_.name);
                  if(_loc1_.isPersistent)
                  {
                     _loc1_.contents = _loc5_.value;
                     if(_loc1_.visible)
                     {
                        _loc1_.updateWatcher(_loc1_.contents.length,false,this.app.interp);
                     }
                  }
                  if(this.seenLists.indexOf(_loc5_.name) < 0)
                  {
                     this.seenLists.push(_loc5_.name);
                  }
               }
               if(_loc6_ == "lappend")
               {
                  if(this.cloudListDisabled)
                  {
                     return;
                  }
                  _loc1_ = this.app.stagePane.lookupOrCreateList(_loc5_.name);
                  if(_loc1_.isPersistent)
                  {
                     _loc1_.contents.push(_loc5_.value);
                     if(_loc1_.visible)
                     {
                        _loc1_.updateWatcher(_loc1_.contents.length,false,this.app.interp);
                     }
                  }
               }
               if(_loc6_ == "ldelete")
               {
                  if(this.cloudListDisabled)
                  {
                     return;
                  }
                  if(isNaN(_loc5_.index))
                  {
                     return;
                  }
                  _loc1_ = this.app.stagePane.lookupOrCreateList(_loc5_.name);
                  if(_loc1_.isPersistent)
                  {
                     _loc1_.contents.splice(_loc5_.index - 1,1);
                     if(_loc1_.visible)
                     {
                        _loc1_.updateWatcher(_loc5_.index,false,this.app.interp);
                     }
                  }
               }
               if(_loc6_ == "lreplace")
               {
                  if(this.cloudListDisabled)
                  {
                     return;
                  }
                  if(isNaN(_loc5_.index))
                  {
                     return;
                  }
                  _loc1_ = this.app.stagePane.lookupOrCreateList(_loc5_.name);
                  if(_loc1_.isPersistent)
                  {
                     _loc1_.contents.splice(_loc5_.index - 1,1,_loc5_.value);
                     if(_loc1_.visible)
                     {
                        _loc1_.updateWatcher(_loc5_.index,false,this.app.interp);
                     }
                  }
               }
               if(_loc6_ == "linsert")
               {
                  if(this.cloudListDisabled)
                  {
                     return;
                  }
                  if(isNaN(_loc5_.index))
                  {
                     return;
                  }
                  _loc1_ = this.app.stagePane.lookupOrCreateList(_loc5_.name);
                  if(_loc1_.isPersistent)
                  {
                     _loc1_.contents.splice(_loc5_.index - 1,0,_loc5_.value);
                     if(_loc1_.visible)
                     {
                        _loc1_.updateWatcher(_loc5_.index,false,this.app.interp);
                     }
                  }
               }
            }
         }
      }
   }
}
