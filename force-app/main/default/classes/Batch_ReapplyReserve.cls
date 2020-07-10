global class Batch_ReapplyReserve implements Database.Batchable<sObject>{
	global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator('select Id, Is_Reserve_Applied__c, Stop_Interest__c, Reserve_Date__c, Reserve_Amount__c from Opportunity where Is_Reserve_Applied__c=true');
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
       List<Opportunity> opps = (List<Opportunity>) scope;
       doJob(opps);
   }
   
   global static void doJob(List<Opportunity> opps){
       List<Map<String, Object>> reserveInfos = new List<Map<String, Object>>();
       for (Opportunity opp : opps){
           Map<String, Object> m = new Map<String, Object>();
           m.put('Id', opp.Id);
           m.put('Is_Reserve_Applied__c', opp.Is_Reserve_Applied__c);
           m.put('Stop_Interest__c', opp.Stop_Interest__c);
           m.put('Reserve_Date__c', opp.Reserve_Date__c);
           m.put('Reserve_Amount__c', opp.Reserve_Amount__c);		
           reserveInfos.add(m);
       }
       System.debug(reserveInfos.size());
       ReserveHelper.applyReserveOpps(reserveInfos);        
   }

   global void finish(Database.BatchableContext BC){
   }
}