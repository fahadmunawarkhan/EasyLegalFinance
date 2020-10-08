global class Batch_ClearNSF implements Database.Batchable<sObject>{
	global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator('select Reason_to_Reverse_Payment_NSF__c, Rejections_Count__c, Is_NSF_Rejection__c from Drawdown__c where Reason_to_Reverse_Payment_NSF__c=\'NSF Cheque\' and  Is_NSF_Rejection__c=false');
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
       List<Drawdown__c> drs = (List<Drawdown__c>) scope;
       doJob(drs);
   }
   
   global static void doJob(List<Drawdown__c> drs){
       for (Drawdown__c d : drs){
           d.Reason_to_Reverse_Payment_NSF__c = null;
       }
       
       update drs;
   }

   global void finish(Database.BatchableContext BC){
   }
}