/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-13-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-04-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public with sharing class PaymentSummaryComponentCtlr {
    public class wrapperClass{
        @AuraEnabled
        public String prov{get;set;}
        @AuraEnabled
        public String businessUnit{get;set;}
        @AuraEnabled
        public Decimal amount{get;set;}
        @AuraEnabled
        public Integer fileCount{get;set;}
        @AuraEnabled
        public Integer opptyCount{get;set;}
        
        public wrapperClass(){
            prov = '';
            businessUnit = '';
            amount = 0;
            fileCount = 0;
            opptyCount = 0;
        }
    }
    @AuraEnabled
    public static wrapperClass[] getPaymentsGroupByProvince(String startDate, String endDate, List<String> businessUnit, List<String> typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            
            String strQuery = '';            
            
            string payment = 'Payment';
            string ClosedWithLoan = 'Closed With Loan';
            String PartialPayment = 'Partial Payment';
            String LoanPayout = 'Loan Payout';
            String clientRebate = 'Client Rebate';
            String Surplus = 'Payment Surplus';
            String Misc = 'Bad Debt Recovery';
            String Refund = 'Refund';
            
            strQuery = 'Select Opportunity__r.Account.ProvinceResidency__c prov, COUNT_DISTINCT(Opportunity__r.AccountId) file,'; 
            strQuery += ' COUNT_DISTINCT(Opportunity__c) opptyCount, SUM(Payment_Summary_Report_Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND ((Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout';
            strQuery += ' OR Reference_Notes__c =:Surplus OR Reference_Notes__c =:Misc)) OR Reference_Notes__c =:Refund)';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            strQuery += ' Group by Opportunity__r.Account.ProvinceResidency__c ';
            strQuery += ' Order by SUM(Amount__c) desc NULLS LAST';
            
              

            List<AggregateResult> aggResult = Database.query(strQuery);
            if(!aggResult.isEmpty()){
                List<wrapperClass> result = new List<wrapperClass>();
                List<String> provs = new List<String>();
                Set<String> provSet = new Set<String>();
                Map<String, wrapperClass> resultMap = new Map<String, wrapperClass>();
                for(AggregateResult ar : aggResult)
                {
                    String prov = (String)ar.get('prov');
                    if(!provSet.contains(prov))
                    {
                        provSet.add(prov);
                        provs.add(prov);
                    }
                    
                    if(!resultMap.containsKey(prov))	resultMap.put(prov, new wrapperClass());
                    wrapperClass r = resultMap.get(prov);
                    r.prov = prov;
                    r.fileCount += (Integer)ar.get('file');
                    r.opptyCount += (Integer)ar.get('opptyCount');
                    r.amount += (Double)ar.get('amt');
                }
                for(String p : provs)
                {
                    if(resultMap.containsKey(p))
                    {
                        result.add(resultMap.get(p));
                    }
                }
                return result;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static PartialPaymentsWrapper getPartialPayments(String startDate, String endDate, List<String> businessUnit, List<String> typeOfLoan){
        PartialPaymentsWrapper partialPaymentsW = new PartialPaymentsWrapper();
        //List<AggregateResult> aggResult = new List<AggregateResult>();
        try{
            AggregateResult aggResult = null;
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            
            String strQuery = ''; 
            
            // total payouts
            string payment = 'Payment';
            string ClosedWithLoan = 'Closed With Loan';
            String PartialPayment = 'Partial Payment';
            String LoanPayout = 'Loan Payout';
            String clientRebate = 'Client Rebate';
            String Surplus = 'Payment Surplus';
            String Misc = 'Bad Debt Recovery';
            String Refund = 'Refund';
            
            strQuery = 'Select'; 
            strQuery += ' COUNT_DISTINCT(Opportunity__c) payouts ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND ((Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout';
            strQuery += ' OR Reference_Notes__c =:Surplus OR Reference_Notes__c =:Misc)) OR Reference_Notes__c =:Refund)';
            strQuery += ' AND Is_Rejected__c = false';
            
            aggResult = Database.query(strQuery); 
            partialPaymentsW.noOfPayouts = aggResult.get('payouts') != null? (Integer)aggResult.get('payouts') : 0;
            
            
            // Average number of days outstanding
            strQuery = '';             
            strQuery = 'Select'; 
            strQuery += ' AVG(Outstanding_Days__c) outstanding ';
            strQuery += ' FROM Opportunity WHERE id in ( Select Opportunity__c from Drawdown__c where Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' AND ((Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout';
            strQuery += ' OR Reference_Notes__c =:Surplus OR Reference_Notes__c =:Misc)) OR Reference_Notes__c =:Refund))';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.avgNoOfDaysOutstanding = aggResult.get('outstanding') != null? (Decimal)aggResult.get('outstanding') : 0;
            
            
            // total principal paid
            strQuery = '';            
            strQuery = 'Select'; 
            strQuery += ' SUM(Principal_Repaid__c) principalPaid ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalPrincipalPaid = aggResult.get('principalPaid') != null? (Decimal)aggResult.get('principalPaid') : 0.00;
                  
            
			// total Other 'Admin Fee'
            strQuery = '';
            String Other = 'Other';
            String otherAdminFee = 'Admin Fee';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) adminFee ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:Other AND Reference_Notes__c =:otherAdminFee';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';            
            
            aggResult = Database.query(strQuery); 
            partialPaymentsW.totalOtherAdminFeePaid = aggResult.get('adminFee') != null? (Decimal)aggResult.get('adminFee') : 0.00;
            
            
            // total other 'Referral Fee' changes
            String ReferralFee = 'Referral Fee';
            strQuery = '';            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) otherReferralFee ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:Other AND Reference_Notes__c =:ReferralFee';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalOtherReferralFee = aggResult.get('otherReferralFee') != null? (Decimal)aggResult.get('otherReferralFee') : 0.00;
            
            // total other 'Legal Fee' changes
            String LegalFee = 'Legal Fee';
            strQuery = '';            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) otherLegalFee';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:Other AND Reference_Notes__c =:LegalFee';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalOtherLegalFee = aggResult.get('otherLegalFee') != null? (Decimal)aggResult.get('otherLegalFee') : 0.00;
            
            // total shortfall paid
            strQuery = '';
            
            String Shortfall = 'Payment Shortfall';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) shortfall';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment AND Reference_Notes__c =:Shortfall';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalShortfall = aggResult.get('shortfall') != null? (Decimal)aggResult.get('shortfall') : 0.00; 
            
            // total surplus paid
            strQuery = '';
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) surplus';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment AND Reference_Notes__c =:Surplus';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalSurplus = aggResult.get('surplus') != null? (Decimal)aggResult.get('surplus') : 0.00;
            
            // total misc paid
            strQuery = '';
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) misc ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment AND Reference_Notes__c =:Misc';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalMisc = aggResult.get('misc') != null? (Decimal)aggResult.get('misc') : 0.00;
            
            
            // Total Interest Received
            strQuery = 'SELECT SUM(Interest_Repaid__c) interestReceived';
            strQuery += ' FROM Drawdown__c';
            strQuery += ' WHERE Date__c >= :startDt';
            strQuery += ' AND Date__c <= :endDt';
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Interest_Repaid__c != null';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout OR Reference_Notes__c = :Surplus)';
            strQuery += ' AND Reference_Notes__c != \'Payment Rejected\'';
            strQuery += ' AND Is_Rejected__c = false';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalInterestPaid = aggResult.get('interestReceived') != null? (Decimal)aggResult.get('interestReceived') : 0.00;
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) refund';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Reference_Notes__c =:Refund';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalRefund = aggResult.get('refund') != null? (Decimal)aggResult.get('refund') : 0.00;
            
            // total client Rebate
            strQuery = '';            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) clientRebate ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += (businessUnit.isEmpty()) ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Reference_Notes__c =:clientRebate AND Reference_Notes__c != \'Payment Rejected\'';
            
            aggResult = Database.query(strQuery);
            partialPaymentsW.totalClientRebate = aggResult.get('clientRebate') != null? (Decimal)aggResult.get('clientRebate') : 0.00;
            
            
            partialPaymentsW.totalPayments = partialPaymentsW.totalPrincipalPaid + partialPaymentsW.totalInterestPaid + partialPaymentsW.totalOtherAdminFeePaid +
                partialPaymentsW.totalOtherReferralFee + partialPaymentsW.totalOtherLegalFee + partialPaymentsW.totalSurplus + partialPaymentsW.totalMisc;
            
            partialPaymentsW.totalPayments -= partialPaymentsW.totalRefund;
            
            
            
            
            //if(!aggResult.isEmpty()){
                
                
                // partialPaymentsW.totalInterestPaid = aggResult[3].get('interestPaid') != null? (Decimal)aggResult[3].get('interestPaid') : 0.00;
                
                
                
                
                
                //partialPaymentsW.totalPayments = partialPaymentsW.totalPrincipalPaid + partialPaymentsW.totalInterestPaid + 
                    //partialPaymentsW.totalAdminFeePaid + partialPaymentsW.totalOther;
                
                
            //}
            
            // get the conga url
            List<Drawdown__c> congaUrlHolder = [Select Conga_Payment_Summary_Report_Print_All__c,
                                                Conga_Payment_Summary_Report_Print_All_2__c,
                                                Conga_Payment_Summary_Report_Print_All_3__c,
                                                Conga_Payment_Summary_Report_Print_All_4__c,
                                                Conga_Payment_Summary_Report_Print_All_5__c,
                                                Conga_Payment_Summary_Report_View_All__c 
                                            from Drawdown__c limit 1];
        	partialPaymentsW.congaViewAllURL = congaUrlHolder.isEmpty() ? '' 
                : congaUrlHolder[0].Conga_Payment_Summary_Report_View_All__c;
        	partialPaymentsW.congaPrintReportURL = congaUrlHolder.isEmpty() ? '' 
                : congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All__c + 
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_2__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_3__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_4__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_5__c;
            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage()+e.getStackTraceString());
        }
        return partialPaymentsW;
    }
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate, List<String> businessUnit, List<String> typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Payment_Summary_Report__c psr = Payment_Summary_Report__c.getOrgDefaults();
            
            psr.End_date__c = endDt;
            psr.Start_Date__c = startDt;
            psr.Business_Unit__c = String.join(businessUnit, '|');
            psr.Type_of_Loan__c = String.join(typeOfLoan, '|');
            update psr;
            
            
            
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }        
        
    }
    
    @AuraEnabled
    public static Payment_Summary_Report__c getCustomSetting(){
        Payment_Summary_Report__c pSR = Payment_Summary_Report__c.getOrgDefaults();
        return pSR;
    }
    
    public class PartialPaymentsWrapper{
        
        @AuraEnabled
        public Integer noOfPayouts {get;set;}
        
        @AuraEnabled
        public Decimal avgNoOfDaysOutstanding {get;set;}
        
        @AuraEnabled
        public Decimal totalPrincipalPaid {get;set;}
        
        @AuraEnabled
        public Decimal totalInterestPaid {get;set;}
        
        @AuraEnabled
        public Decimal totalOtherAdminFeePaid {get;set;}
        
        @AuraEnabled
        public Decimal totalPayments {get;set;}
        
        @AuraEnabled
        public Decimal totalSurplus {get;set;}
        
        @AuraEnabled
        public Decimal totalShortfall {get;set;}
        
        @AuraEnabled
        public Decimal totalMisc {get;set;}
        
        @AuraEnabled
        public Decimal totalOtherReferralFee {get;set;}
        
        @AuraEnabled
        public Decimal totalClientRebate{get;set;}
        
        @AuraEnabled
        public Decimal totalRefund {get;set;}
        
        @AuraEnabled
        public Decimal totalOtherLegalFee {get;set;}
        
        @AuraEnabled
        public String congaViewAllURL {get;set;}
        
        @AuraEnabled
        public String congaPrintReportURL {get;set;}
        
        public PartialPaymentsWrapper(){
            noOfPayouts = 0;
            avgNoOfDaysOutstanding = 0;
            totalPrincipalPaid = 0.0;
            totalInterestPaid = 0.0;
            totalOtherAdminFeePaid = 0.0;
            totalPayments = 0.0;
            totalOtherReferralFee = 0.00;
            totalSurplus = 0.0;
            totalShortfall = 0.0;
            totalMisc = 0.0;
            totalRefund = 0.0;
            totalOtherLegalFee = 0.0;
            totalClientRebate = 0.0;
            
            congaViewAllURL = null;
            congaPrintReportURL = null;
        }
    }
}