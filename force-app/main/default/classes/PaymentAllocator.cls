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
		System.enqueueJob(new QueueablePaymentAllocator(new Set<Id>(paymentIds)));
	} 
}