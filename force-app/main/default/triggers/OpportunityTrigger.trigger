trigger OpportunityTrigger on Opportunity (before insert, before update) {
    
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        OpportunityTriggerHandler.setDiscountschedule(Trigger.new, Trigger.oldMap, Trigger.isInsert);
    }
}