public with sharing class PaymentAllocator {

/*------------------------------------------------------------
Author: Basil Dobek
Company: Deloitte
Description: A utility class to allocate a payment type Drawdown to an Advance type Drawdown.
             This clase creates "Drawdown Payment Allocation" objects to accomplish this.
			 Class is invokable so it can be called from Process Builder.
			 
			 NOTE: This class assumes that the Payout Date on all Drawdowns will match
			 the Payment Transaction Date.  This is critical as this controls the amount of interest shown 
			 on each Drawdown and would impact the amount which should be allocated if it were inconsistent.
			 An exception is thrown if this assumption proves invalid. 

Inputs: 
	- List of Payment Ids
History
<Date> <Authors Name> <Brief Description of Change>
------------------------------------------------------------*/
        
	// Define custom exception
	public class PayoutDateInconsistentException extends Exception {} // Throws this if Payout date on Drawdown not consistent with Transaction Date on Payment. 
    public class PaymentToReverseIsNotSetException extends Exception {}     

	@InvocableMethod(label='Allocate Payments' description='Create Drawdown Payment Allocation records to associate Payment Drawdown with Advance Drawdown')
    public static void AllocatePayments (List<ID> paymentIds) {            
        allocate(paymentIds, true);
        allocate(paymentIds, false);
    }       

    public static void allocate (List<ID> paymentIds, Boolean isFirstIteration) {
        // Get the Payments
		list<Drawdown__c> payments = [select name, Outstanding_Balance_as_of_Payout_Date__c,Date__c,Reference_Notes__c, Id,Opportunity__c,
                                      Opportunity__r.Payout_Date__c,Payout_Interest_First__c, Opportunity__r.Reserve_Date__c
									  from Drawdown__c where (id in :paymentIds) and (Reference_Notes__c != 'Payment Rejected') and (Reference_Notes__c != 'Payment Halted')];
		// Get all Opportunities
		list<ID> opportunityIds = new List<ID>();
		for (Drawdown__c p:payments){
			opportunityIds.add(p.Opportunity__c);
		}

		// Get all drawdowns which are not payments but are under the same Opportunity - calling them customer "advances"
		list<Drawdown__c> advances = [select Name,date__c,Outstanding_Balance_as_of_Payout_Date__c,Id, Opportunity__c, Payout_Date__c, Temp_Payout_Date__c, 
                                      Interest_End_Date__c, Accrued_Interest_as_of_Payout_Date__c,Amount__c, Interest_repaid__c, Principal_repaid__c, Advance_Principal_Repaid__c,
                                      Opportunity__r.Interest_Rate_Type__c
									  from Drawdown__c
									  where Opportunity__c in :opportunityIds AND Outstanding_Balance_as_of_Payout_Date__c > 0 and Payment_Method__c <> 'Payment' order by Opportunity__c,Date__c ASC];

		list<Drawdown_Payment_Allocation__c> allocations = new list<Drawdown_Payment_Allocation__c> ();  // list of allocations to be inserted

		for (Drawdown__c p:payments){  
            Boolean allocateToPrincipal = (p.Payout_Interest_First__c != isFirstIteration);
			Decimal paymentBalance = 0.00 - p.Outstanding_Balance_as_of_Payout_Date__c;  //change sign            
                 
			for (drawdown__c a : advances){                                                
				if (a.Payout_Date__c <> p.date__c && a.opportunity__c == p.opportunity__c){
					throw new PayoutDateInconsistentException('Drawdown ' + a.name + ', with a Payout Date of:' + a.Payout_Date__c + ' is not consistent with Payment date on ' + p.name+ ' of '+ p.date__c +'. Payments cannot be allocated.');
				}
                Decimal advancePrincipal = a.Amount__c;                
                if (a.Advance_Principal_Repaid__c != null)
                    advancePrincipal -=  a.Advance_Principal_Repaid__c;                
                Decimal advanceAmountToAllocate;                
                if (allocateToPrincipal)
                    advanceAmountToAllocate = advancePrincipal;
                else{
                    Decimal advanceInterest = a.Outstanding_Balance_as_of_Payout_Date__c - advancePrincipal;
                    advanceAmountToAllocate = advanceInterest;
                }                   
                if (a.opportunity__c == p.opportunity__c && paymentBalance > 0 && advanceAmountToAllocate > 0  ){
                    Decimal AllocationAmount = 0.00;
                    
                    if (advanceAmountToAllocate >= paymentBalance){
						AllocationAmount += paymentBalance;
						paymentBalance = 0;						
					} else {
						AllocationAmount += advanceAmountToAllocate;
						paymentBalance -= advanceAmountToAllocate;						
					}                                                       
                    Drawdown_Payment_Allocation__c newAllocation = 
					    new Drawdown_Payment_Allocation__c (Amount__c=AllocationAmount, drawdown__c=a.id,payment__c=p.id, 
															payout_date__c=a.payout_date__c, temp_payout_date__c=a.temp_payout_date__c, 
															Transaction_Date__c=p.date__c, opportunity__c=p.opportunity__c,
															Interest_Accrued_to_Transaction_Date__c = a.Accrued_Interest_as_of_Payout_Date__c,
															Interest_End_Date__c = a.Interest_End_Date__c, Reserve_Date__c = p.Opportunity__r.Reserve_Date__c);
                    if (allocateToPrincipal){
                        newAllocation.Principal_Repaid__c = AllocationAmount;
                        newAllocation.Interest_Repaid__c = 0.0;
                    }
                    else{
                        newAllocation.Interest_Repaid__c = AllocationAmount;
                        newAllocation.Principal_Repaid__c = 0.0;
                    }
					allocations.add(newAllocation);	                                        
                }
            }
        }
        insert allocations;
        recalculateVariableInterest(advances);
    }
    
    public static void recalculateVariableInterest(List<Drawdown__c> advances){
        Set<Id> oppIdsWithVariableInterest = new Set<Id>();
        for (drawdown__c a : advances){                                                
            if (a.Opportunity__r.Interest_Rate_Type__c == 'Variable')
                oppIdsWithVariableInterest.add(a.Opportunity__c);
        }
        if (!oppIdsWithVariableInterest.isEmpty()){   
            List<Id> oppIds = new List<Id>();
            oppIds.addAll(oppIdsWithVariableInterest);
            InterestCalculator.calculateVariableRates(oppIds);
        }
    }
    public static void allocateRejectionDrawdowns(List<Id> paymentDrawdownIds){
        List<Drawdown__c> paymentDrawdowns = [select name, Payment_To_Reverse__c, Amount__c, Principal_Reversed__c, Outstanding_Balance_as_of_Payout_Date__c, Date__c,Id, 
                                                Opportunity__c,Opportunity__r.Payout_Date__c, Opportunity__r.Reserve_Date__c, Reference_Notes__c from Drawdown__c where id in :paymentDrawdownIds];
        List<Id> advanceDrawdownIds = new List<Id>();
        for (Drawdown__c paymentDrawdown : paymentDrawdowns){
			advanceDrawdownIds.add(paymentDrawdown.Payment_To_Reverse__c);            
        }
        List<Drawdown__c> drawdownsToReverse = [select Id, Name, Payout_Date__c, temp_payout_date__c, Opportunity__c, Outstanding_Balance_as_of_Payout_Date__c,                                                
                                                Accrued_Interest_as_of_Payout_Date__c, Interest_End_Date__c,
                                                Opportunity__r.Interest_Rate_Type__c
                                                from Drawdown__c where Id in :advanceDrawdownIds];
        List<Drawdown_Payment_Allocation__c> allocations = new List<Drawdown_Payment_Allocation__c>();
        for (Drawdown__c paymentDrawdown : paymentDrawdowns){
            Decimal paymentBalance = 0.00 - paymentDrawdown.Outstanding_Balance_as_of_Payout_Date__c;  
            if (paymentBalance > 0){
                Drawdown__c advanceDrawdown = null;            
                for (Drawdown__c d : drawdownsToReverse){
                    if (paymentDrawdown.Payment_To_Reverse__c == d.Id)
                        advanceDrawdown = d;
                }
                if (advanceDrawdown == null){
                    throw new PaymentToReverseIsNotSetException('Payment to reverse is not set');
                }
                if (advanceDrawdown.Payout_Date__c <> paymentDrawdown.date__c && advanceDrawdown.opportunity__c == paymentDrawdown.opportunity__c){
                    throw new PayoutDateInconsistentException('Drawdown ' + advanceDrawdown.name + ', with a Payout Date of:' + advanceDrawdown.Payout_Date__c + ' is not consistent with Payment date on ' + paymentDrawdown.name+ ' of '+ paymentDrawdown.date__c +'. Payments cannot be allocated.');
                }
                Drawdown_Payment_Allocation__c newAllocation = createAllocationForRejection(paymentDrawdown, advanceDrawdown);
                allocations.add(newAllocation);
            }
        }
        insert allocations;
        recalculateVariableInterest(drawdownsToReverse);
    }
    
    public static Drawdown_Payment_Allocation__c createAllocationForRejection(Drawdown__c paymentDrawdown, Drawdown__c advanceDrawdown){        
        Drawdown_Payment_Allocation__c newAllocation = 
            new Drawdown_Payment_Allocation__c (Amount__c=paymentDrawdown.Amount__c, drawdown__c=advanceDrawdown.id,payment__c=paymentDrawdown.id, 
                                                payout_date__c=advanceDrawdown.payout_date__c, temp_payout_date__c=advanceDrawdown.temp_payout_date__c, 
                                                Transaction_Date__c=paymentDrawdown.date__c, opportunity__c=paymentDrawdown.opportunity__c,
                                                Interest_Accrued_to_Transaction_Date__c = advanceDrawdown.Accrued_Interest_as_of_Payout_Date__c,
                                                Interest_End_Date__c = advanceDrawdown.Interest_End_Date__c, Reserve_Date__c=paymentDrawdown.Opportunity__r.Reserve_Date__c);
            //System.debug('allocatepaymentDrawdowns ' + newAllocation.Amount__c  + ' ' + advanceDrawdown.Outstanding_Balance_as_of_Payout_Date__c + ' ' + paymentDrawdown.Principal_Reversed__c);
        if (paymentDrawdown.Reference_Notes__c == 'Payment Rejected' || paymentDrawdown.Reference_Notes__c == 'Payment Halted'){
            if (newAllocation.Amount__c < advanceDrawdown.Outstanding_Balance_as_of_Payout_Date__c ){
                newAllocation.Principal_Repaid__c = newAllocation.Amount__c;
                newAllocation.Interest_Repaid__c = 0.0;                    
            }
            else{
                newAllocation.Principal_Repaid__c = paymentDrawdown.Principal_Reversed__c;
                newAllocation.Interest_Repaid__c = advanceDrawdown.Outstanding_Balance_as_of_Payout_Date__c - paymentDrawdown.Principal_Reversed__c;                    
            }
        }
        else{
            newAllocation.Principal_Repaid__c = newAllocation.Amount__c;
            newAllocation.Interest_Repaid__c = 0.0;
        }
        
        return newAllocation;
    }
    
    public static void deletePaymentAllocations(List<Id> paymentIds){
        List<Drawdown_Payment_Allocation__c> paymentAllocations = [select Id from Drawdown_Payment_Allocation__c where Payment__c in :paymentIds];
        if (!paymentAllocations.isEmpty())
            delete paymentAllocations;
    }
}