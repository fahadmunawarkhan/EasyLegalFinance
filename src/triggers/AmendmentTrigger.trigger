trigger AmendmentTrigger on Opportunity (after update) {

    if(trigger.isAfter && trigger.isUpdate)
        AmendmentTriggerHandler.createActivityHistory(trigger.newMap);
}