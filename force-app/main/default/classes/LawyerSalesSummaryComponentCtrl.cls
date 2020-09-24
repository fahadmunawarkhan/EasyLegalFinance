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
    public static list<Wrapper> getAmountGroupByLawyer(String startDate, String endDate, String field, String direction, List<string> BusinessUnit, String searchByName, List<String> typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = '';            
            
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
            
            strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, '; 
            strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount, ';
            strQuery += ' SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
            strQuery += ' OR (Payment_Method__c =:Cheque)';
            strQuery += ' OR (Payment_Method__c =:AdminFee))';
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
            strQuery += ' AND Opportunity__r.Lawyer__c != \'\'';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Opportunity__r.Lawyer__r.Name_Formula__c LIKE \'%' + searchByName + '%\')'  : '';
            strQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c';
            strQuery += ' order by ' + field + ' ' + direction + ' NULLS LAST';

            List<AggregateResult> aggResult = Database.query(strQuery);
            
            if(!aggResult.isEmpty()){
                
                Set<String> lawyerIdsSet = new Set<String>();
                for(AggregateResult agr : aggResult){
                    lawyerIdsSet.add(String.ValueOf(agr.get('lawyerId')));
                }

                map<string, wrapper> agrMap = new map<string, wrapper>();
                
                for(AggregateResult agr : aggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                       // if province exists 
                       wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                        
                        w.OpptyCount += Integer.valueof(agr.get('opptyCount'));
                        w.Amount += Double.valueof(agr.get('amt'));
                        w.ClosedAmount = 0; 
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);
                        
                    }else{
                        // new province
                        wrapper w;
                        w = new wrapper(String.ValueOf(agr.get('lawyer')), String.ValueOf(agr.get('lawyerId')),
                                        String.ValueOf(agr.get('firm')), String.ValueOf(agr.get('firmId')),
                                        0,
                                        0,
                                        Integer.valueof(agr.get('opptyCount')),                                            
                                        Double.valueof(agr.get('amt')));
                        w.ClosedAmount = 0;
                        w.ClosedAmount = 0;
                        agrMap.put(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);
                    }
                }
                
                /**
                 * Active/Open file count
                 * */
                strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file';
                strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                strQuery += ' AND Date__c <= :endDt';
                strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                strQuery += ' AND Opportunity__r.Stage_Status__c LIKE \'%Active%\'';
                strQuery += ' AND Opportunity__r.Stage_Status__c !=:activePartialPayment';
                strQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                strQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                strQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c';
                
                List<AggregateResult> aggResultOpenOpps = Database.query(strQuery);
                for(AggregateResult agr : aggResultOpenOpps){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                        
                         w.ActiveFileCount += integer.valueof(agr.get('file'));
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);                        
                    }
                }
                system.debug('===>');
                system.debug(aggResultOpenOpps);
                system.debug('===>');

                String closedOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId,';
                closedOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                closedOppQuery += ' SUM(Amount__c) amt, SUM(Interest_Repaid__c) interest';
                closedOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                closedOppQuery += ' AND Date__c <= :endDt';
                closedOppQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                closedOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                closedOppQuery += ' AND Payment_Method__c =:payment';  
                closedOppQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment)'; 
                //closedOppQuery += ' AND (Opportunity__r.Stage_Status__c =:closedPaid OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
                closedOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                closedOppQuery += ' AND Is_Rejected__c = false';
                closedOppQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                closedOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c';
                
                
            	List<AggregateResult> closedOppAggResult = Database.query(closedOppQuery);
                
                for(AggregateResult agr : closedOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                        
                            w.ClosedAmount += Double.valueof(agr.get('amt'));
                            //w.ClosedFileCount += integer.valueof(agr.get('file'));
                        	w.InterestRepaid += Double.valueof(agr.get('interest')) != null? Double.valueof(agr.get('interest')) : 0;
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);
                        
                    }
                }
                
                /**
                 * Closed file Count
                 * */
                
                strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file';
                strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                strQuery += ' AND Date__c <= :endDt';
                strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                strQuery += ' AND Opportunity__r.Stage_Status__c LIKE \'%Closed%\'';
                strQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                strQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                strQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c';
                closedOppAggResult.clear();
                closedOppAggResult = Database.query(strQuery);
                
                for(AggregateResult agr : closedOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                        
                        w.ClosedFileCount += integer.valueof(agr.get('file'));
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);                        
                    }
                }
                
                /**
                 * Bad Debt
                 * */
                String badDebtOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId,';
                badDebtOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                badDebtOppQuery += ' SUM(Amount__c) amt, SUM(Interest_Repaid__c) interest';
                badDebtOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                badDebtOppQuery += ' AND Date__c <= :endDt';
                badDebtOppQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                //badDebtOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                //badDebtOppQuery += ' AND Payment_Method__c =:payment';  
                badDebtOppQuery += ' AND Reference_Notes__c =:badDebt';                 
                badDebtOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                badDebtOppQuery += ' AND Is_Rejected__c = false';
                badDebtOppQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                badDebtOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c';
                
                
            	List<AggregateResult> badDebtOppAggResult = Database.query(badDebtOppQuery);
                
                for(AggregateResult agr : badDebtOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                            
                            w.BadDebtAmount += Double.valueof(agr.get('amt'));
                            w.BadDebtFileCount += integer.valueof(agr.get('file'));
                        	//w.InterestRepaid += Double.valueof(agr.get('interest')) != null? Double.valueof(agr.get('interest')) : 0;
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);
                        
                    }
                }
                
                /**
                 * ShortFall
                 * */
                
                String shortFallOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId,';
                shortFallOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                shortFallOppQuery += ' SUM(Amount__c) amt, SUM(Interest_Repaid__c) interest';
                shortFallOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                shortFallOppQuery += ' AND Date__c <= :endDt';
                shortFallOppQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                shortFallOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                shortFallOppQuery += ' AND Payment_Method__c =:payment';
                shortFallOppQuery += ' AND Reference_Notes__c =:paymentShortfall';                 
                shortFallOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedShortfall';
                shortFallOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                shortFallOppQuery += ' AND Is_Rejected__c = false';
                shortFallOppQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                shortFallOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c';
                
                
            	List<AggregateResult> shortFallOppQueryOppAggResult = Database.query(shortFallOppQuery);
                
                for(AggregateResult agr : shortFallOppQueryOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                            
                            w.ShortfallAmount += Double.valueof(agr.get('amt'));
                            w.ShortfallFileCount += integer.valueof(agr.get('file'));
                        	//w.InterestRepaid += Double.valueof(agr.get('interest')) != null? Double.valueof(agr.get('interest')) : 0;
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);
                        
                    }
                }
                
                /**
                 * Overage
                 * */
                String overageOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId,';
                overageOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                overageOppQuery += ' SUM(Amount__c) amt, SUM(Interest_Repaid__c) interest';
                overageOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                overageOppQuery += ' AND Date__c <= :endDt';
                overageOppQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                overageOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                overageOppQuery += ' AND Payment_Method__c =:payment';  
                overageOppQuery += ' AND Reference_Notes__c =:paymentSurplus'; 
                overageOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedSurplus';
                overageOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                overageOppQuery += ' AND Is_Rejected__c = false';
                overageOppQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                overageOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c';
                
                
            	List<AggregateResult> overageOppAggResult = Database.query(overageOppQuery);
                
                for(AggregateResult agr : overageOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                            
                            w.OverageAmount += Double.valueof(agr.get('amt'));
                            w.OverageFileCount += integer.valueof(agr.get('file'));
                        	//w.InterestRepaid += Double.valueof(agr.get('interest')) != null? Double.valueof(agr.get('interest')) : 0;
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);
                        
                    }
                }
                
                /**
                 * 	Admin Fee Received
                 * */
                
                String adminFeeQuery = 'Select Account.Business_Unit__c businessunit, Lawyer__c lawyerId, Lawyer__r.Name lawyer, Law_firm__r.name firm, Law_firm__c firmId,';
                adminFeeQuery += ' SUM(Admin_Fee_Received__c) adminfeeRec';
                adminFeeQuery += ' FROM Opportunity WHERE Opportunity_Closed_Date__c >= :startDt';
                adminFeeQuery += ' AND Opportunity_Closed_Date__c <= :endDt';
                adminFeeQuery += ' AND Lawyer__c in :lawyerIdsSet';
                adminFeeQuery += (typeOfLoan.isEmpty())? '' : ' AND Type_of_Loan__c IN :typeOfLoan';
                adminFeeQuery += ' AND StageName =:ClosedWithLoan';
                adminFeeQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Account.Business_Unit__c IN :BusinessUnit';
                adminFeeQuery += ' Group by Account.Business_Unit__c, Lawyer__c, Lawyer__r.Name, Law_firm__r.name, Law_firm__c';
                
                List<AggregateResult> adminOppAggResult = Database.query(adminFeeQuery);
                
                for(AggregateResult agr : adminOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                            
                            w.AdminFeeReceived += Double.valueof(agr.get('adminfeeRec')) != null? Double.valueof(agr.get('adminfeeRec')) : 0;
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);
                        
                    }
                }

                /**
                 * Total file count
                 */

                strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file';
                strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                strQuery += ' AND Date__c <= :endDt';
                strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                strQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                strQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                strQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c';
                
                List<AggregateResult> aggResultTotalFiles = Database.query(strQuery);
                for(AggregateResult agr : aggResultTotalFiles){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                        
                        w.FileCount += integer.valueof(agr.get('file'));
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);                        
                    }
                }
                
                /**
                 * Active Partial Payment file count
                 */

                strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file';
                strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                strQuery += ' AND Date__c <= :endDt';
                strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
                strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                strQuery += (BusinessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
                strQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                strQuery += ' AND Opportunity__r.Stage_Status__c =:activePartialPayment';
                strQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c';
                
                List<AggregateResult> aggResultActivePartialFiles = Database.query(strQuery);
                for(AggregateResult agr : aggResultActivePartialFiles){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')))){
                        
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')));
                        
                        w.ActivePartialFileCount += integer.valueof(agr.get('file'));
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firmId')), w);                        
                    }
                }
                
				list<Wrapper> finalWrapper = new list<Wrapper>(agrMap.values());
                
                for(Wrapper w : finalWrapper){
                    w.NetAmount = (((w.InterestRepaid + w.AdminFeeReceived + w.OverageAmount) - w.ShortfallAmount) - w.BadDebtAmount);
                }
                
                return finalWrapper;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
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
        public decimal Amount {get; set;}
        @AuraEnabled
        public decimal InterestRepaid {get; set;}
        @AuraEnabled
        public decimal AdminFeeReceived {get; set;}
        @AuraEnabled
        public decimal NetAmount {get; set;}
        

        wrapper(string l, string lawrId, string f, string frmId, integer rc, integer rcc, integer roc, decimal ra){
            
            lawyer = l;
            lawyerId = lawrId;
            firm = f;
            firmId = frmId;
            
            ActiveFileCount = rc;
            ClosedFileCount = rcc;
            OpptyCount = roc;
            Amount = ra;
            
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
        }
        
    }
}