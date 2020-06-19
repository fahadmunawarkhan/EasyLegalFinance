public class Batch_ReNumberDrawdown implements Database.Batchable<sObject> {
    
    public Set<Id> oppIds;
    
    public Batch_ReNumberDrawdown(){
        oppIds = new Set<Id>();
    }
    public Batch_ReNumberDrawdown(Set<Id> Ids){
        oppIds = Ids;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String strQuery = 'SELECT Id, (SELECT Id, Drawdown_Number__c FROM Drawdowns__r Order by Date__c asc) FROM Opportunity';
        strQuery += !oppIds.isEmpty()? ' WHERE Id in :oppIds' : '';
        return DataBase.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> Opportunities){
        List<Drawdown__c> drawdownsToUpdate = new List<Drawdown__c>();
        
        for(Opportunity opp :Opportunities){
            Integer num = 1;
            for(Drawdown__c dd : opp.Drawdowns__r){
                if(dd.Drawdown_Number__c != num){
                    dd.Drawdown_Number__c = num;
                    drawdownsToUpdate.add(dd);
                }
                num++;
            }
        }
        
        if(!drawdownsToUpdate.isEmpty()) update drawdownsToUpdate;
    }
    
    public void finish(Database.BatchableContext BC){

    }
}