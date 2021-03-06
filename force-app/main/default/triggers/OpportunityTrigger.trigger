trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update, after delete) {
    
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        OpportunityTriggerHandler.setDiscountschedule(Trigger.new, Trigger.oldMap, Trigger.isInsert);
        OpportunityTriggerHandler.clearInterestRateForVariableRates(Trigger.new);
        if (trigger.isUpdate){            
            OpportunityTriggerHandler.updateLoanStatus(Trigger.new, Trigger.oldMap);
            OpportunityTriggerHandler.clearReserveAmountWhenClosed(Trigger.new, Trigger.oldMap);
        }
    }
    
    if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert || Trigger.isDelete)){
        //Lawyer Avalible Credit Roll ups.
        OpportunityTriggerHandler.LawyerAvailableCreditRollUps(Trigger.isDelete ? Trigger.old : Trigger.new, 
                                                               Trigger.oldMap, Trigger.isInsert || Trigger.isDelete);
        
        if (Trigger.isInsert || Trigger.isUpdate)
            OpportunityTriggerHandler.sendEmailOnReserveChange(Trigger.isInsert, Trigger.oldMap, Trigger.new);        
    }
}