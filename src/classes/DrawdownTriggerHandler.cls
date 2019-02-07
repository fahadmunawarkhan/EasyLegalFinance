public class DrawdownTriggerHandler {

    public static void validatePaymentChange(Map<Id,Drawdown__c> oldMap, List<Drawdown__c> newDrawdowns){
		/*------------------------------------------------------------
		Author: Basil Dobek
		Company: Deloitte
		Description: Validate that updates to payment dates do not change order of payments.  Changing order of payments is not supported. 
					Also amount changes when later payments exist is not supported. 
					And finally changing from or to a payment when later payments exist is not supported.
					This class works in before update and before insert.
		Inputs: Trigger.OldMap and Trigger.new context variables. 
			
		History
		<Date> <Authors Name> <Brief Description of Change>
		------------------------------------------------------------*/

		List <ID> OpportunityIds = new List <ID>();  // hold list of opportunities for which we have payments we need to validate date change on
		list <Drawdown__c> Payments = new List <Drawdown__c>();  // Will hold list of payments with potential issues

		for (Drawdown__c newDrawdown : newDrawdowns){
			Date OldDate = Date.newInstance(1900,01,01);
			Decimal OldAmount = 0;
			String OldPaymentMethod = '';
			if (trigger.isUpdate){
				OldDate = oldMap.get(newDrawdown.id).Date__c;
				OldAmount = oldMap.get(newDrawdown.id).Amount__c;
				OldPaymentMethod = oldMap.get(newDrawdown.id).Payment_Method__c;
			}

			if( (newDrawdown.Payment_Method__c =='Payment' && OldDate != newDrawdown.Date__c ) || 
			    (newDrawdown.Payment_Method__c =='Payment' && newDrawdown.Amount__c != OldAmount) ||
				(newDrawdown.Payment_Method__c =='Payment' && OldPaymentMethod != 'Payment' ) ||
				(newDrawdown.Payment_Method__c !='Payment' && OldPaymentMethod == 'Payment' )) {
				// save opportunity id in set
				// save payment in map
				OpportunityIds.Add(newDrawdown.Opportunity__c);
				Payments.Add(newDrawdown);	
			}
		}

		// query for all payments under the opportunities where we have payments with changed dates
		List <Drawdown__c> allPayments = [Select id,date__c from Drawdown__c where Opportunity__c in : OpportunityIds and Payment_Method__c = 'Payment'];

		// Cycle throuh every payment in our map of payments which are a potential issue and verify id doesn't violate one of the other payments
		for (drawdown__c newPayment : Payments){
			for (drawdown__c otherPayment : allPayments){
				if (Trigger.isUpdate){
					if ((newPayment.id != otherPayment.id) && (newPayment.date__c < otherPayment.Date__c || oldMap.get(newPayment.id).date__c < otherPayment.Date__c )){
						// throw an error as an invalid date change has occurred
						newPayment.addError('Invalid change due to conflicting payment.  Payments dated after this record must be removed first.');
					}
				}
				if (Trigger.isInsert){
					// on insert, don't check the to date
					if ((newPayment.id != otherPayment.id) && (newPayment.date__c < otherPayment.Date__c )){
						// throw an error as an invalid date change has occurred
						newPayment.addError('Invalid change due to conflicting payment.  Payments dated after this record must be removed first.');
					}
				}
			}
		}
	}

    public static void validatePaymentDelete(List<Drawdown__c> Payments){
		/*------------------------------------------------------------
		Author: Basil Dobek
		Company: Deloitte
		Description: Validate that payment deletions only occur on the last payment as changing order of payments via deletion is not supported. 
					Also verify the loan is still open.   
		Inputs: Trigger.OldMap context variable. 
			
		History
		<Date> <Authors Name> <Brief Description of Change>
		------------------------------------------------------------*/

		List <ID> OpportunityIds = new List <ID>();  // hold list of opportunities for which we have payments we need to validate deletion of

		for (Drawdown__c p : Payments){
			OpportunityIds.Add(p.Opportunity__c);
		}

		// query for all payments under the opportunities where we have payments with changed dates
		List <Drawdown__c> allPayments = [Select id,date__c,Opportunity__c,Opportunity__r.Stage_Status__c from Drawdown__c where Opportunity__c in : OpportunityIds and Payment_Method__c = 'Payment'];

		// Cycle throuh every payment in our map of payments which are a potential issue and verify id doesn't violate one of the other payments
		for (drawdown__c paymentToDelete : Payments){
			for (drawdown__c otherPayment : allPayments){
                if (paymentToDelete.Opportunity__c==otherPayment.Opportunity__c) {
                    if ((paymentToDelete.id != otherPayment.id)  && (paymentToDelete.date__c < otherPayment.Date__c )){
                        // throw an error as an invalid date change has occurred
                        paymentToDelete.addError('Invalid payment deletion due to later payments.  Payments dated after this record must be removed first.');
                    }  
                    if (paymentToDelete.Opportunity__r.Stage_Status__c == 'Paid Off'){
                        // throw an error as an Loan cannot be closed
                        paymentToDelete.addError('Cannot delete payments from close Loans.  Please re-open first.');                        
                    }
                }
			}
		}
	}

    public static void updateAdminFeeOnFirstDrawdown(List<Drawdown__c> newDrawdowns, Map<Id,Drawdown__c> oldMap, Boolean isInsert){
		/*------------------------------------------------------------
		Author: Fahad Khan
		Company: Toptal
		Description: update first drawdown of opportunity to house both admin fee and its amount
			
		History
		<Date> <Authors Name> <Brief Description of Change>
		------------------------------------------------------------*/
        
        Set<Id> oppties = new Set<Id>();
        for(Drawdown__c d : newDrawdowns)
        {
            if(d.Opportunity__c != null &&
               (isInsert || (!isInsert && 
                             (/*(d.Reference_Notes__c == 'Admin Fee' ||
									oldMap.get(d.Id).Reference_Notes__c == 'Admin Fee') && */
                                 (d.Per_Diem_as_of_Payout_Date__c != oldMap.get(d.Id).Per_Diem_as_of_Payout_Date__c ||
                                  d.Amount__c != oldMap.get(d.Id).Amount__c || 
                                  d.Reference_Notes__c != oldMap.get(d.Id).Reference_Notes__c || 
                                  d.Date__c != oldMap.get(d.Id).Date__c ||
                                  d.Accrued_Interest_as_of_Payout_Date__c != oldMap.get(d.Id).Accrued_Interest_as_of_Payout_Date__c ||
                                  d.Outstanding_Balance_as_of_Payout_Date__c != oldMap.get(d.Id).Outstanding_Balance_as_of_Payout_Date__c) )) ))
            {
                oppties.add( d.Opportunity__c);
            }
        }
        if(!oppties.isEmpty())
        {
            mergeAdminFeeWithFirstDrawdown(oppties);
        }
    }
	public static void mergeAdminFeeWithFirstDrawdown(Set<Id> opptyIds)
    {
        system.debug('In mergeAdminFeeWithFirstDrawdown Function');
        List<Opportunity> oppties = [Select id , Stage_Status__c,
                                     (Select Amount__c, Reference_Notes__c , Payment_Method__c,
                                      Accrued_Interest_as_of_Payout_Date__c, Admin_Accrued_Interest__c,
                                      Admin_Outstanding_Balance__c, Outstanding_Balance_as_of_Payout_Date__c,
                                      Admin_Per_Diem__c, Per_Diem_as_of_Payout_Date__c From Drawdowns__r
                                      Order by Date__c asc)
                                     from Opportunity where id in :opptyIds];
        List<Drawdown__c> updatables = new List<Drawdown__c>();
        for(Opportunity op : oppties)
        {
            if(!op.Drawdowns__r.isEmpty())
            {
                double adminFee = 0.0;
                double adminAccuredInterest = 0.0;
                double adminOutstandingBalance = 0.0;
                double adminPerDiem = 0.0;
                Drawdown__c firstDrawdown = null;
                for(Drawdown__c d : op.Drawdowns__r)
                {
                    if(d.Reference_Notes__c == 'Admin Fee')
                    {
                        //system.debug('Reference Notes == Admin Fee ' + d.Id);
                        adminFee += d.Amount__c;
                        adminAccuredInterest += d.Accrued_Interest_as_of_Payout_Date__c;
                        adminOutstandingBalance +=d.Outstanding_Balance_as_of_Payout_Date__c;
                        adminPerDiem += d.Per_Diem_as_of_Payout_Date__c;
                        //system.debug('sel drawdown Admin Fee ' + d.Amount__c);
                        //ystem.debug('Total Admin Fee ' + adminFee);
                        //system.debug('Total Admin Accrued Interest ' + adminAccuredInterest);
                    }
                    else if (d.Reference_Notes__c != 'Referral Fee' && firstDrawdown == null)
                    {
                        //system.debug('Reference Notes != Referral Fee and FDd == null ' + d.Id);
                        firstDrawdown = d;
                        //System.debug('firstDrawdown'+firstDrawdown);
                        
                    }else if (firstDrawdown != null){
                        d.Admin_Fee__c = null;
                        d.Admin_Accrued_Interest__c = null;
                        d.Admin_Outstanding_Balance__c = null;
                        d.Admin_Per_Diem__c = null;
                        updatables.add(d);
                    }
                }
                if(firstDrawdown != null && adminFee > 0)
                {
                    system.debug('FDd != null admin fee ++ ' + firstDrawdown.Id);
                    system.debug('Admin Fee to be assigned ' + adminFee);
                    firstDrawdown.Admin_Fee__c = adminFee;
                    firstDrawdown.Admin_Accrued_Interest__c = adminAccuredInterest;
                    firstDrawdown.Admin_Outstanding_Balance__c = adminOutstandingBalance;
                    firstDrawdown.Admin_Per_Diem__c = adminPerDiem;
                    updatables.add(firstDrawdown);
                }
            }
        }
        if(!updatables.isEmpty())
        {
            update updatables;
        }
    }
}