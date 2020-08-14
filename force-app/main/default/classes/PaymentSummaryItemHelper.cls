public class PaymentSummaryItemHelper {
    @TestVisible
    private static void fillRealPaymentSummaryItem(PaymentSummaryItem paymentSummaryItem, Decimal reserveBalance, Decimal principal, Decimal interest, Boolean isLastOpp){        
        if (reserveBalance == 0.0 || (reserveBalance < 0.0 && !isLastOpp))
            paymentSummaryItem.referenceNotes = 'Loan Payout';
        else
            paymentSummaryItem.referenceNotes = 'Partial Payment';        
        paymentSummaryItem.principal = principal;
        paymentSummaryItem.interest = interest;        
    }
    @TestVisible
    private static void fillSurplusPaymentSummaryItem(PaymentSummaryItem paymentSummaryItem, Decimal reserveBalance){        
        paymentSummaryItem.referenceNotes = 'Payment Surplus';
        if (reserveBalance < 0.0)
            paymentSummaryItem.surplus = -reserveBalance;                        
        paymentSummaryItem.amount = paymentSummaryItem.surplus;        
    }
    @TestVisible
    private static void fillShortfallPaymentSummaryItem(PaymentSummaryItem paymentSummaryItem, Decimal reserveBalance, Decimal principal, Decimal interest){        
        if (reserveBalance < 0.0){
            paymentSummaryItem.referenceNotes = 'Payment Surplus';
            paymentSummaryItem.surplus = -reserveBalance;   
            paymentSummaryItem.amount = paymentSummaryItem.surplus;
        }                        
        else if (reserveBalance >= 0.0){
            paymentSummaryItem.referenceNotes = 'Payment Shortfall';
            paymentSummaryItem.shortfallPrincipal = principal;   
            paymentSummaryItem.shortfallInterest = interest;   
        }     
    }
    @TestVisible
    private static void fillBadDebtPaymentSummaryItem(PaymentSummaryItem paymentSummaryItem, Decimal reserveBalance, Decimal principal, Decimal interest){        
        if (reserveBalance < 0.0){
            paymentSummaryItem.referenceNotes = 'Payment Surplus';
            paymentSummaryItem.surplus = -reserveBalance;   
            paymentSummaryItem.amount = paymentSummaryItem.surplus;
        }                        
        else if (reserveBalance >= 0.0){
            paymentSummaryItem.referenceNotes = 'Bad Debt';
            paymentSummaryItem.badDebtPrincipal = principal;
            paymentSummaryItem.badDebtInterest = interest;                            
        }     
    }
    @TestVisible
    private static void fillBadDebtRecoveryPaymentSummaryItem(PaymentSummaryItem paymentSummaryItem, Decimal reserveBalance, Decimal amount){        
        paymentSummaryItem.referenceNotes = 'Bad Debt Recovery';
        paymentSummaryItem.badDebtRecovery = amount;
        paymentSummaryItem.amount = paymentSummaryItem.badDebtRecovery;     
    }
    @TestVisible
    private static void fillOtherPaymentSummaryItem(PaymentSummaryItem paymentSummaryItem, Drawdown__c drawdown){        
        paymentSummaryItem.referenceNotes = drawdown.Reference_Notes__c;
        paymentSummaryItem.principal = drawdown.Principal_Repaid__c;
        paymentSummaryItem.interest = drawdown.Interest_Repaid__c;
        paymentSummaryItem.amount = drawdown.Total_Amount__c;        
    }
    
    @TestVisible
    private static void fillRefundPaymentSummaryItem(PaymentSummaryItem paymentSummaryItem, Drawdown__c drawdown){        
        paymentSummaryItem.referenceNotes = drawdown.Reference_Notes__c;
        paymentSummaryItem.refund = drawdown.Total_Amount__c;
        paymentSummaryItem.amount = drawdown.Total_Amount__c;        
    }

    
    public static PaymentSummaryItem getPaymentSummaryItemWithReserve(Drawdown__c drawdown, Opportunity opp, Decimal principal, Decimal interest, 
        	Decimal reserveBalance, Decimal reserveToReverse, Decimal reservePrincipal, Decimal reserveInterest, Boolean isLastOpp){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();                        
        paymentSummaryItem.id = drawdown.Id;
        paymentSummaryItem.fileNumber = opp.Account.AccountNumber;
        paymentSummaryItem.paymentDate = drawdown.Date__c;
        paymentSummaryItem.opportunityName = opp.Opportunity_Long_Name__c;
        paymentSummaryItem.wireFee = drawdown.Wire_Fee__c;    
        paymentSummaryItem.reserve = reserveToReverse;
        paymentSummaryItem.amount = principal + interest;                        
        
        String referenceNotes = '';
        if (drawdown.Reference_Notes__c == 'Loan Payout' || drawdown.Reference_Notes__c == 'Partial Payment'){
            fillRealPaymentSummaryItem(paymentSummaryItem, reserveBalance, principal, interest, isLastOpp);
        }
        else if (drawdown.Reference_Notes__c == 'Payment Surplus'){
            fillSurplusPaymentSummaryItem(paymentSummaryItem, reserveBalance);
        }
        else if(drawdown.Reference_Notes__c == 'Payment Shortfall'){  
            if (reserveBalance == 0.0)
                return null;
            fillShortfallPaymentSummaryItem(paymentSummaryItem, reserveBalance, principal, interest);
        }
        else if(drawdown.Reference_Notes__c == 'Bad Debt'){
            if (reserveBalance == 0.0)
                return null;
            fillBadDebtPaymentSummaryItem(paymentSummaryItem, reserveBalance, principal, interest);                                                
        }
        else if(drawdown.Reference_Notes__c == 'Bad Debt Recovery'){
            fillBadDebtRecoveryPaymentSummaryItem(paymentSummaryItem, reserveBalance, drawdown.Total_Amount__c);
        }  
        else if (drawdown.Reference_Notes__c == 'Client Rebate' || drawdown.Reference_Notes__c == 'Payment Rejected' || drawdown.Reference_Notes__c == 'Payment Halted'){
            fillOtherPaymentSummaryItem(paymentSummaryItem, drawdown);
        }
        else if  (drawdown.Reference_Notes__c == 'Refund'){
        	  fillRefundPaymentSummaryItem(paymentSummaryItem, drawdown);          
        }

        DateTime dt = DateTime.newInstance(drawdown.Date__c.year(), drawdown.Date__c.month(), drawdown.Date__c.day());
        paymentSummaryItem.paymentDateString = dt.format('dd-MMM-yy');                            
        
        return paymentSummaryItem;
    }
    
    public static List<PaymentSummaryItem> getPaymentSummaryItemsWithReserve(List<Opportunity> opps, List<Drawdown__c> drawdowns){
        List<PaymentSummaryItem> items = new List<PaymentSummaryItem>();
        Decimal reserveOverpayment = 0.0;
        Decimal reserveBalance = 0.0;
        for (Integer oppIndex = 0; oppIndex < opps.size(); oppIndex++){
            Opportunity opp = opps[oppIndex];
            Boolean isLastOpp = oppIndex == opps.size() - 1;
            List<Drawdown__c> drawdownsForOpp = new List<Drawdown__c>();            
            for (Drawdown__c drawdown : drawdowns){
                if (drawdown.Opportunity__c == opp.Id)
                	drawdownsForOpp.add(drawdown);
			}            
            if (opp.Is_Reserve_Applied__c && opp.Stop_Interest__c){                
                reserveOverpayment +=  opp.Outstanding_Balance_as_of_Reserve_Date__c;
                reserveBalance = reserveOverpayment;                                
                if (!isLastOpp && reserveBalance < 0.0)
                    reserveBalance = 0.0;
                if (reserveOverpayment > 0.0)
                    reserveOverpayment = 0.0;                
            }
            else reserveBalance = 0.0;
            //reserveBalance = opp.Is_Reserve_Applied__c && opp.Stop_Interest__c ? opp.Outstanding_Balance_as_of_Reserve_Date__c - reserveOverpayment : 0.0;
            Decimal reserveAmount = opp.Is_Reserve_Applied__c ? opp.Reserve_Amount_Without_Clearing__c : 0.0;
            Decimal reserveInterest = opp.Is_Reserve_Applied__c && opp.Stop_Interest__c ? opp.Interest_Accrued_as_of_Reserve_Date__c : 0.0;
            Decimal reservePrincipal = opp.Is_Reserve_Applied__c && opp.Stop_Interest__c ? opp.Principal_Advanced_To_Reserve_Date__c : 0.0;                        
            List<PaymentSummaryItem> itemsForOpp = new List<PaymentSummaryItem>();
            for (Integer i = 0; i < drawdownsForOpp.size(); i++){
                Drawdown__c drawdown = drawdownsForOpp[i];
                Decimal principal = 0.0;
                Decimal interest = 0.0;
                Decimal reserveToReverse = 0.0;
                if (drawdown.Payment_Method__c=='Payment'){
                    principal = drawdown.Principal_Repaid__c;
                    interest = drawdown.Interest_Repaid__c;
                    if (opp.Is_Reserve_Applied__c && opp.Stop_Interest__c && drawdown.Date__c > opp.Reserve_Date__c && reserveInterest > 0.0 ){
                        if (interest > reserveInterest)
                            interest = reserveInterest;
                    }                                        
				}                
                if (opp.Is_Reserve_Applied__c && ( !opp.Stop_Interest__c || (opp.Stop_Interest__c && drawdown.Date__c > opp.Reserve_Date__c) ) ){
                    if ((drawdown.Reference_Notes__c == 'Loan Payout' || drawdown.Reference_Notes__c == 'Partial Payment'
                        || drawdown.Reference_Notes__c == 'Client Rebate' || drawdown.Reference_Notes__c == 'Payment Rejected' || drawdown.Reference_Notes__c == 'Payment Halted')){
                            if (opp.Stop_Interest__c && drawdown.Date__c > opp.Reserve_Date__c){
                                reserveBalance -= drawdown.Principal_Repaid__c + drawdown.Interest_Repaid__c;
                                reservePrincipal -= drawdown.Principal_Repaid__c;
                                reserveInterest -= drawdown.Interest_Repaid__c;
                            }                            
                        	reserveToReverse = drawdown.Amount__c <= reserveAmount ? drawdown.Amount__c : reserveAmount;
                        	reserveAmount = drawdown.Amount__c <= reserveAmount ? (reserveAmount - drawdown.Amount__c) : 0.0;
                    }
                    /*else if (drawdown.Reference_Notes__c == 'Payment Shortfall' || drawdown.Reference_Notes__c == 'Bad Debt'){
                        reserveToReverse = drawdown.Amount__c <= reserveAmount ? drawdown.Amount__c : reserveAmount;
                        reserveAmount = drawdown.Amount__c <= reserveAmount ? (reserveAmount - drawdown.Amount__c) : 0.0;
                    }*/
                    else if (drawdown.Include_In_Principal__c){
                        reservePrincipal += drawdown.Amount__c;
                        reserveBalance += drawdown.Amount__c;
                    }
                }                
                if (drawdown.Payment_Method__c=='Payment' || drawdown.Reference_Notes__c=='Refund'){
                    if (opp.Is_Reserve_Applied__c && opp.Stop_Interest__c && drawdown.Date__c > opp.Reserve_Date__c){   
						PaymentSummaryItem item = getPaymentSummaryItemWithReserve(drawdown, opp, principal, interest, reserveBalance, reserveToReverse, reservePrincipal, reserveInterest, isLastOpp);                         
                        if (item != null)
                    		itemsForOpp.add( item );                    
                    }
                    else
                    	itemsForOpp.add(getPaymentSummaryItem(drawdown, opp.Account.AccountNumber, opp.Opportunity_Long_Name__c, opp.Is_Reserve_Applied__c ? reserveToReverse : 0.0));
                }
            }
            if (reserveBalance < 0.0)
                reserveOverpayment += reserveBalance;
            items.addAll(processItemsForOpp(itemsForOpp));
        }
        return items;
    }
    public static List<PaymentSummaryItem> processItemsForOpp(List<PaymentSummaryItem> itemsForOpp){
        List<PaymentSummaryItem> items = new List<PaymentSummaryItem>();
        for (Integer i = 0; i < itemsForOpp.size(); i++){
            PaymentSummaryItem item = itemsForOpp[i];
            if (item.referenceNotes == 'Loan Payout'){
                Boolean nextPaymentFound = false;
                for (Integer j = i+1; j < itemsForOpp.size(); j++){
                    PaymentSummaryItem nextItem = itemsForOpp[j];
                    if (nextItem.referenceNotes == 'Partial Payment' || nextItem.referenceNotes == 'Payment Surplus'){
                        nextPaymentFound = true;
                    }
				}                
                if (nextPaymentFound)                 
                    item.referenceNotes = 'Partial Payment';
            }
            items.add(item);
        }
        return items;
    }
    public static PaymentSummaryItem getPaymentSummaryItem(Drawdown__c payment, String fileNumber, String oppName, Decimal reserveAmount) {
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        paymentSummaryItem.id = payment.Id;
        paymentSummaryItem.amount = payment.Amount__c;
        paymentSummaryItem.fileNumber = fileNumber;
        paymentSummaryItem.paymentDate = payment.Date__c;
        paymentSummaryItem.opportunityName = oppName;
        paymentSummaryItem.wireFee = payment.Wire_Fee__c;
        if (reserveAmount != null)
            paymentSummaryItem.reserve = reserveAmount;
        DateTime dt = DateTime.newInstance(payment.Date__c.year(), payment.Date__c.month(), payment.Date__c.day());
        paymentSummaryItem.paymentDateString = dt.format('dd-MMM-yy');        
        if (payment.Reference_Notes__c == 'Loan Payout' || payment.Reference_Notes__c == 'Partial Payment'
           || payment.Reference_Notes__c == 'Client Rebate' || payment.Reference_Notes__c == 'Payment Rejected' || payment.Reference_Notes__c == 'Payment Halted'){
            if (payment.Principal_Repaid__c != null && payment.Principal_Repaid__c != 0.0)
            	paymentSummaryItem.principal = payment.Principal_Repaid__c;
            if (payment.Interest_Repaid__c != null && payment.Interest_Repaid__c != 0.0)
            	paymentSummaryItem.interest = payment.Interest_Repaid__c;
        }
        if(payment.Reference_Notes__c == 'Payment Surplus'){  
            paymentSummaryItem.surplus = payment.Total_Amount__c;
        }
        if(payment.Reference_Notes__c == 'Payment Shortfall'){  
            if (payment.Principal_Repaid__c != null && payment.Principal_Repaid__c != 0.0)
            	paymentSummaryItem.shortfallPrincipal = payment.Principal_Repaid__c;
            if (payment.Interest_Repaid__c != null && payment.Interest_Repaid__c != 0.0)
            	paymentSummaryItem.shortfallInterest = payment.Interest_Repaid__c;            
        }
        if(payment.Reference_Notes__c == 'Bad Debt'){  
            if (payment.Principal_Repaid__c != null && payment.Principal_Repaid__c != 0.0)
            	paymentSummaryItem.badDebtPrincipal = payment.Principal_Repaid__c;
            if (payment.Interest_Repaid__c != null && payment.Interest_Repaid__c != 0.0)
            	paymentSummaryItem.badDebtInterest = payment.Interest_Repaid__c;            
        }
        if(payment.Reference_Notes__c == 'Bad Debt Recovery'){  
            paymentSummaryItem.badDebtRecovery = payment.Total_Amount__c;
        }
        if (payment.Reference_Notes__c == 'Refund'){
            paymentSummaryItem.refund = payment.Total_Amount__c;
        }
        return paymentSummaryItem;
    }    

	public static List<PaymentSummaryItem> getPaymentSummaryItems(String accountId){
        List<Opportunity> opps = [select Name, Loan_Requests__c, Is_Reserve_Applied__c, Stop_Interest__c, Reserve_Amount_Without_Clearing__c, Opportunity_Long_Name__c, Account.AccountNumber, Reserve_Date__c,
                                  Outstanding_Balance_as_of_Reserve_Date__c, Interest_Accrued_as_of_Reserve_Date__c, Principal_Advanced_To_Reserve_Date__c from Opportunity where AccountId=:accountId order by Loan_Requests__c asc];
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);
        List<PaymentSummaryItem> paymentSummaryItems = new List<PaymentSummaryItem>();        
        List<Drawdown__c> drawdownList = [SELECT Amount__c, Total_Amount__c, Reference_Notes__c, Date__c, Opportunity__c, Payment_Method__c, Principal_Repaid__c, Include_in_Principal__c,
                                      	  Interest_Repaid__c, Wire_Fee__c FROM Drawdown__c where (Payment_Method__c='Payment' or Reference_Notes__c='Refund') and Opportunity__r.AccountId =: accountId order by Opportunity__r.Loan_Requests__c asc, Date__c asc, Name asc ];  
        return getPaymentSummaryItemsWithReserve(opps, drawdownList);
    }
    public static List<PaymentSummaryItem> getLastPaymentSummaryItems(String accountId, List<Id> paymentIds){
        List<PaymentSummaryItem> allItems = getPaymentSummaryItems(accountId);
        List<PaymentSummaryItem> items = new List<PaymentSummaryItem>();
        for (PaymentSummaryItem item : allItems){
            if (paymentIds.contains(item.id))
                items.add(item);
        }
        return items;
    }	         
}