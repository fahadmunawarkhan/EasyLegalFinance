public class CreateVariableFeesQueueable implements Queueable{
    List<Id> oppIds;
    public CreateVariableFeesQueueable (List<Id> oppIds){
        this.oppIds = oppIds;
    }
    
   	public void execute(QueueableContext context) {        
        if (!oppIds.isEmpty()){                        
            try{
                Id oppId = oppIds[0];
                VariableFeeHelper.createFeesForOpp(oppIds[0]);
                VariableFeeHelper.createBOMFeesForOpp(oppId);
                List<Drawdown__c> drawdowns = [select Id, Variable_Fees_Generated__c, BOM_Fees_Generated__c from Drawdown__c where Opportunity__c=:oppId and Has_Interest__c=true];
                for (Drawdown__c d : drawdowns){
                    d.Variable_Fees_Generated__c = true;
                    d.BOM_Fees_Generated__c = true;
                }
                update drawdowns;
                oppIds.remove(0);
                System.enqueueJob(new CreateVariableFeesQueueable(oppIds));
            }
            catch(Exception ex){
                onFinish();
            }
        }       
        else
            onFinish();
    }
    
    private void onFinish(){
    }
}