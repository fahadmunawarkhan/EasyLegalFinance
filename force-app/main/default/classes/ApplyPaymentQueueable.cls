public class ApplyPaymentQueueable implements Queueable{
    public String accountId;
	List<PaymentInfo> paymentInfos;
    public ApplyPaymentQueueable(String accountId, List<PaymentInfo> paymentInfos){
        this.accountId = accountId;
        this.paymentInfos = paymentInfos;
    }
    
   	public void execute(QueueableContext context) {        
        if (!paymentInfos.isEmpty()){                        
            try{
                CustomerViewComponentCtlr.applyPayment(paymentInfos[0].accountId, paymentInfos[0].payoutDate, paymentInfos[0].searchType, paymentInfos[0].eft, 
                                                       paymentInfos[0].chq, paymentInfos[0].oppId, paymentInfos[0].action, paymentInfos.size() == 1,
                                                       paymentInfos[0].OppBadDebts, paymentInfos[0].wireFee);
                paymentInfos.remove(0);
                System.enqueueJob(new ApplyPaymentQueueable(accountId, paymentInfos));
            }
            catch(Exception ex){
                onFinish();
            }
        }       
        else
            onFinish();
    }
    
    private void onFinish(){
        Account acc = [select Is_Async_Processing__c from Account where Id=:accountId];
        acc.Is_Async_Processing__c = false;
        update acc;
    }
}