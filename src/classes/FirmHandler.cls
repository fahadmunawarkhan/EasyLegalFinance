public with sharing class FirmHandler {
	
	public static void createActivityHistory(Map<Id,Opportunity> newMap){
        
        List<Firm__c> lstFirm = new List<Firm__c>();
        
        for(Opportunity opp : newMap.values()){
            Opportunity oppr = (Opportunity)Trigger.oldMap.get(opp.Id);
            
            if(opp.Law_Firm__c != oppr.Law_Firm__c ||
               opp.Lawyer__c != oppr.Lawyer__c 
               ){
                Firm__c firm = new Firm__c();
                firm.Law_Firm__c = opp.Law_Firm__c;
                firm.Lawyer__c = opp.Lawyer__c;
                firm.Date_of_Update__c = Date.today();
                firm.Opportunity__c = opp.Id;

                lstFirm.add(firm);
            }
        }

        if(lstFirm.size() > 0){
            insert lstFirm; 
        }
    }
}