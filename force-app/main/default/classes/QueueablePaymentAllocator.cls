public with sharing class QueueablePaymentAllocator implements queueable {
   
    private Set<Id> paymentIds;

    public QueueablePaymentAllocator(Set<Id> paymentIds) {
        this.paymentIds = paymentIds;
    }

    public class PayoutDateInconsistentException extends Exception {}

    public void execute(System.QueueableContext QC){
        
        // Get the Payments
        list<Drawdown__c> payments = [select name, CreatedDate, Outstanding_Balance_as_of_Payout_Date__c,Date__c,Id,Opportunity__c,Opportunity__r.Payout_Date__c 
                                      from Drawdown__c where Id IN :this.paymentIds ORDER BY CreatedDate];

        // Get all Opportunities
        Set<ID> opportunityIds = new Set<ID>();
        for (Drawdown__c p:payments){
            opportunityIds.add(p.Opportunity__c);
        }

        // Get all drawdowns which are not payments but are under the same Opportunity - calling them customer "advances"
        list<Drawdown__c> advances = [select Name,date__c,Outstanding_Balance_as_of_Payout_Date__c,Id, Opportunity__c, Payout_Date__c, Temp_Payout_Date__c, 
                                      Interest_End_Date__c, Accrued_Interest_as_of_Payout_Date__c,Amount__c, Interest_repaid__c, Principal_repaid__c,
                                      Opportunity__r.Interest_Accrued_as_of_Payout_Date__c, Opportunity__r.Drawdown_Total_wo_Payment__c, 
                                      Opportunity__r.Sum_of_Principal_Repayments__c
                                      from Drawdown__c
                                      where Opportunity__c in :opportunityIds AND Outstanding_Balance_as_of_Payout_Date__c > 0 and Payment_Method__c <> 'Payment' order by Opportunity__c,Date__c ASC];


        list<Drawdown_Payment_Allocation__c> allocations = new list<Drawdown_Payment_Allocation__c> ();  // list of allocations to be inserted

        // saving the balance of each advance so I can decrement as I allocate it
        map<id,Decimal> advanceBalance = new map<id,Decimal>();  
        for (drawdown__c a : advances){
            advanceBalance.put(a.id,a.Outstanding_Balance_as_of_Payout_Date__c);
        }

        // go through each payment and allocate it - there is unlikely to be more than 1 but trying to bulkify ...
        Decimal SumPrincipalRepaymentsAux = 0;
        for (Drawdown__c p:payments){            
            Decimal paymentBalance = 0.00 - p.Outstanding_Balance_as_of_Payout_Date__c;  //change sign            
                 
            for (drawdown__c a : advances){
                
                if (a.Payout_Date__c <> p.date__c && a.opportunity__c == p.opportunity__c){
                    throw new PayoutDateInconsistentException('Drawdown ' + a.name + ', with a Payout Date of:' + a.Payout_Date__c + ' is not consistent with Payment date on ' + p.name+ ' of '+ p.date__c +'. Payments cannot be allocated.');
                }
                
                if (a.opportunity__c == p.opportunity__c && paymentBalance > 0 && advanceBalance.get(a.id)> 0  ){
                    
                    Decimal AllocationAmount = 0.00;                    
                    if (advanceBalance.get(a.id)>= paymentBalance){
                        AllocationAmount += paymentBalance;
                        advanceBalance.put(a.id,advanceBalance.get(a.id)-paymentBalance);
                        paymentBalance = 0;
                        
                    } else {
                        AllocationAmount += advanceBalance.get(a.id);
                        paymentBalance -= advanceBalance.get(a.id);
                        advanceBalance.put(a.id,0);
                        
                    }
                    Drawdown_Payment_Allocation__c newAllocation = 
                        new Drawdown_Payment_Allocation__c (Amount__c=AllocationAmount, drawdown__c=a.id,payment__c=p.id, 
                                                            payout_date__c=a.payout_date__c, temp_payout_date__c=a.temp_payout_date__c, 
                                                            Transaction_Date__c=p.date__c, opportunity__c=p.opportunity__c,
                                                            Interest_Accrued_to_Transaction_Date__c = a.Accrued_Interest_as_of_Payout_Date__c,
                                                            Interest_End_Date__c = a.Interest_End_Date__c);
                    
                    if(SumPrincipalRepaymentsAux == 0 && a.Opportunity__r.Sum_of_Principal_Repayments__c != null){
                        SumPrincipalRepaymentsAux = a.Opportunity__r.Sum_of_Principal_Repayments__c;
                    } else if (SumPrincipalRepaymentsAux == 0 && a.Opportunity__r.Sum_of_Principal_Repayments__c == null){
                        SumPrincipalRepaymentsAux = 0;
                    }
                    
                    
                    // calculate principal repaid                    
                    If (SumPrincipalRepaymentsAux >= a.Opportunity__r.Drawdown_Total_wo_Payment__c){
                        //set to zero as principal is already fully paid
                        newAllocation.Principal_repaid__c = 0.00;
                    } else{
                        If((AllocationAmount + SumPrincipalRepaymentsAux)<= a.Opportunity__r.Drawdown_Total_wo_Payment__c){
                            //set to full repayment as principal outstanding is less than repayment
                            newAllocation.Principal_repaid__c = AllocationAmount;
                            SumPrincipalRepaymentsAux = SumPrincipalRepaymentsAux + newAllocation.Principal_repaid__c;
                        } else {
                            //set to the difference between the principal outstanding and the amount paid so far
                            newAllocation.Principal_repaid__c = a.Opportunity__r.Drawdown_Total_wo_Payment__c - SumPrincipalRepaymentsAux;
                            SumPrincipalRepaymentsAux = SumPrincipalRepaymentsAux + newAllocation.Principal_repaid__c;
                        }
                    }
                    
                    system.debug(' newAllocation.Principal_repaid__c >> ' + newAllocation.Principal_repaid__c);
                    
                    // calculate interest repaid                    
                    If (newAllocation.Principal_repaid__c >= AllocationAmount){
                        // all of the repayment went to principal to set interest repaid to zero
                        newAllocation.Interest_repaid__c = 0.00;
                    } else {
                        // Interest repaid is set to the leftover amount after the principal is repaid
                        newAllocation.Interest_repaid__c = AllocationAmount - newAllocation.Principal_repaid__c;
                    }
                    
                    system.debug(' newAllocation.Interest_repaid__c >> ' + newAllocation.Interest_repaid__c );
                    
                    //insert newAllocation;
                    allocations.add(newAllocation);                 
                }
            }
        }
        insert allocations;
    }
}