public class DeleteDrawdownQueueable implements Queueable{
    public String drawdownId;	
    public String accountId;	
    public DeleteDrawdownQueueable(String drawdownId, String accountId){
        this.drawdownId = drawdownId;        
        this.accountId = accountId;        
    }
    public void execute(QueueableContext context) {
        try{
            Drawdown__c d = [select Id from Drawdown__c where Id=:drawdownId];
            delete d;
        }
        catch(Exception ex){
            
        }
        Account acc = [select Is_Async_Processing__c from Account where Id=:accountId];
        acc.Is_Async_Processing__c = false;
        update acc;   
    }
}