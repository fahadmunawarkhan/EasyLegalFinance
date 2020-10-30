/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-28-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-24-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
trigger AccountTrigger on Account (before insert, after insert, before update, after update) {
    /*if (Trigger.isInsert && Trigger.isBefore)
        AccountTriggerHandler.validateAccountCreation(Trigger.new);
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
        AccountTriggerHandler.propagateFileNo(Trigger.isInsert, Trigger.oldMap, Trigger.new);*/
    if(Trigger.isBefore && Trigger.isUpdate){
        AccountObjHandler.UnderwriterEvaluationCheck(Trigger.isUpdate, Trigger.oldMap, Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isInsert){
        AccountObjHandler.CreateHistoryOnAccountCreate(Trigger.isInsert, Trigger.new);
    }
}