trigger DrawdownTrigger on Drawdown__c (before insert , before update, after insert , after update, before delete, after delete) {

	if (trigger.isBefore && trigger.isInsert) {
		// send with empty "old map" as this isn't available in insert trigger
		Map <Id,Drawdown__c> dummyMap = new Map<Id,Drawdown__c> ();
		DrawdownTriggerHandler.validatePaymentChange( dummyMap,trigger.new);			
	}  
	if (trigger.isBefore && trigger.isUpdate) {
		DrawdownTriggerHandler.validatePaymentChange(trigger.oldMap,trigger.new);			
	}
	if(trigger.isBefore && trigger.isDelete){
		DrawdownTriggerHandler.validatePaymentDelete(trigger.old);
		// Deleting a Master object will cascade-delete the Detail objects, but Apex wont
		// run delete triggers for the cascade-deleted records.  That prevents the DLRS
		// summaries from running,
		// see https://github.com/afawcett/declarative-lookup-rollup-summaries/issues/257
		//
		// As a work around, we will delete the Detail records directly
		List <ID> toDel = New List<ID>{};
        toDel.addAll(trigger.oldMap.keySet());
		DeletePaymentAllocations.DeletePaymentAllocationsFromPayment(toDel);
	}
    if(trigger.isAfter && (Trigger.isInsert || trigger.isUpdate || trigger.isDelete)){
        ///*
        DrawdownTriggerHandler.updateAdminFeeOnFirstDrawdown(Trigger.isDelete ? Trigger.old : Trigger.new,
                                                             Trigger.oldMap,
                                                             Trigger.isInsert || Trigger.isDelete);
		//*/
    }
}