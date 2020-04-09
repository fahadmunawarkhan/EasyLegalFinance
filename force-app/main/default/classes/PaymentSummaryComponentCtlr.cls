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
    public static wrapperClass[] getPaymentsGroupByProvince(String startDate, String endDate, String businessUnit, String typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            string filterByBusinessUnit = (businessUnit != null && !String.isEmpty(businessUnit))? businessUnit : 'ELFI';
            
            String strQuery = '';            
            
            string payment = 'Payment';
            string ClosedWithLoan = 'Closed With Loan';
            String PartialPayment = 'Partial Payment';
            String LoanPayout = 'Loan Payout';
            String clientRebate = 'Client Rebate';
            
            strQuery = 'Select Opportunity__r.Account.ProvinceResidency__c prov, Opportunity__r.Account.Business_Unit__c bunit, COUNT_DISTINCT(Opportunity__r.AccountId) file,'; 
            strQuery += ' COUNT_DISTINCT(Opportunity__c) opptyCount, SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout OR Reference_Notes__c =:clientRebate)';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' Group by Opportunity__r.Account.ProvinceResidency__c, Opportunity__r.Account.Business_Unit__c ';
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
    public static PartialPaymentsWrapper getPartialPayments(String startDate, String endDate, String businessUnit, String typeOfLoan){
        PartialPaymentsWrapper partialPaymentsW = new PartialPaymentsWrapper();
        //List<AggregateResult> aggResult = new List<AggregateResult>();
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String filterByBusinessUnit = (!String.isEmpty(businessUnit) && businessUnit != null)? businessUnit : 'ELFI';
            
            String strQuery = ''; 
            
            // total payouts
            string payment = 'Payment';
            string ClosedWithLoan = 'Closed With Loan';
            String PartialPayment = 'Partial Payment';
            String LoanPayout = 'Loan Payout';
            String clientRebate = 'Client Rebate';
            
            strQuery = 'Select'; 
            strQuery += ' COUNT(Opportunity__c) payouts, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout OR Reference_Notes__c =:clientRebate)';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultPayouts = Database.query(strQuery); 
            
            // Average number of days outstanding
            strQuery = ''; 
            
            strQuery = 'Select'; 
            strQuery += ' AVG(Outstanding_Days__c) outstanding, Account.Business_Unit__c unit ';
            strQuery += ' FROM Opportunity WHERE id in ( Select Opportunity__c from Drawdown__c where Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout OR Reference_Notes__c =:clientRebate))';
            strQuery += ' group by Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultOutstanding = Database.query(strQuery);
            
            // total principal paid
            strQuery = '';
            
            String Cheque = 'Cheque';
            String eTransfer = 'e-Transfer';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) principalPaid, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND (Payment_Method__c =:eTransfer OR Payment_Method__c =:Cheque)';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            //strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            
            List<AggregateResult> aggResultPrincipal = Database.query(strQuery);
            
            // total interest paid
               // yet to be decided, question marks added
            
			// total admin fee
            strQuery = '';
            
            String AdminFee = 'Admin Fee';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) adminFee, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND (Payment_Method__c =:AdminFee)';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            //strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            
            List<AggregateResult> aggResultAdminfee = Database.query(strQuery); 
            
            // total other changes
            strQuery = '';
            
            String Other = 'Other';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) other, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND (Payment_Method__c =:Other)';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            // strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            
            List<AggregateResult> aggResultOther = Database.query(strQuery); 
            
            // total shortfall paid
            strQuery = '';
            
            String Shortfall = 'Payment Shortfall';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) shortfall, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Reference_Notes__c =:Shortfall';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultShortfall = Database.query(strQuery); 
            
            // total surplus paid
            strQuery = '';

            String Surplus = 'Payment Surplus';

            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) surplus, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Reference_Notes__c =:Surplus';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultSurplus = Database.query(strQuery);
            
            // total misc paid
            strQuery = '';
            
            String Misc = 'Miscellaneous Payment';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) misc, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Reference_Notes__c =:Misc';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultMisc = Database.query(strQuery);
            
            
            // Total Interest Received
            strQuery = 'SELECT SUM(Interest_Repaid__c) interestReceived,';
            strQuery += ' Opportunity__r.Account.Business_Unit__c unit';
            strQuery += ' FROM Drawdown__c';
            strQuery += ' WHERE Opportunity__r.Date_Applied__c >= :startDt';
            strQuery += ' AND Opportunity__r.Date_Applied__c <= :endDt';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Interest_Repaid__c != null';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND Reference_Notes__c != \'Payment Rejected\'';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' AND Opportunity__r.Stage_Status__c like \'%Closed%\'';
            strQuery += ' AND Opportunity__r.Stage_Status__c != \'Closed - Bad Debt\'';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c';
            
            List<AggregateResult> aggResultInterestReceived = Database.query(strQuery);

            if(!aggResultPayouts.isEmpty()){
                for(AggregateResult aggResult : aggResultPayouts)
                {
                    partialPaymentsW.noOfPayouts += aggResult.get('payouts') != null? (Integer)aggResult.get('payouts') : 0;
                }
                
            }
            
            if(!aggResultoutstanding.isEmpty()){
                for(AggregateResult aggResult : aggResultoutstanding)
                {
                    partialPaymentsW.avgNoOfDaysOutstanding += aggResult.get('outstanding') != null? (Decimal)aggResult.get('outstanding') : 0;
                }
                
            }
            if(!aggResultPrincipal.isEmpty()){
                for(AggregateResult aggResult : aggResultPrincipal)
                {
                    partialPaymentsW.totalPrincipalPaid += aggResult.get('principalPaid') != null? (Decimal)aggResult.get('principalPaid') : 0.00;
                }
                
            }
            if(!aggResultAdminfee.isEmpty()){
                for(AggregateResult aggResult : aggResultAdminfee)
                {
                    partialPaymentsW.totalAdminFeePaid += aggResult.get('adminFee') != null? (Decimal)aggResult.get('adminFee') : 0.00;
                }
                
            }
            if(!aggResultOther.isEmpty()){
                for(AggregateResult aggResult : aggResultOther)
                {
                    partialPaymentsW.totalOther += aggResult.get('other') != null? (Decimal)aggResult.get('other') : 0.00;
                }
                
            }
            if(!aggResultShortfall.isEmpty()){
                for(AggregateResult aggResult : aggResultShortfall)
                {
                    partialPaymentsW.totalShortfall += aggResult.get('shortfall') != null? (Decimal)aggResult.get('shortfall') : 0.00;
                }
                
            }
            if(!aggResultSurplus.isEmpty()){
                for(AggregateResult aggResult : aggResultSurplus)
                {
                    partialPaymentsW.totalSurplus += aggResult.get('surplus') != null? (Decimal)aggResult.get('surplus') : 0.00;
                }
                
            }
            if(!aggResultMisc.isEmpty()){
                for(AggregateResult aggResult : aggResultMisc)
                {
                    partialPaymentsW.totalMisc += aggResult.get('misc') != null? (Decimal)aggResult.get('misc') : 0.00;
                }
                
            }
            
            if(!aggResultInterestReceived.isEmpty()){
                for(AggregateResult aggResult : aggResultInterestReceived)
                {
                    partialPaymentsW.totalInterestPaid += aggResult.get('interestReceived') != null? (Decimal)aggResult.get('interestReceived') : 0.00;
                }                
            }
            
            partialPaymentsW.totalPayments = partialPaymentsW.totalPrincipalPaid + partialPaymentsW.totalAdminFeePaid + 
                partialPaymentsW.totalOther + partialPaymentsW.totalInterestPaid;
            
            
            
            
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
                                                Conga_Payment_Summary_Report_View_All__c 
                                            from Drawdown__c limit 1];
        	partialPaymentsW.congaViewAllURL = congaUrlHolder.isEmpty() ? '' 
                : congaUrlHolder[0].Conga_Payment_Summary_Report_View_All__c;
        	partialPaymentsW.congaPrintReportURL = congaUrlHolder.isEmpty() ? '' 
                : congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All__c + 
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_2__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_3__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_4__c;
            
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
    public static void saveDateCustomSettings(String startDate, String endDate, String businessUnit, String typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Payment_Summary_Report__c psr = Payment_Summary_Report__c.getOrgDefaults();
            
            psr.End_date__c = endDt;
            psr.Start_Date__c = startDt;
            psr.Business_Unit__c = businessUnit;
            psr.Type_of_Loan__c = typeOfLoan;
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
        public Decimal totalAdminFeePaid {get;set;}
        
        @AuraEnabled
        public Decimal totalPayments {get;set;}
        
        @AuraEnabled
        public Decimal totalSurplus {get;set;}
        
        @AuraEnabled
        public Decimal totalShortfall {get;set;}
        
        @AuraEnabled
        public Decimal totalMisc {get;set;}
        
        @AuraEnabled
        public Decimal totalOther {get;set;}
        
        @AuraEnabled
        public String congaViewAllURL {get;set;}
        
        @AuraEnabled
        public String congaPrintReportURL {get;set;}
        
        public PartialPaymentsWrapper(){
            noOfPayouts = 0;
            avgNoOfDaysOutstanding = 0;
            totalPrincipalPaid = 0.0;
            totalInterestPaid = 0.0;
            totalAdminFeePaid = 0.0;
            totalPayments = 0.0;
            totalOther = 0.00;
            totalSurplus = 0.0;
            totalShortfall = 0.0;
            totalMisc = 0.0;
            
            congaViewAllURL = null;
            congaPrintReportURL = null;
        }
    }
}