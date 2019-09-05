trigger FirmTrigger on Opportunity (after update) {

    if(trigger.isAfter && trigger.isUpdate){
        if(RDS_CustomerCtlr.runFirstTime != null && RDS_CustomerCtlr.runFirstTime){
            system.debug('<><><> :'+RDS_CustomerCtlr.runFirstTime); 
            FirmHandler.createActivityHistory(trigger.newMap);
        }
        
        /*
            * Code for Amendment 
        */
         AmendmentTriggerHandler.createActivityHistory(trigger.newMap);
    }
     
       
}