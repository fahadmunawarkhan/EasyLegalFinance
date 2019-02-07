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

	@InvocableMethod(label='Allocate Payments' description='Create Drawdown Payment Allocation records to associate Payment Drawdown with Advance Drawdown')
	public static void AllocatePayments (List<ID> paymentIds) {
		//system.debug('xxxxxxxxxxxxxxxxxx Start Allocate Payments xxxxxxxxxxxxxxxxxx');
		// Get the Payments
		list<Drawdown__c> payments = [select name, Outstanding_Balance_as_of_Payout_Date__c,Date__c,Id,Opportunity__c,Opportunity__r.Payout_Date__c 
									  from Drawdown__c where id in :paymentIds];
		//system.debug('xxxxxxxxxxxxxxxxxx Payments found '+payments);

		// Get all Opportunities
		list<ID> opportunityIds = new List<ID>();
		for (Drawdown__c p:payments){
			opportunityIds.add(p.Opportunity__c);
		}
		//system.debug('xxxxxxxxxxxxxxxxxx Opportunities found '+opportunityIds);

		// Get all drawdowns which are not payments but are under the same Opportunity - calling them customer "advances"
		list<Drawdown__c> advances = [select Name,date__c,Outstanding_Balance_as_of_Payout_Date__c,Id, Opportunity__c, Payout_Date__c, Temp_Payout_Date__c, 
									  Interest_End_Date__c, Accrued_Interest_as_of_Payout_Date__c,Amount__c
									  from Drawdown__c
									  where Opportunity__c in :opportunityIds AND Outstanding_Balance_as_of_Payout_Date__c > 0 and Payment_Method__c <> 'Payment' order by Opportunity__c,Date__c ASC];

		//system.debug('xxxxxxxxxxxxxxxxxx advances found '+advances);

		list<Drawdown_Payment_Allocation__c> allocations = new list<Drawdown_Payment_Allocation__c> ();  // list of allocations to be inserted

		// saving the balance of each advance so I can decrement as I allocate it
		map<id,Decimal> advanceBalance = new map<id,Decimal>();  
		for (drawdown__c a : advances){
			advanceBalance.put(a.id,a.Outstanding_Balance_as_of_Payout_Date__c);
		}

		// go through each payment and allocate it - there is unlikely to be more than 1 but trying to bulkify ...
		
		for (Drawdown__c p:payments){            
			Decimal paymentBalance = 0.00 - p.Outstanding_Balance_as_of_Payout_Date__c;  //change sign            
			//system.debug('xxxxxxxxxxxxxxxxxx payment to process '+p);
			for (drawdown__c a : advances){
				if (a.Payout_Date__c <> p.date__c && a.opportunity__c == p.opportunity__c){
					throw new PayoutDateInconsistentException('Drawdown ' + a.name + ', with a Payout Date of:' + a.Payout_Date__c + ' is not consistent with Payment date on ' + p.name+ ' of '+ p.date__c +'. Payments cannot be allocated.');
				}
				system.debug('xxxxxxxxxxxxxxxxxx advance to check '+a);
				if (a.opportunity__c == p.opportunity__c && paymentBalance > 0 && advanceBalance.get(a.id)> 0  ){
					//system.debug('xxxxxxxxxxxxxxxxxx advance to process '+a);
					Decimal AllocationAmount = 0.00;                    
					if (advanceBalance.get(a.id)>= paymentBalance){
						AllocationAmount += paymentBalance;
						advanceBalance.put(a.id,advanceBalance.get(a.id)-paymentBalance);
						paymentBalance = 0;
						//system.debug('xxxxxxxxxxxxxxxxxx If section 1');
					} else {
						AllocationAmount += advanceBalance.get(a.id);
						paymentBalance -= advanceBalance.get(a.id);
						advanceBalance.put(a.id,0);
						//system.debug('xxxxxxxxxxxxxxxxxx If section 2');
					}
					Drawdown_Payment_Allocation__c newAllocation = 
					    new Drawdown_Payment_Allocation__c (Amount__c=AllocationAmount, drawdown__c=a.id,payment__c=p.id, 
															payout_date__c=a.payout_date__c, temp_payout_date__c=a.temp_payout_date__c, 
															Transaction_Date__c=p.date__c, opportunity__c=p.opportunity__c,
															Interest_Accrued_to_Transaction_Date__c = a.Accrued_Interest_as_of_Payout_Date__c,
															Interest_End_Date__c = a.Interest_End_Date__c);
					allocations.add(newAllocation);
					//system.debug('xxxxxxxxxxxxxxxxxx allocation to create '+newAllocation );
				}
			}

		}
		insert allocations;
		//system.debug('xxxxxxxxxxxxxxxxxx Payments Allocations created=>'+allocations.size());
		//system.debug('xxxxxxxxxxxxxxxxxx END Allocate Payments xxxxxxxxxxxxxxxxxx');
		return;
	} 
}