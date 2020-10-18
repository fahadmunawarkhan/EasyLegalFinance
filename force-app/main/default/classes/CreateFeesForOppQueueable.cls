public class CreateFeesForOppQueueable implements Queueable{
    Id oppId;
    Boolean onlyBOM;
    public CreateFeesForOppQueueable (Id oppId){
        this.oppId = oppId;        
    }
    
   	public void execute(QueueableContext context) {        
        try{
        	VariableFeeHelper.createFeesForOpp(oppId, false);                
            VariableFeeHelper.createBOMFeesForOpp(oppId);        
        	InterestCalculator.calculateVariableRates(oppId);
        }
        catch(Exception ex){
		}
        Opportunity opp = [select Id, VR_Fees_Generating_In_Progress__c from Opportunity where Id=:oppId];        
        opp.VR_Fees_Generating_In_Progress__c = false;
        update opp;
    }
}