/**
 * @File Name          : LawFirmSalesSummaryComponentCtrl.cls
 * @Description        : 
 * @Author             : fahad.khan@toptal.com
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 09/04/2020, 11:05:14 am
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    3/6/2020   fahad.khan@toptal.com     Initial Version
**/
public with sharing class LawFirmSalesSummaryComponentCtrl {
    public class Wrapper {
        @AuraEnabled
        public string firm {get; set;}
        @AuraEnabled
        public string firmId {get; set;}
        @AuraEnabled
        public integer totalFileCount {get; set;}
        @AuraEnabled
        public integer totalClosedFileCount {get; set;}
        @AuraEnabled
        public integer totalOpptyCount {get; set;}
        @AuraEnabled
        public decimal totalAmount {get; set;}
        @AuraEnabled
        public decimal totalClosedAmount {get; set;}
        @AuraEnabled
        public integer totalbdfile {get; set;}
        @AuraEnabled
        public double totalbdamount {get; set;}
        @AuraEnabled
        public integer totalShortFallFile {get; set;}
        @AuraEnabled
        public double totalShortFallAmt {get; set;}
        @AuraEnabled
        public integer totalOverAgeFile {get; set;}
        @AuraEnabled
        public double totalOverAgeAmt {get; set;}
        
        public wrapper(string f, string frmId){
            
            firm = f;
            firmId = frmId;
            totalFileCount = 0;
            totalClosedFileCount = 0;
            totalOpptyCount = 0;
            totalAmount = 0.00;
            totalClosedAmount = 0.00;
            totalbdfile = 0;
            totalbdamount = 0.00;
            totalShortFallFile = 0;
            totalShortFallAmt = 0.00;
            totalOverAgeFile = 0;
            totalOverAgeAmt = 0.00;
        }
        
        // public void wrapper1(integer tc, integer tcc, integer toc, decimal ta,decimal tca, integer tbdf, double tbda, integer tsff, double tsfa, integer toaf, double toaa){
        //     totalFileCount = tc;
        //     totalClosedFileCount = tcc;
        //     totalOpptyCount = toc;
        //     totalAmount = ta;
        //     totalClosedAmount = tca;
        //     totalbdfile = tbdf;
        //     totalbdamount = tbda;
        //     totalShortFallFile = tsff;
        //     totalShortFallAmt = tsfa;
        //     totalOverAgeFile = toaf;
        //     totalOverAgeAmt = toaa;
        // }
    }
    @AuraEnabled
    public static Wrapper[] getAmountGroupByLawFirm(String startDate, String endDate, String field, String direction, string BusinessUnit, String searchByName, String typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = '';            
            
            string eTransfer = 'e-Transfer';
            String payment = 'Payment';
            String loanPayout = 'Loan Payout';
            String partialPayment = 'Partial Payment';
            String paymentShortfall = 'Payment Shortfall';
            String paymentSurplus = 'Payment Surplus';
            string Cheque = 'Cheque';
            string AdminFee = 'Admin Fee';
            String ClosedWithLoan = 'Closed With Loan';
            String closedPaid = 'Closed - Paid';
            String closedShortfall = 'Closed - Shortfall';
            String closedSurplus = 'Closed - Surplus';
            String badDebt = 'Bad Debt';
            String clientRebate = 'Client Rebate';
            
            // for sorting 
            
            if(field == 'Firm'){
                field = 'Opportunity__r.Law_firm__r.name';
            }else if(field == 'Files'){
                field = 'COUNT_Distinct(Opportunity__r.AccountId)';  
            }else if(field == 'opptyCount'){
                field = 'COUNT_Distinct(Opportunity__c)';  
            }else if(field == 'Amount'){
                field = 'SUM(Amount__c)'; 
            }
            
            
            
            strQuery = 'Select Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
            strQuery += ' COUNT_Distinct(Opportunity__r.AccountId) file, COUNT_Distinct(Opportunity__c) opptyCount, ';
            strQuery += ' SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
            strQuery += ' OR (Payment_Method__c =:Cheque)';
            strQuery += ' OR (Payment_Method__c =:AdminFee))';
            strQuery += ' AND Is_Rejected__c = false';            
            strQuery += ' AND Opportunity__r.Law_firm__c != \'\''; 
            strQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
            strQuery += typeOfLoan == 'Consolidated' ? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += ' Group by Opportunity__r.Law_firm__c, Opportunity__r.Law_firm__r.name';
            strQuery += ' order by ' + field + ' ' + direction + ' NULLS LAST';
            
            List<AggregateResult> aggResult = Database.query(strQuery);
            List<Wrapper> wrapers = new List<Wrapper>();
            if(!aggResult.isEmpty()){
                Map<String, AggregateResult> result = new Map<String, AggregateResult>();
                List<String> lawfirms = new List<String>();
                Map<String, String> lawfirmMap = new Map<String, String>();
                Set<String> lawfirmIdsSet = new Set<String>();
                for(AggregateResult res : aggResult)
                {
                    String key = String.valueOf(res.get('firmId'));
                    result.put(key,res);
                    lawfirmIdsSet.add((String)res.get('firmId'));
                    if(!lawfirmMap.containsKey((String)res.get('firmId')))		lawfirmMap.put((String)res.get('firmId'), (String)res.get('firm'));
                    
                }
                
                // Closed with loan
                
                String closedWLoanQuery = 'Select Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId,'; 
                closedWLoanQuery += ' COUNT_Distinct(Opportunity__r.AccountId) file, COUNT_Distinct(Opportunity__c) opptyCount, ';
                closedWLoanQuery += ' SUM(Amount__c) amt';
                closedWLoanQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                closedWLoanQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                closedWLoanQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                closedWLoanQuery += ' AND Payment_Method__c =:payment';  
                closedWLoanQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment'; 
                closedWLoanQuery += ' OR Reference_Notes__c =:clientRebate)'; 
                closedWLoanQuery += ' AND Opportunity__r.Stage_Status__c =:closedPaid';
                closedWLoanQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
                closedWLoanQuery += ' AND Is_Rejected__c = false'; 
                closedWLoanQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                closedWLoanQuery += typeOfLoan == 'Consolidated' ? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                closedWLoanQuery += ' Group by Opportunity__r.Law_firm__c, Opportunity__r.Law_firm__r.name';
                //lawfirm in set of lawfirm
                List<AggregateResult> closedOppAggResult = Database.query(closedWLoanQuery);
                //double testvalue = 0;
                Map<String, AggregateResult> closedOppResultMap = new Map<String, AggregateResult>();
                if(!closedOppAggResult.isEmpty()){
                    for(AggregateResult res : closedOppAggResult)
                    {
                        //testvalue = testvalue + (double)res.get('amt');
                        String key = String.valueOf(res.get('firmId'));
                        closedOppResultMap.put(key,res);
                    }
                }
                system.debug('====>Toatl Test By Me');
                //system.debug(testvalue);
                system.debug('====>Toatl Test By Me');
                system.debug('Closed Loan');
                System.debug(closedOppResultMap);
                /*
                =================
                BAD DEBT QUERY
                =================
                */
                String badDebtOppQuery = 'Select Opportunity__r.Account.Business_Unit__c unit, Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId,';
                badDebtOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                badDebtOppQuery += ' SUM(Amount__c) amt';
                badDebtOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                badDebtOppQuery += ' AND Date__c <= :endDt';
                badDebtOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                //badDebtOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                //badDebtOppQuery += ' AND Payment_Method__c =:payment';
                badDebtOppQuery += ' AND Reference_Notes__c =:badDebt';
                badDebtOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
                badDebtOppQuery += ' AND Is_Rejected__c = false';
                badDebtOppQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                badDebtOppQuery += ' Group by Opportunity__r.Law_firm__c, Opportunity__r.Law_firm__r.name, Opportunity__r.Account.Business_Unit__c';

                List<AggregateResult> BadDebtAggResult = Database.query(badDebtOppQuery);
                Map<String, AggregateResult> BadDebtResultMap = new Map<String, AggregateResult>();
                if(!BadDebtAggResult.isEmpty()){
                    for(AggregateResult baddebtsagr : BadDebtAggResult)
                    {
                        String key = String.valueOf(baddebtsagr.get('firmId'));
                        BadDebtResultMap.put(key, baddebtsagr);
                        //closedOppResultMap.put(key,res);
                    }
                }
                system.debug('Bad Debts');
                system.debug(BadDebtResultMap);

                /*
                =================
                SHORT FALL QUERY
                =================
                */
                String shortFallOppQuery = 'Select Opportunity__r.Account.Business_Unit__c unit, Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId,';
                shortFallOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                shortFallOppQuery += ' SUM(Amount__c) amt';
                shortFallOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                shortFallOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                shortFallOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                shortFallOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                shortFallOppQuery += ' AND Payment_Method__c =:payment';
                shortFallOppQuery += ' AND Reference_Notes__c =:paymentShortfall';
                shortFallOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedShortfall';
                shortFallOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
                shortFallOppQuery += ' AND Is_Rejected__c = false';
                shortFallOppQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                shortFallOppQuery += ' Group by Opportunity__r.Law_firm__c, Opportunity__r.Law_firm__r.name, Opportunity__r.Account.Business_Unit__c ';

                List<AggregateResult> ShortFallAggResult = Database.query(shortFallOppQuery);
                Map<String, AggregateResult> ShortFallResultMap = new Map<String, AggregateResult>();
                if(!ShortFallAggResult.isEmpty()){
                    for(AggregateResult shortfallagr : ShortFallAggResult)
                    {
                        String key = String.valueOf(shortfallagr.get('firmId'));
                        ShortFallResultMap.put(key, shortfallagr);
                    }
                }
                system.debug('Short Fall Results');
                system.debug(ShortFallResultMap);


                /*
                =================
                OVERAGE QUERY
                =================
                */
                String overageOppQuery = 'Select Opportunity__r.Account.Business_Unit__c unit, Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId,';
                overageOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                overageOppQuery += ' SUM(Amount__c) amt';
                overageOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                overageOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                overageOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                overageOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                overageOppQuery += ' AND Payment_Method__c =:payment';  
                overageOppQuery += ' AND Reference_Notes__c =:paymentSurplus'; 
                overageOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedSurplus';
                overageOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
                overageOppQuery += ' AND Is_Rejected__c = false';
                overageOppQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                overageOppQuery += ' Group by Opportunity__r.Law_firm__c, Opportunity__r.Law_firm__r.name, Opportunity__r.Account.Business_Unit__c';

                List<AggregateResult> OverAgeAggResult = Database.query(overageOppQuery);
                Map<String, AggregateResult> OverAgeResultMap = new Map<String, AggregateResult>();
                if(!OverAgeAggResult.isEmpty()){
                    for(AggregateResult overageagr : OverAgeAggResult)
                    {
                        String key = String.valueOf(overageagr.get('firmId'));
                        OverAgeResultMap.put(key, overageagr);
                    }
                }
                system.debug('Over Age Results');
                system.debug(OverAgeResultMap);



                
                for(String f : lawfirmIdsSet)
                {
                    String fName = lawfirmMap.get(f);
                    String key = f;
                    Wrapper w = new Wrapper(fName, result.containsKey(key) ? (String)result.get(key).get('firmId') : '');
                        // ========== RHINO, ELFI, Consolidated ========//
                        w.totalFileCount += (result.containsKey(key) ? (Integer)result.get(key).get('file') : 0);
                        w.totalClosedFileCount += (closedOppResultMap.containsKey(key) ? (Integer)closedOppResultMap.get(key).get('file') : 0);
                        W.totalOpptyCount += (result.containsKey(key) ? (Integer)result.get(key).get('opptyCount') : 0);
                        w.totalClosedAmount += (closedOppResultMap.containsKey(key) ? (decimal)closedOppResultMap.get(key).get('amt') : 0);
                        w.totalAmount += (result.containsKey(key) ? (decimal)result.get(key).get('amt') : 0);
                        w.totalbdfile += (BadDebtResultMap.containsKey(key) ? (integer)BadDebtResultMap.get(key).get('file') : 0);
                        w.totalbdamount += (BadDebtResultMap.containsKey(key) ? (double)BadDebtResultMap.get(key).get('amt'): 0);
                        w.totalShortFallFile += (ShortFallResultMap.containsKey(key) ? (integer)ShortFallResultMap.get(key).get('file') : 0);
                        w.totalShortFallAmt += (ShortFallResultMap.containsKey(key) ? (double)ShortFallResultMap.get(key).get('amt') : 0);
                        w.totalOverAgeFile += (OverAgeResultMap.containsKey(key) ? (Integer)OverAgeResultMap.get(key).get('file') : 0);
                        w.totalOverAgeAmt += (OverAgeResultMap.containsKey(key) ? (double)OverAgeResultMap.get(key).get('amt') : 0);
                        // ========== RHINO, ELFI, Consolidated ========//
                    wrapers.add(w);
                }
                system.debug('this is wrapper');
                return wrapers;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static list<Drawdown__c> getDrawdownLawFirmSalesCongaURLs(){
        
        list<Drawdown__c> drawdown_conga_url = [select id, Conga_Law_Firm_Sales_Summary_View_All__c,Conga_Law_Firm_Sales_Summary_Print_All__c from Drawdown__c limit 1];
    	return drawdown_conga_url;
    }

    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static void saveCustomSettings(String startDate, String endDate, String businessUnit){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Law_Firm_Sales_Summary_Report__c psr = Law_Firm_Sales_Summary_Report__c.getOrgDefaults();
            
            psr.End_date__c = endDt;
            psr.Start_Date__c = startDt;
            psr.Business_Unit__c = businessUnit;
            
            update psr; 
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Law_Firm_Sales_Summary_Report__c getCustomSetting(){
        Law_Firm_Sales_Summary_Report__c LFSR = Law_Firm_Sales_Summary_Report__c.getOrgDefaults();
        return LFSR;
    }
}