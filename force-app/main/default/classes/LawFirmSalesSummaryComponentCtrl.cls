/**
 * @File Name          : LawFirmSalesSummaryComponentCtrl.cls
 * @Description        : 
 * @Author             : fahad.khan@toptal.com
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 01/04/2020, 5:11:49 pm
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    3/6/2020   fahad.khan@toptal.com     Initial Version
**/
public with sharing class LawFirmSalesSummaryComponentCtrl {
    public class Wrapper {
        @AuraEnabled
        string firm {get; set;}
        @AuraEnabled
        string firmId {get; set;}
        @AuraEnabled
        integer rhinoFileCount {get; set;}
        @AuraEnabled
        integer rhinoClosedFileCount {get; set;}
        @AuraEnabled
        integer rhinoOpptyCount {get; set;}
        @AuraEnabled
        decimal rhinoAmount {get; set;}
        @AuraEnabled
        decimal rhinoClosedAmount {get; set;}
        @AuraEnabled
        integer rhinoBadDebtFile {get; set;}
        @AuraEnabled
        double rhinoBadDebtAmount {get; set;}
        @AuraEnabled
        integer rhinoShortFallFile {get; set;}
        @AuraEnabled
        double rhinoShortFallamt {get; set;}
        @AuraEnabled
        integer rhinoOverAgeFile {get; set;}
        @AuraEnabled
        double rhinoOverAgeamt {get; set;}
        @AuraEnabled
        integer elfiFileCount {get; set;}
        @AuraEnabled
        integer elfiClosedFileCount {get; set;}
        @AuraEnabled
        integer elfiOpptyCount {get; set;}
        @AuraEnabled
        decimal elfiAmount {get; set;}
        @AuraEnabled
        decimal elfiClosedAmount {get; set;}
        @AuraEnabled
        integer elfiBadDebtFile {get; set;}
        @AuraEnabled
        double elfiBadDebtAmount {get; set;}
        @AuraEnabled
        integer elfiShortFallFile {get; set;}
        @AuraEnabled
        double elfiShortFallAmt {get; set;}
        @AuraEnabled
        integer elfiOverAgeFile {get; set;}
        @AuraEnabled
        double elfiOverAgeAmt {get; set;}
        @AuraEnabled
        integer totalFileCount {get; set;}
        @AuraEnabled
        integer totalClosedFileCount {get; set;}
        @AuraEnabled
        integer totalOpptyCount {get; set;}
        @AuraEnabled
        decimal totalAmount {get; set;}
        @AuraEnabled
        decimal totalClosedAmount {get; set;}
        @AuraEnabled
        integer totalbdfile {get; set;}
        @AuraEnabled
        double totalbdamount {get; set;}
        @AuraEnabled
        integer totalShortFallFile {get; set;}
        @AuraEnabled
        double totalShortFallAmt {get; set;}
        @AuraEnabled
        integer totalOverAgeFile {get; set;}
        @AuraEnabled
        double totalOverAgeAmt {get; set;}
        
        public wrapper(string f, string frmId, integer rc,integer rcc, integer roc, decimal ra, decimal rca, integer rbdf, double rbda, integer rsff, double rsfa, integer roaf, double roaa, integer ec, integer ecc, integer eoc, decimal ea, decimal eca, integer ebdf, double ebda, integer esff, double esfa, integer tc, integer tcc, integer toc, decimal ta,decimal tca, integer tbdf, double tbda, integer tsff, double tsfa){
            
            firm = f;
            firmId = frmId;
            
            rhinoFileCount = rc;
            rhinoClosedFileCount = rcc;
            rhinoOpptyCount = roc;
            rhinoAmount = ra;
            rhinoClosedAmount = rca;
            rhinoBadDebtFile = rbdf;
            rhinoBadDebtAmount = rbda;
            rhinoShortFallFile = rsff;
            rhinoShortFallamt = rsfa;
            rhinoOverAgeFile = roaf;
            rhinoOverAgeamt = roaa;
            
            elfiFileCount = ec;
            elfiClosedFileCount = ecc;
            elfiOpptyCount = eoc;
            elfiAmount = ea;
            elfiClosedAmount = eca;
            elfiBadDebtFile = ebdf;
            elfiBadDebtAmount = ebda;
            elfiShortFallFile = esff;
            elfiShortFallAmt = esfa;
            
            totalFileCount = tc;
            totalClosedFileCount = tcc;
            totalOpptyCount = toc;
            totalAmount = ta;
            totalClosedAmount = tca;
            totalbdfile = tbdf;
            totalbdamount = tbda;
            totalShortFallFile = tsff;
            totalShortFallAmt = tsfa;
        }

        /*
            Creation Reason:
            Created this method because only 32 parameters can pass in method in constructor. Remaining variables set in this method.
        */
        public void wrapper2(integer eoaf, double eoaa, integer toaf, double toaa){
            elfiOverAgeFile = eoaf;
            elfiOverAgeAmt = eoaa;
            
            totalOverAgeFile = toaf;
            totalOverAgeAmt = toaa;
        }
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
            
            
            
            strQuery = 'Select Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, Opportunity__r.Lawyer__c lawyerId, ';
            strQuery += ' COUNT_Distinct(Opportunity__r.AccountId) file, COUNT_Distinct(Opportunity__c) opptyCount, ';
            strQuery += ' SUM(Amount__c) amt, Opportunity__r.Account.Business_Unit__c unit';
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
            strQuery += ' Group by Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c';
            strQuery += ' order by ' + field + ' ' + direction + ' NULLS LAST';
            
            List<AggregateResult> aggResult = Database.query(strQuery);
            List<Wrapper> wrapers = new List<Wrapper>();
            if(!aggResult.isEmpty()){
                Map<String, AggregateResult> result = new Map<String, AggregateResult>();
                List<String> lawfirms = new List<String>();
                Set<String> lawfirmSet = new Set<String>();
                Set<String> lawfirmIdsSet = new Set<String>();
                Set<String> lawyerIdsSet = new Set<String>();
                for(AggregateResult res : aggResult)
                {
                    String key = res.get('firm')+'-'+res.get('unit');
                    result.put(key,res);
                    lawfirmIdsSet.add((String)res.get('firmId'));
                    if(!lawfirmSet.contains((String)res.get('firm')))		lawfirms.add((String)res.get('firm'));
                    lawfirmSet.add((String)res.get('firm'));
                    lawyerIdsSet.add(String.ValueOf(res.get('lawyerId')));
                }
                
                // Closed with loan
                
                String closedWLoanQuery = 'Select Opportunity__r.Law_firm__r.name firm,'; 
                closedWLoanQuery += ' COUNT_Distinct(Opportunity__r.AccountId) file, COUNT_Distinct(Opportunity__c) opptyCount, ';
                closedWLoanQuery += ' SUM(Amount__c) amt, Opportunity__r.Account.Business_Unit__c unit';
                closedWLoanQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                closedWLoanQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                closedWLoanQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                closedWLoanQuery += ' AND Payment_Method__c =:payment';  
                closedWLoanQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment'; 
                closedWLoanQuery += ' OR Reference_Notes__c =:paymentShortfall OR Reference_Notes__c =:paymentSurplus)'; 
                closedWLoanQuery += ' AND (Opportunity__r.Stage_Status__c =:closedPaid';
                closedWLoanQuery += ' OR Opportunity__r.Stage_Status__c =:closedShortfall';
                closedWLoanQuery += ' OR Opportunity__r.Stage_Status__c =:closedSurplus)';
                closedWLoanQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
                closedWLoanQuery += ' AND Is_Rejected__c = false'; 
                closedWLoanQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                closedWLoanQuery += typeOfLoan == 'Consolidated' ? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                closedWLoanQuery += ' Group by Opportunity__r.Law_firm__r.name, Opportunity__r.Account.Business_Unit__c';
                //lawfirm in set of lawfirm
                List<AggregateResult> closedOppAggResult = Database.query(closedWLoanQuery);
                
                Map<String, AggregateResult> closedOppResultMap = new Map<String, AggregateResult>();
                if(!closedOppAggResult.isEmpty()){
                    for(AggregateResult res : closedOppAggResult)
                    {
                        String key = res.get('firm')+'-'+res.get('unit');
                        closedOppResultMap.put(key,res);
                    }
                }
                system.debug('Closed Loan');
                System.debug(closedOppResultMap);
                /*
                =================
                BAD DEBT QUERY
                =================
                */
                String badDebtOppQuery = 'Select Opportunity__r.Account.Business_Unit__c unit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm,';
                badDebtOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                badDebtOppQuery += ' SUM(Amount__c) amt';
                badDebtOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                badDebtOppQuery += ' AND Date__c <= :endDt';
                badDebtOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                //badDebtOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                //badDebtOppQuery += ' AND Payment_Method__c =:payment';
                badDebtOppQuery += ' AND Reference_Notes__c =:badDebt';
                badDebtOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                badDebtOppQuery += ' AND Is_Rejected__c = false';
                badDebtOppQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                badDebtOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name';

                List<AggregateResult> BadDebtAggResult = Database.query(badDebtOppQuery);
                Map<String, AggregateResult> BadDebtResultMap = new Map<String, AggregateResult>();
                if(!BadDebtAggResult.isEmpty()){
                    for(AggregateResult baddebtsagr : BadDebtAggResult)
                    {
                        String key = String.valueOf(baddebtsagr.get('firm')) + '-' + String.valueOf(baddebtsagr.get('unit'));
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
                String shortFallOppQuery = 'Select Opportunity__r.Account.Business_Unit__c unit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm,';
                shortFallOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                shortFallOppQuery += ' SUM(Amount__c) amt';
                shortFallOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                shortFallOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                shortFallOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                shortFallOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                shortFallOppQuery += ' AND Payment_Method__c =:payment';
                shortFallOppQuery += ' AND Reference_Notes__c =:paymentShortfall';
                shortFallOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedShortfall';
                shortFallOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                shortFallOppQuery += ' AND Is_Rejected__c = false';
                shortFallOppQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                shortFallOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name';

                List<AggregateResult> ShortFallAggResult = Database.query(shortFallOppQuery);
                Map<String, AggregateResult> ShortFallResultMap = new Map<String, AggregateResult>();
                if(!ShortFallAggResult.isEmpty()){
                    for(AggregateResult shortfallagr : ShortFallAggResult)
                    {
                        String key = String.valueOf(shortfallagr.get('firm')) + '-' + String.valueOf(shortfallagr.get('unit'));
                        ShortFallResultMap.put(key, shortfallagr);
                        //closedOppResultMap.put(key,res);
                    }
                }
                system.debug('Short Fall Results');
                system.debug(ShortFallResultMap);


                /*
                =================
                OVERAGE QUERY
                =================
                */
                String overageOppQuery = 'Select Opportunity__r.Account.Business_Unit__c unit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm,';
                overageOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                overageOppQuery += ' SUM(Amount__c) amt';
                overageOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                overageOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                overageOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                overageOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                overageOppQuery += ' AND Payment_Method__c =:payment';  
                overageOppQuery += ' AND Reference_Notes__c =:paymentSurplus'; 
                overageOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedSurplus';
                overageOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                overageOppQuery += ' AND Is_Rejected__c = false';
                overageOppQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                overageOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name';

                List<AggregateResult> OverAgeAggResult = Database.query(shortFallOppQuery);
                Map<String, AggregateResult> OverAgeResultMap = new Map<String, AggregateResult>();
                if(!OverAgeAggResult.isEmpty()){
                    for(AggregateResult overageagr : OverAgeAggResult)
                    {
                        String key = String.valueOf(overageagr.get('firm')) + '-' + String.valueOf(overageagr.get('unit'));
                        OverAgeResultMap.put(key, overageagr);
                        //closedOppResultMap.put(key,res);
                    }
                }
                system.debug('Over Age Results');
                system.debug(OverAgeResultMap);



                
                for(String f : lawfirms)
                {
                    String rhinokey = f+'-Rhino';
                    String elfikey = f+'-ELFI';
                    String emptyKey = f+'-';
                    Wrapper w = new Wrapper(f,
                                            result.containsKey(rhinokey) ? (String)result.get(rhinokey).get('firmId') : '',
                                            /* ===== RINO Values =====*/
                                            result.containsKey(rhinokey) ? (Integer)result.get(rhinokey).get('file') : 0,
                                            closedOppResultMap.containsKey(rhinokey) ? (Integer)closedOppResultMap.get(rhinokey).get('file') : 0,
                                            result.containsKey(rhinokey) ? (Integer)result.get(rhinokey).get('opptyCount') : 0,
                                            result.containsKey(rhinokey) ? (decimal)result.get(rhinokey).get('amt') : 0,
                                            closedOppResultMap.containsKey(rhinokey) ? (decimal)closedOppResultMap.get(rhinokey).get('amt') : 0,
                                            BadDebtResultMap.containsKey(rhinokey) ? (Integer)BadDebtResultMap.get(rhinokey).get('file') : 0,
                                            BadDebtResultMap.containsKey(rhinokey) ? (double)BadDebtResultMap.get(rhinokey).get('amt') : 0,
                                            ShortFallResultMap.containsKey(rhinokey) ? (Integer)ShortFallResultMap.get(rhinokey).get('file') : 0,
                                            ShortFallResultMap.containsKey(rhinokey) ? (double)ShortFallResultMap.get(rhinokey).get('amt') : 0,
                                            OverAgeResultMap.containsKey(rhinokey) ? (Integer)OverAgeResultMap.get(rhinokey).get('file') : 0,
                                            OverAgeResultMap.containsKey(rhinokey) ? (double)OverAgeResultMap.get(rhinokey).get('amt') : 0,
                                            /* ===== RINO Values =====*/
                                            /* ===== ELFI Values =====*/
                                            result.containsKey(elfikey) ? (Integer)result.get(elfikey).get('file') : 0,
                                            closedOppResultMap.containsKey(elfikey) ? (Integer)closedOppResultMap.get(elfikey).get('file') : 0,
                                            result.containsKey(elfikey) ? (Integer)result.get(elfikey).get('opptyCount') : 0,
                                            result.containsKey(elfikey) ? (decimal)result.get(elfikey).get('amt') : 0,
                                            closedOppResultMap.containsKey(elfikey) ? (decimal)closedOppResultMap.get(elfikey).get('amt') : 0,
                                            BadDebtResultMap.containsKey(elfikey) ? (integer)BadDebtResultMap.get(elfikey).get('file') : 0,
                                            BadDebtResultMap.containsKey(elfikey) ? (double)BadDebtResultMap.get(elfikey).get('amt') : 0,
                                            ShortFallResultMap.containsKey(elfikey) ? (Integer)ShortFallResultMap.get(elfikey).get('file') : 0,
                                            ShortFallResultMap.containsKey(elfikey) ? (double)ShortFallResultMap.get(elfikey).get('amt') : 0,
                                            /* ===== ELFI Values =====*/
                                            
                                            /* ===== ALL (Rhino, Elfi, Consolidated) Value =====*/
                                            (result.containsKey(rhinokey) ? (Integer)result.get(rhinokey).get('file') : 0) +
                                            (result.containsKey(elfikey) ? (Integer)result.get(elfikey).get('file') : 0) +
                                            (result.containsKey(emptyKey) ? (Integer)result.get(emptyKey).get('file') : 0),
                                            
                                            (closedOppResultMap.containsKey(rhinokey) ? (Integer)closedOppResultMap.get(rhinokey).get('file') : 0) +
                                            (closedOppResultMap.containsKey(elfikey) ? (Integer)closedOppResultMap.get(elfikey).get('file') : 0) +
                                            (closedOppResultMap.containsKey(emptyKey) ? (Integer)closedOppResultMap.get(emptyKey).get('file') : 0),
                                            
                                            (result.containsKey(rhinokey) ? (Integer)result.get(rhinokey).get('opptyCount') : 0) +
                                            (result.containsKey(elfikey) ? (Integer)result.get(elfikey).get('opptyCount') : 0) +
                                            (result.containsKey(emptyKey) ? (Integer)result.get(emptyKey).get('opptyCount') : 0) ,
                                            
                                            (result.containsKey(rhinokey) ? (decimal)result.get(rhinokey).get('amt') : 0) +
                                            (result.containsKey(elfikey) ? (decimal)result.get(elfikey).get('amt') : 0) +
                                            (result.containsKey(emptyKey) ? (decimal)result.get(emptyKey).get('amt') : 0),
                                            
                                            (closedOppResultMap.containsKey(rhinokey) ? (decimal)closedOppResultMap.get(rhinokey).get('amt') : 0) +
                                            (closedOppResultMap.containsKey(elfikey) ? (decimal)closedOppResultMap.get(elfikey).get('amt') : 0) +
                                            (closedOppResultMap.containsKey(emptyKey) ? (decimal)closedOppResultMap.get(emptyKey).get('amt') : 0),

                                            (BadDebtResultMap.containsKey(rhinokey) ? (integer)BadDebtResultMap.get(rhinokey).get('file') : 0) +
                                            (BadDebtResultMap.containsKey(elfikey) ? (integer)BadDebtResultMap.get(elfikey).get('file') : 0) +
                                            (BadDebtResultMap.containsKey(emptyKey) ? (integer)BadDebtResultMap.get(emptyKey).get('file') : 0),

                                            (BadDebtResultMap.containsKey(rhinokey) ? (double)BadDebtResultMap.get(rhinokey).get('amt') : 0) +
                                            (BadDebtResultMap.containsKey(elfikey) ? (double)BadDebtResultMap.get(elfikey).get('amt') : 0) +
                                            (BadDebtResultMap.containsKey(emptyKey) ? (double)BadDebtResultMap.get(emptyKey).get('amt') : 0),

                                            
                                            (ShortFallResultMap.containsKey(rhinokey) ? (integer)ShortFallResultMap.get(rhinokey).get('file') : 0) +
                                            (ShortFallResultMap.containsKey(elfikey) ? (integer)ShortFallResultMap.get(elfikey).get('file') : 0) +
                                            (ShortFallResultMap.containsKey(emptyKey) ? (integer)ShortFallResultMap.get(emptyKey).get('file') : 0),

                                            (ShortFallResultMap.containsKey(rhinokey) ? (double)ShortFallResultMap.get(rhinokey).get('amt') : 0) +
                                            (ShortFallResultMap.containsKey(elfikey) ? (double)ShortFallResultMap.get(elfikey).get('amt') : 0) +
                                            (ShortFallResultMap.containsKey(emptyKey) ? (double)ShortFallResultMap.get(emptyKey).get('amt') : 0)
                                        );
                                            /* ===== ALL Value =====*/

                            w.wrapper2(
                                /* ===== ELFI VALUES =====*/
                                OverAgeResultMap.containsKey(elfikey) ? (Integer)OverAgeResultMap.get(elfikey).get('file') : 0,
                                OverAgeResultMap.containsKey(elfikey) ? (double)OverAgeResultMap.get(elfikey).get('amt') : 0,
                                /* ===== ELFI VALUES =====*/
                                /* ===== ALL Value =====*/
                                (OverAgeResultMap.containsKey(rhinokey) ? (Integer)OverAgeResultMap.get(rhinokey).get('file') : 0) +
                                (OverAgeResultMap.containsKey(elfikey) ? (Integer)OverAgeResultMap.get(elfikey).get('file') : 0) +
                                (OverAgeResultMap.containsKey(emptyKey) ? (Integer)OverAgeResultMap.get(emptyKey).get('file') : 0),

                                (OverAgeResultMap.containsKey(rhinokey) ? (double)OverAgeResultMap.get(rhinokey).get('amt') : 0) +
                                (OverAgeResultMap.containsKey(elfikey) ? (double)OverAgeResultMap.get(elfikey).get('amt') : 0) +
                                (OverAgeResultMap.containsKey(emptyKey) ? (double)OverAgeResultMap.get(emptyKey).get('amt') : 0)
                                /* ===== ALL Value =====*/
                            );
                    wrapers.add(w);
                }
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