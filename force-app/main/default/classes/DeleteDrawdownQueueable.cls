public class DeleteDrawdownQueueable implements Queueable{
    public String drawdownId;	
    public String accountId;	
    public DeleteDrawdownQueueable(String drawdownId, String accountId){
        this.drawdownId = drawdownId;        
        this.accountId = accountId;        
    }
    public void execute(QueueableContext context) {
        try{
            Drawdown__c dd = [select Id, Opportunity__c, Payment_Method__c, Opportunity__r.Interest_Rate_Type__c from Drawdown__c where Id=:drawdownId];
            Id oppId = dd.Opportunity__c;
            Boolean needRecalcVariableRates = false;
            if (dd.Payment_Method__c == 'Payment' && dd.Opportunity__r.Interest_Rate_Type__c == 'Variable')
                needRecalcVariableRates = true;
            delete dd;            
            if (needRecalcVariableRates)
                InterestCalculator.calculateVariableRates(new List<Id>{oppId});
        }
        catch(Exception ex){
            
        }
        Account acc = [select Is_Async_Processing__c from Account where Id=:accountId];
        acc.Is_Async_Processing__c = false;
        update acc;   
    }
}