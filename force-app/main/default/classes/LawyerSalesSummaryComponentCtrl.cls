/**
 * @File Name          : LawyerSalesSummaryComponentCtrl.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : fahad.khan@toptal.com
 * @Last Modified On   : 09-21-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    07/04/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class LawyerSalesSummaryComponentCtrl {
    @AuraEnabled
    public static list<Wrapper> getAmountGroupByLawyer(String startDate, String endDate, String field, 
    String direction, List<string> BusinessUnit, String searchByName, List<String> typeOfLoan){
        try{

            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);           
            
            String payment = 'Payment';
            String loanPayout = 'Loan Payout';
            String partialPayment = 'Partial Payment';
            String paymentShortfall = 'Payment Shortfall';
            String paymentSurplus = 'Payment Surplus';
            string eTransfer = 'e-Transfer';
            string Cheque = 'Cheque';
            string AdminFee = 'Admin Fee';
            String ClosedWithLoan = 'Closed With Loan';
            String closedPaid = 'Closed - Paid';
            String closedShortfall = 'Closed - Shortfall';
            String closedSurplus = 'Closed - Surplus';
            String badDebt = 'Bad Debt';
            String clientRebate = 'Client Rebate';
            String activePartialPayment = 'Active - Partial Payment';
            
            // for sorting 
            if(field == 'Lawyer'){
                field = 'Opportunity__r.Lawyer__r.name';
            }else if(field == 'Firm'){
                field = 'Opportunity__r.Law_firm__r.name';
            }else if(field == 'Files'){
                field = 'COUNT_DISTINCT(Opportunity__r.AccountId)'; 
            }else if(field == 'opptyCount'){
                field = 'COUNT_DISTINCT(Opportunity__c)';
            }else if(field == 'Amount'){
                field = 'SUM(Amount__c)'; 
            }

                            
            Integer FileTotal = 0;
            Integer ActiveTotal = 0;
            Integer ClosedTotal = 0;
            Integer BadDebtTotal = 0;
            Integer ShortfallTotal = 0;
            Integer OverageTotal = 0;
            Integer OpptyTotal = 0;
            Integer PartialTotal = 0;

            map<string, wrapper> agrMap = new map<string, wrapper>();
            Set<String> lawyerIdsSet = new Set<String>();
            List<AggregateResult> aggResult = new List<AggregateResult>();
            List<AggregateResult> TotalAggrResult = new List<AggregateResult>();
            
            String MainQuery = 'Select Opportunity__r.Lawyer__c lawyerId, ';
            MainQuery += ' Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, ';
            MainQuery += ' Opportunity__r.Law_firm__c firmId, '; 
            MainQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount, ';
            MainQuery += ' SUM(Amount__c) amt ';
            MainQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt '; 
            MainQuery += ' AND Date__c <= :endDt'; 
            MainQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer) ';
            MainQuery += ' OR (Payment_Method__c =:Cheque)';
            MainQuery += ' OR (Payment_Method__c =:AdminFee))';
            MainQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan ';
            MainQuery += ' AND Is_Rejected__c = false';
            MainQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit ';
            MainQuery += ' AND Opportunity__r.Lawyer__c != null';
            MainQuery += !String.isEmpty(searchByName) && searchByName != null 
            ? ' AND (Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
            MainQuery += !String.isEmpty(searchByName) && searchByName != null 
            ? ' OR Opportunity__r.Lawyer__r.Name_Formula__c LIKE \'%' + searchByName + '%\')'  : '';
            MainQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, '; 
            MainQuery += ' Opportunity__r.Law_firm__c ';
            MainQuery += ' order by Opportunity__r.Lawyer__r.name NULLS LAST';
            // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count

            aggResult = Database.query(MainQuery);
            
            if(!aggResult.isEmpty()){
                
                for(AggregateResult agr : aggResult){
                    lawyerIdsSet.add(String.ValueOf(agr.get('lawyerId')));
                }
                
                for(AggregateResult agr : aggResult){ 
                    
                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));

                    if(agrMap.containsKey(key)){
                       // if province exists 
                       wrapper w = agrMap.get(key);

                       w.OpptyCount = 0;
                       w.PrincipalAdvanced = 0;
                       w.ClosedAmount = 0;

                        w.OpptyCount += agr.get('opptyCount') != null ? Integer.valueof(agr.get('opptyCount')) : 0;
                        w.PrincipalAdvanced += agr.get('amt') != null ? Double.valueof(agr.get('amt')) : 0;
                        w.ClosedAmount = 0;

                        agrMap.put(key, w);
                        
                    }else{
                        // new province
                        wrapper w;
                        w = new wrapper(String.ValueOf(agr.get('lawyer')), String.ValueOf(agr.get('lawyerId')),
                                        String.ValueOf(agr.get('firm')), String.ValueOf(agr.get('firmId')));

                        w.OpptyCount += agr.get('opptyCount') != null ? Integer.valueof(agr.get('opptyCount')) : 0;
                        w.PrincipalAdvanced += agr.get('amt') != null ? Double.valueof(agr.get('amt')) : 0;
                        w.ClosedAmount = 0; 

                        agrMap.put(key, w);
                    }
                }
            }
            // For total
            MainQuery = MainQuery.substringBefore('Group by');
            MainQuery = MainQuery.replace('Opportunity__r.Lawyer__c lawyerId,', '');
            MainQuery = MainQuery.replace('Opportunity__r.Lawyer__r.Name lawyer,', '');
            MainQuery = MainQuery.replace('Opportunity__r.Law_firm__r.name firm,', '');
            MainQuery = MainQuery.replace('Opportunity__r.Law_firm__c firmId,', '');
            TotalAggrResult = Database.query(MainQuery);

            if(!TotalAggrResult.isEmpty()) OpptyTotal = TotalAggrResult[0].get('opptyCount') != null ?
            (Integer)TotalAggrResult[0].get('opptyCount') : 0;
            

                // Active/Open file count
                
                string ActiveFileQuery = 'Select Opportunity__r.Lawyer__c lawyerId, ';
                ActiveFileQuery += ' Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, ';
                ActiveFileQuery += ' Opportunity__r.Law_firm__c firmId, ';
                ActiveFileQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file ';
                ActiveFileQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt ';
                ActiveFileQuery += ' AND Date__c <= :endDt ';
                ActiveFileQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan ';
                ActiveFileQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan ';
                ActiveFileQuery += ' AND Opportunity__r.Stage_Status__c LIKE \'%Active%\' ';
                ActiveFileQuery += ' AND Opportunity__r.Stage_Status__c !=:activePartialPayment ';
                ActiveFileQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit ';
                ActiveFileQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                ActiveFileQuery += ' AND Opportunity__r.Lawyer__c != null';
                ActiveFileQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, '; 
                ActiveFileQuery += ' Opportunity__r.Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count
                
                aggResult = Database.query(ActiveFileQuery);
                for(AggregateResult agr : aggResult){ 
                    
                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));

                    if(agrMap.containsKey(key)){

                        wrapper w = agrMap.get(key); 

                        w.ActiveFileCount = 0;
                        w.ActiveFileCount += agr.get('file') != null ? integer.valueof(agr.get('file')) : 0;

                        agrMap.put(key, w);                        
                    }
                }

                // For total
                ActiveFileQuery = ActiveFileQuery.substringBefore('Group by');
                ActiveFileQuery = ActiveFileQuery.replace('Opportunity__r.Lawyer__c lawyerId,', '');
                ActiveFileQuery = ActiveFileQuery.replace('Opportunity__r.Lawyer__r.Name lawyer,', '');
                ActiveFileQuery = ActiveFileQuery.replace('Opportunity__r.Law_firm__r.name firm,', '');
                ActiveFileQuery = ActiveFileQuery.replace('Opportunity__r.Law_firm__c firmId,', '');
                TotalAggrResult = Database.query(ActiveFileQuery);

                if(!TotalAggrResult.isEmpty()) ActiveTotal = TotalAggrResult[0].get('file') != null ?
                (Integer)TotalAggrResult[0].get('file') : 0;
                  
                string ClosedAmountQuery = 'Select '; 
                ClosedAmountQuery += ' Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, ';
                ClosedAmountQuery += ' Opportunity__r.Law_firm__r.name firm, '; 
                ClosedAmountQuery += ' Opportunity__r.Law_firm__c firmId, ';
                ClosedAmountQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                ClosedAmountQuery += ' SUM(Amount__c) amt, SUM(Interest_Repaid__c) interest, SUM(Principal_Repaid__c) principal';
                ClosedAmountQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                ClosedAmountQuery += ' AND Date__c <= :endDt';
                ClosedAmountQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                ClosedAmountQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                ClosedAmountQuery += ' AND Payment_Method__c =:payment';  
                ClosedAmountQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment OR ';
                ClosedAmountQuery += ' Reference_Notes__c =:paymentSurplus)'; 
                //strQuery += ' AND (Opportunity__r.Stage_Status__c =:closedPaid OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
                ClosedAmountQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                ClosedAmountQuery += ' AND Is_Rejected__c = false';
                ClosedAmountQuery += ' AND Opportunity__r.Lawyer__c != null';
                ClosedAmountQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                ClosedAmountQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, ';
                ClosedAmountQuery += ' Opportunity__r.Law_firm__r.name, '; 
                ClosedAmountQuery += ' Opportunity__r.Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count
                
                
                aggResult = Database.query(ClosedAmountQuery);

                for(AggregateResult agr : aggResult){  
                    
                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));

                    if(agrMap.containsKey(key)){

                        // if province exists 
                        wrapper w = agrMap.get(key);

                        w.ClosedAmount = 0;
                        w.PrincipalRepaid = 0;
                        w.InterestRepaid = 0;

                        w.ClosedAmount += agr.get('amt') != null ? Double.valueof(agr.get('amt')) : 0;
                        w.PrincipalRepaid += agr.get('principal') != null ? Double.valueOf(agr.get('principal')) : 0;
                        w.InterestRepaid += agr.get('interest')!= null ? Double.valueof(agr.get('interest')) : 0;

                        agrMap.put(key, w);                        
                    }
                }
                
                // Closed file Count
                
                string ClosedFileQuery = 'Select ';
                ClosedFileQuery += ' Opportunity__r.Lawyer__c lawyerId, ';
                ClosedFileQuery += ' Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, ';
                ClosedFileQuery += ' Opportunity__r.Law_firm__c firmId, ';
                ClosedFileQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file ';
                ClosedFileQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt ';
                ClosedFileQuery += ' AND Date__c <= :endDt ';
                ClosedFileQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan ';
                ClosedFileQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan ';
                ClosedFileQuery += ' AND Opportunity__r.Stage_Status__c LIKE \'%Closed%\' ';
                ClosedFileQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit ';
                ClosedFileQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet ';
                ClosedFileQuery += ' AND Opportunity__r.Lawyer__c != null';
                ClosedFileQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, ';
                ClosedFileQuery += ' Opportunity__r.Law_firm__r.name, '; 
                ClosedFileQuery += ' Opportunity__r.Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count

                aggResult = Database.query(ClosedFileQuery);
                
                for(AggregateResult agr : aggResult){

                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));
                    
                    if(agrMap.containsKey(key)){
                        
                        wrapper w = agrMap.get(key);

                        w.ClosedFileCount = 0; 
                        w.ClosedFileCount += agr.get('file') != null ? integer.valueof(agr.get('file')) : 0; 

                        agrMap.put(key, w);                        
                    }
                }

                // For total
                ClosedFileQuery = ClosedFileQuery.substringBefore('Group by');
                ClosedFileQuery = ClosedFileQuery.replace('Opportunity__r.Lawyer__c lawyerId,', '');
                ClosedFileQuery = ClosedFileQuery.replace('Opportunity__r.Lawyer__r.Name lawyer,', '');
                ClosedFileQuery = ClosedFileQuery.replace('Opportunity__r.Law_firm__r.name firm,', '');
                ClosedFileQuery = ClosedFileQuery.replace('Opportunity__r.Law_firm__c firmId,', '');
                TotalAggrResult = Database.query(ClosedFileQuery);

                if(!TotalAggrResult.isEmpty()) ClosedTotal = TotalAggrResult[0].get('file') != null ?
                (Integer)TotalAggrResult[0].get('file') : 0;
                
                // Bad Debt
                
                string BadDebtQuery = 'Select ';
                BadDebtQuery += ' Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, ';
                BadDebtQuery += ' Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                BadDebtQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount, ';
                BadDebtQuery += ' SUM(Amount__c) amt, SUM(Interest_Repaid__c) interest ';
                BadDebtQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt ';
                BadDebtQuery += ' AND Date__c <= :endDt ';
                BadDebtQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan ';
                //strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                //strQuery += ' AND Payment_Method__c =:payment';  
                BadDebtQuery += ' AND Reference_Notes__c =:badDebt ';                 
                BadDebtQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet ';
                BadDebtQuery += ' AND Is_Rejected__c = false ';
                BadDebtQuery += ' AND Opportunity__r.Lawyer__c != null';
                BadDebtQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit ';
                BadDebtQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, '; 
                BadDebtQuery += ' Opportunity__r.Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count
                
                
            	aggResult = Database.query(BadDebtQuery);
                
                for(AggregateResult agr : aggResult){

                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));
                    
                    if(agrMap.containsKey(key)){
                        // if province exists 
                        wrapper w = agrMap.get(key);

                            w.BadDebtAmount = 0;
                            w.BadDebtFileCount = 0;
                            
                            w.BadDebtAmount += agr.get('amt') != null ? Double.valueof(agr.get('amt')) : 0;
                            w.BadDebtFileCount += agr.get('file') != null ? integer.valueof(agr.get('file')) : 0;
                        	//w.InterestRepaid += Double.valueof(agr.get('interest')) != null? Double.valueof(agr.get('interest')) : 0;
                        
                        agrMap.put(key, w);
                        
                    }
                }

                // For total
                BadDebtQuery = BadDebtQuery.substringBefore('Group by');
                BadDebtQuery = BadDebtQuery.replace('Opportunity__r.Lawyer__c lawyerId,', '');
                BadDebtQuery = BadDebtQuery.replace('Opportunity__r.Lawyer__r.Name lawyer,', '');
                BadDebtQuery = BadDebtQuery.replace('Opportunity__r.Law_firm__r.name firm,', '');
                BadDebtQuery = BadDebtQuery.replace('Opportunity__r.Law_firm__c firmId,', '');
                TotalAggrResult = Database.query(BadDebtQuery);

                if(!TotalAggrResult.isEmpty()) BadDebtTotal = TotalAggrResult[0].get('file') != null ?
                (Integer)TotalAggrResult[0].get('file') : 0;
                
                // ShortFall
                
                string ShortfallQuery = 'Select ';
                ShortfallQuery += ' Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, ';
                ShortfallQuery += ' Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                ShortfallQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount, ';
                ShortfallQuery += ' SUM(Amount__c) amt, SUM(Interest_Repaid__c) interest';
                ShortfallQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                ShortfallQuery += ' AND Date__c <= :endDt';
                ShortfallQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                ShortfallQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                ShortfallQuery += ' AND Payment_Method__c =:payment';
                ShortfallQuery += ' AND Reference_Notes__c =:paymentShortfall';                 
                ShortfallQuery += ' AND Opportunity__r.Stage_Status__c =:closedShortfall';
                ShortfallQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                ShortfallQuery += ' AND Is_Rejected__c = false';
                ShortfallQuery += ' AND Opportunity__r.Lawyer__c != null';
                ShortfallQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                ShortfallQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, '; 
                ShortfallQuery += ' Opportunity__r.Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count
                
                
            	aggResult = Database.query(ShortfallQuery);
                
                for(AggregateResult agr : aggResult){

                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));
                    
                    if(agrMap.containsKey(key)){
                        // if province exists 
                        wrapper w = agrMap.get(key);

                            w.ShortfallAmount = 0;
                            w.ShortfallFileCount = 0;
                            
                            w.ShortfallAmount += agr.get('amt') != null ? Double.valueof(agr.get('amt')) : 0;
                            w.ShortfallFileCount += agr.get('file') != null ? integer.valueof(agr.get('file')) : 0;
                        	//w.InterestRepaid += Double.valueof(agr.get('interest')) != null? Double.valueof(agr.get('interest')) : 0;
                        
                        agrMap.put(key, w);
                        
                    }
                }

                // For total
                ShortfallQuery = ShortfallQuery.substringBefore('Group by');
                ShortfallQuery = ShortfallQuery.replace('Opportunity__r.Lawyer__c lawyerId,', '');
                ShortfallQuery = ShortfallQuery.replace('Opportunity__r.Lawyer__r.Name lawyer,', '');
                ShortfallQuery = ShortfallQuery.replace('Opportunity__r.Law_firm__r.name firm,', '');
                ShortfallQuery = ShortfallQuery.replace('Opportunity__r.Law_firm__c firmId,', '');
                TotalAggrResult = Database.query(ShortfallQuery);

                if(!TotalAggrResult.isEmpty()) ShortfallTotal = TotalAggrResult[0].get('file') != null ?
                (Integer)TotalAggrResult[0].get('file') : 0;
                
                // Overage

                string OverageQuery = 'Select ';
                OverageQuery += ' Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, ';
                OverageQuery += ' Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                OverageQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount, ';
                OverageQuery += ' SUM(Amount__c) amt, SUM(Interest_Repaid__c) interest ';
                OverageQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt ';
                OverageQuery += ' AND Date__c <= :endDt ';
                OverageQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan ';
                OverageQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan ';
                OverageQuery += ' AND Payment_Method__c =:payment ';  
                OverageQuery += ' AND Reference_Notes__c =:paymentSurplus '; 
                OverageQuery += ' AND Opportunity__r.Stage_Status__c =:closedSurplus ';
                OverageQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                OverageQuery += ' AND Is_Rejected__c = false ';
                OverageQuery += ' AND Opportunity__r.Lawyer__c != null';
                OverageQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit ';
                OverageQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, '; 
                OverageQuery += ' Opportunity__r.Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count
                
                
            	aggResult = Database.query(OverageQuery);
                
                for(AggregateResult agr : aggResult){

                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));
                    
                    if(agrMap.containsKey(key)){
                        // if province exists 
                        wrapper w = agrMap.get(key);

                            w.OverageAmount = 0;
                            w.OverageFileCount = 0;
                            
                            w.OverageAmount += agr.get('amt') != null ? Double.valueof(agr.get('amt')) : 0;
                            w.OverageFileCount += agr.get('file') != null ? integer.valueof(agr.get('file')) : 0;
                        	//w.InterestRepaid += Double.valueof(agr.get('interest')) != null? Double.valueof(agr.get('interest')) : 0;
                        
                        agrMap.put(key, w);
                        
                    }
                }

                // For total
                OverageQuery = OverageQuery.substringBefore('Group by');
                OverageQuery = OverageQuery.replace('Opportunity__r.Lawyer__c lawyerId,', '');
                OverageQuery = OverageQuery.replace('Opportunity__r.Lawyer__r.Name lawyer,', '');
                OverageQuery = OverageQuery.replace('Opportunity__r.Law_firm__r.name firm,', '');
                OverageQuery = OverageQuery.replace('Opportunity__r.Law_firm__c firmId,', '');
                TotalAggrResult = Database.query(OverageQuery);

                if(!TotalAggrResult.isEmpty()) OverageTotal = TotalAggrResult[0].get('file') != null ?
                (Integer)TotalAggrResult[0].get('file') : 0;
                
                // Admin Fee Received
                
                string AdminQuery = 'Select Lawyer__c lawyerId, ';
                AdminQuery += ' Lawyer__r.Name lawyer, Law_firm__r.name firm, Law_firm__c firmId,';
                AdminQuery += ' SUM(Admin_Fee_Received__c) adminfeeRec';
                AdminQuery += ' FROM Opportunity WHERE Opportunity_Closed_Date__c >= :startDt';
                AdminQuery += ' AND Opportunity_Closed_Date__c <= :endDt';
                AdminQuery += ' AND Lawyer__c in :lawyerIdsSet';
                AdminQuery += (typeOfLoan.isEmpty())? '' : ' AND Type_of_Loan__c IN :typeOfLoan';
                AdminQuery += ' AND StageName =:ClosedWithLoan';
                AdminQuery += ' AND Lawyer__c != null';
                AdminQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Account.Business_Unit__c IN :BusinessUnit';
                AdminQuery += ' Group by Lawyer__c, Lawyer__r.Name, Law_firm__r.name, '; 
                AdminQuery += ' Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count
                
                aggResult = Database.query(AdminQuery);
                
                for(AggregateResult agr : aggResult){

                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));
                    
                    if(agrMap.containsKey(key)){
                        // if province exists 
                        wrapper w = agrMap.get(key);

                            w.AdminFeeReceived = 0;
                            
                            w.AdminFeeReceived += agr.get('adminfeeRec') != null ? 
                            Double.valueof(agr.get('adminfeeRec')) : 0;
                        
                        agrMap.put(key, w);
                        
                    }
                }

                // Total file count

                
                //string FileCountQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, ';
                string FileCountQuery = 'Select Opportunity__r.Lawyer__c lawyerId, ';
                FileCountQuery += ' Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, ';
                FileCountQuery += ' Opportunity__r.Law_firm__c firmId, ';
                FileCountQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file';
                FileCountQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                FileCountQuery += ' AND Date__c <= :endDt';
		        FileCountQuery += ' AND Opportunity__r.RecordType.Name = \'Client Opportunity Record Type\' ';
                FileCountQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                FileCountQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                FileCountQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                FileCountQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                FileCountQuery += ' AND Opportunity__r.Lawyer__c != null';
                FileCountQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, '; 
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count 
                FileCountQuery += ' Opportunity__r.Law_firm__c ';
                
                aggResult = Database.query(FileCountQuery);
                for(AggregateResult agr : aggResult){

                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));
                    
                    if(agrMap.containsKey(key)){
                        
                        wrapper w = agrMap.get(key);
                        
                        w.FileCount = 0;
                        w.FileCount += agr.get('file') != null ? integer.valueof(agr.get('file')) : 0;
                        
                        agrMap.put(key, w);                        
                    }
                }

                // For total
                FileCountQuery = FileCountQuery.substringBefore('Group by');
                FileCountQuery = FileCountQuery.replace('Opportunity__r.Lawyer__c lawyerId,', '');
                FileCountQuery = FileCountQuery.replace('Opportunity__r.Lawyer__r.Name lawyer,', '');
                FileCountQuery = FileCountQuery.replace('Opportunity__r.Law_firm__r.name firm,', '');
                FileCountQuery = FileCountQuery.replace('Opportunity__r.Law_firm__c firmId,', '');
                TotalAggrResult = Database.query(FileCountQuery);

                if(!TotalAggrResult.isEmpty()) FileTotal = TotalAggrResult[0].get('file') != null ?
                (Integer)TotalAggrResult[0].get('file') : 0;
                
                // Active Partial Payment file count

                string PartialPaymentQuery = 'Select ';
                PartialPaymentQuery += ' Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, ';
                PartialPaymentQuery += ' Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                PartialPaymentQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file';
                PartialPaymentQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                PartialPaymentQuery += ' AND Date__c <= :endDt';
                PartialPaymentQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                PartialPaymentQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                PartialPaymentQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                PartialPaymentQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                PartialPaymentQuery += ' AND Opportunity__r.Lawyer__c != null';
                PartialPaymentQuery += ' AND Opportunity__r.Stage_Status__c =:activePartialPayment';
                PartialPaymentQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, '; 
                PartialPaymentQuery += ' Opportunity__r.Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count
                
                aggResult = Database.query(PartialPaymentQuery);
                for(AggregateResult agr : aggResult){

                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));
                    
                    if(agrMap.containsKey(key)){
                        
                        wrapper w = agrMap.get(key);
                        
                        w.ActivePartialFileCount = 0;
                        w.ActivePartialFileCount += agr.get('file') != null ? integer.valueof(agr.get('file')) : 0;
                        
                        agrMap.put(key, w);                        
                    }
                }

                // For total
                PartialPaymentQuery = PartialPaymentQuery.substringBefore('Group by');
                PartialPaymentQuery = PartialPaymentQuery.replace('Opportunity__r.Lawyer__c lawyerId,', '');
                PartialPaymentQuery = PartialPaymentQuery.replace('Opportunity__r.Lawyer__r.Name lawyer,', '');
                PartialPaymentQuery = PartialPaymentQuery.replace('Opportunity__r.Law_firm__r.name firm,', '');
                PartialPaymentQuery = PartialPaymentQuery.replace('Opportunity__r.Law_firm__c firmId,', '');
                TotalAggrResult = Database.query(PartialPaymentQuery);

                if(!TotalAggrResult.isEmpty()) PartialTotal = TotalAggrResult[0].get('file') != null ?
                (Integer)TotalAggrResult[0].get('file') : 0;
                
                // Closed Principal Advance
                
                string ClosedPrincipalQuery = 'Select ';
                ClosedPrincipalQuery += ' Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, ';
                ClosedPrincipalQuery += ' Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                ClosedPrincipalQuery += ' SUM(Amount__c) amt';
                ClosedPrincipalQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                ClosedPrincipalQuery += ' AND Date__c <= :endDt';
                ClosedPrincipalQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                ClosedPrincipalQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
                ClosedPrincipalQuery += ' OR (Payment_Method__c =:Cheque)';
                ClosedPrincipalQuery += ' OR (Payment_Method__c =:AdminFee))';
                ClosedPrincipalQuery += ' AND Opportunity__r.Stage_Status__c LIKE \'%Closed%\'';
                ClosedPrincipalQuery += (BusinessUnit.isEmpty()) ? '' : 
                ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                ClosedPrincipalQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                ClosedPrincipalQuery += ' AND Opportunity__r.Lawyer__c != null';
                ClosedPrincipalQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, '; 
                ClosedPrincipalQuery += ' Opportunity__r.Law_firm__r.name, '; 
                ClosedPrincipalQuery += ' Opportunity__r.Law_firm__c ';
                // 19 November 2020: Business Unit has been removed from grouping because it is not in columns and affects the file count

                aggResult = Database.query(ClosedPrincipalQuery);
                
                for(AggregateResult agr : aggResult){

                    String key = String.ValueOf(agr.get('lawyer')) + '-' + String.ValueOf(agr.get('lawyerId')) + '-'
                    + String.ValueOf(agr.get('firm')) + '-' + String.ValueOf(agr.get('firmId'));
                    
                    if(agrMap.containsKey(key)){
                        
                        wrapper w = agrMap.get(key);

                        w.PrincipalAdvancedClosed = 0;
                        w.PrincipalAdvancedClosed += agr.get('amt') != null ? Double.valueof(agr.get('amt')) : 0;

                        agrMap.put(key, w);                        
                    }
                }
                
                list<Wrapper> finalWrapper = new list<Wrapper>(agrMap.values());
                
                for(Wrapper w : finalWrapper){
                    w.LawyerIds = JSON.serialize(lawyerIdsSet);
                    w.NetAmount = (((w.InterestRepaid + w.AdminFeeReceived + w.OverageAmount) - 
                    w.ShortfallAmount) - w.BadDebtAmount);
                    w.PrincipalAdvancedOpen = w.PrincipalAdvanced - w.PrincipalAdvancedClosed;
                    w.ROI = (w.PrincipalAdvancedClosed != null && w.PrincipalAdvancedClosed != 0)? 
                    (w.ClosedAmount / w.PrincipalAdvancedClosed) : 0;

                    // Totals
                    w.FileCountTotal = FileTotal;
                    w.ActiveFileTotal = ActiveTotal;
                    w.ClosedFileTotal = ClosedTotal;
                    w.BadDebtFileTotal = BadDebtTotal;
                    w.ShortfallFileTotal = ShortfallTotal;
                    w.OverageFileTotal = OverageTotal;
                    w.OpptyCountTotal = OpptyTotal;
                    w.ActivePartialFileTotal = PartialTotal;
                }
                
                if(!finalWrapper.isEmpty()) return finalWrapper;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

        return null;
    }
    
    @AuraEnabled
    public static list<Drawdown__c> getDrawdownLawyerSalesCongaURLs(){
        
        list<Drawdown__c> drawdown_conga_url = [select id, Conga_Lawyer_Sales_Summary_View_All__c,Conga_Lawyer_Sales_Summary_Print_All__c from Drawdown__c limit 1];
    	return drawdown_conga_url;
    }

    @AuraEnabled
    public static void saveCustomSettings(String startDate, String endDate, List<String> businessUnit, String searchByName){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Lawyer_Sales_Summary_Report__c lsr = Lawyer_Sales_Summary_Report__c.getOrgDefaults();
            
            lsr.End_date__c = endDt;
            lsr.Start_Date__c = startDt;
            lsr.BusinessUnit__c = string.join(businessUnit, '|');
            lsr.Search_By_Name__c = searchByName;
            
            update lsr; 
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static void saveBusinessUnitCustomSettings(String BusinessUnit){
        try{
            
           // Bad_Debt_Summary_Report__c bdr = Bad_Debt_Summary_Report__c.getInstance(UserInfo.getUserId());
            Lawyer_Sales_Summary_Report__c lsr = Lawyer_Sales_Summary_Report__c.getOrgDefaults();
            
            lsr.BusinessUnit__C = BusinessUnit;
            
            upsert lsr;

        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Lawyer_Sales_Summary_Report__c getCustomSetting(){
        Lawyer_Sales_Summary_Report__c Lsr = Lawyer_Sales_Summary_Report__c.getOrgDefaults();
        return Lsr;
    }
    
    @AuraEnabled
    public static String getLawyerName(String recordId){
        String name = '';
        if(recordId != null){
            Contact con = [SELECT Id, Name_Formula__c, Name 
                           FROM Contact
                           WHERE Id = :recordId];
            if(con != null) name = con.Name_Formula__c;
        }
        
        return name;
            
    }
    
    public class Wrapper {
        @AuraEnabled
        public string lawyer {get; set;}
        @AuraEnabled
        public string lawyerId {get; set;}
        @AuraEnabled
        public string firm {get; set;}
        @AuraEnabled
        public string firmId {get; set;}
        @AuraEnabled
        public integer FileCount {get; set;}
        @AuraEnabled
        public integer ActiveFileCount {get; set;}
        @AuraEnabled
        public integer ActivePartialFileCount {get; set;}
        @AuraEnabled
        public integer ClosedFileCount {get; set;}
        @AuraEnabled
        public integer ShortfallFileCount {get; set;}
        @AuraEnabled
        public integer BadDebtFileCount {get; set;}
        @AuraEnabled
        public integer OverageFileCount {get; set;}
        @AuraEnabled
        public integer OpptyCount {get; set;}
        @AuraEnabled
        public decimal ClosedAmount {get; set;}
        @AuraEnabled
        public decimal ShortfallAmount {get; set;}
        @AuraEnabled
        public decimal BadDebtAmount {get; set;}
        @AuraEnabled
        public decimal OverageAmount {get; set;}
        @AuraEnabled
        public decimal PrincipalAdvanced {get; set;}
        @AuraEnabled
        public decimal PrincipalAdvancedOpen {get; set;}
        @AuraEnabled
        public decimal PrincipalAdvancedClosed {get; set;}
        @AuraEnabled
        public decimal PrincipalRepaid {get; set;}
        @AuraEnabled
        public decimal InterestRepaid {get; set;}
        @AuraEnabled
        public decimal AdminFeeReceived {get; set;}
        @AuraEnabled
        public decimal NetAmount {get; set;}
        @AuraEnabled
        public decimal ROI {get; set;}
        @AuraEnabled
        public string LawyerIds {get; set;}

        // Totals
        @AuraEnabled
        public integer FileCountTotal {get; set;}
        @AuraEnabled
        public integer ActiveFileTotal {get; set;}
        @AuraEnabled
        public integer ClosedFileTotal {get; set;}
        @AuraEnabled
        public integer BadDebtFileTotal {get; set;}
        @AuraEnabled
        public integer ShortfallFileTotal {get; set;}
        @AuraEnabled
        public integer OverageFileTotal {get; set;}
        @AuraEnabled
        public integer OpptyCountTotal {get; set;}
        @AuraEnabled
        public integer ActivePartialFileTotal {get; set;}
        
        wrapper(string l, string lawrId, string f, string frmId){
            
            lawyer = l;
            lawyerId = lawrId;
            firm = f;
            firmId = frmId;
            
            ActiveFileCount = 0;
            ClosedFileCount = 0;
            OpptyCount = 0;
            ClosedAmount = 0;
            PrincipalAdvancedOpen = 0.0;
            PrincipalAdvancedClosed = 0.0;
            PrincipalAdvanced = 0.0;
            
            ShortfallFileCount = 0;
            BadDebtFileCount = 0;
            OverageFileCount = 0;
            
            ShortfallAmount = 0.0;
            BadDebtAmount = 0.0;
            OverageAmount = 0.0;
            FileCount = 0;
            InterestRepaid = 0.0;
            AdminFeeReceived = 0.0;
            ActivePartialFileCount = 0;
            NetAmount = 0.0;
            PrincipalRepaid = 0.0;
            ROI = 0.0;
            LawyerIds = '';

            FileCountTotal = 0;
            ActiveFileTotal = 0;
            ClosedFileTotal = 0;
            BadDebtFileTotal = 0;
            ShortfallFileTotal = 0;
            OverageFileTotal = 0;
            OpptyCountTotal = 0;
            ActivePartialFileTotal = 0;

        }
        
    }
}