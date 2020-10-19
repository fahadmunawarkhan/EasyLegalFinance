public class HistoricalDataController {
    
    @AuraEnabled
    public static List<sObject> searchHistoricalData(String recordId){
        
        List<Historical_Data__c> hdList=
            new List<Historical_Data__c>([SELECT Id,Opportunity__c,Opportunity__r.Name ,Opportunity__r.Opportunity_Long_Name__c 
                                          FROM Historical_Data__c 
                                          WHERE Opportunity__r.AccountId =:recordId]);
        system.debug(hdList);
        return hdList;
    }
    
}