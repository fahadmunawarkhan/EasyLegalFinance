public with sharing class LawyerSalesSummaryComponentCtrl {
    @AuraEnabled
    public static list<Wrapper> getAmountGroupByLawyer(String startDate, String endDate, String field, String direction, string BusinessUnit, String searchByName, String typeOfLoan){
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
            string filterByBusinessUnit = '';
            string Rhino = 'Rhino';
            string Elfi = 'ELFI';
            
            // Business Unit Filter

            if(BusinessUnit == 'ELFI'){
                
                filterByBusinessUnit = 'ELFI';
            }else if(BusinessUnit == 'Rhino'){
                
                filterByBusinessUnit = 'Rhino';
            }else if(BusinessUnit == 'Consolidated'){
                
                filterByBusinessUnit = 'Consolidated';
            }
            
            
            strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, '; 
            strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount, ';
            strQuery += ' SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
            strQuery += ' OR (Payment_Method__c =:Cheque)';
            strQuery += ' OR (Payment_Method__c =:AdminFee))';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND Is_Rejected__c = false AND';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? 
                ' (Opportunity__r.Account.Business_Unit__c =:Elfi OR Opportunity__r.Account.Business_Unit__c =:Rhino)':
            ' Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += ' AND Opportunity__r.Lawyer__c != \'\'';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Opportunity__r.Lawyer__r.Name LIKE \'%' + searchByName + '%\')'  : '';
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
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')))){
                       // if province exists 
                       wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            //w.rhinoFileCount += Integer.valueof(agr.get('file'));
                            w.rhinoOpptyCount += Integer.valueof(agr.get('opptyCount'));
                            w.rhinoAmount += Double.valueof(agr.get('amt'));
                            w.rhinoClosedAmount = 0;                            
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            //w.elfiFileCount += Integer.valueof(agr.get('file'));
                            w.elfiOpptyCount += Integer.valueof(agr.get('opptyCount'));
                            w.elfiAmount += Double.valueof(agr.get('amt'));
                            w.elfiClosedAmount = 0;
                        }
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                        
                    }else{
                        // new province
                        wrapper w;
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){                            
                            w = new wrapper(String.ValueOf(agr.get('lawyer')), String.ValueOf(agr.get('lawyerId')),
                                            String.ValueOf(agr.get('firm')), String.ValueOf(agr.get('firmId')),
                                            0,
                                            0,
                                            Integer.valueof(agr.get('opptyCount')),                                            
                                            Double.valueof(agr.get('amt')),0,0,0,0.00);
                            
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){                            
                            w = new wrapper(String.ValueOf(agr.get('lawyer')), String.ValueOf(agr.get('lawyerId')),
                                            String.ValueOf(agr.get('firm')), String.ValueOf(agr.get('firmId')),
                                            0,0,0,0.00,0,
                                            0,
                                            Integer.valueof(agr.get('opptyCount')),                                            
                                            Double.valueof(agr.get('amt')));
                        }
                        w.rhinoClosedAmount = 0;
                        w.elfiClosedAmount = 0;
                        agrMap.put(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                    }
                }
                
                /**
                 * Active/Open file count
                 * */
                strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, ';
                strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file';
                strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
                strQuery += ' AND Date__c <= :endDt';
                strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                strQuery += ' AND Opportunity__r.Stage_Status__c LIKE \'%Active%\' AND';
                strQuery += (filterByBusinessUnit == 'Consolidated') ? 
                    ' (Opportunity__r.Account.Business_Unit__c =:Elfi OR Opportunity__r.Account.Business_Unit__c =:Rhino)':
                ' Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
                strQuery += ' AND Opportunity__r.Lawyer__c != \'\'';
                strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
                strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Opportunity__r.Lawyer__r.Name LIKE \'%' + searchByName + '%\')'  : '';
                strQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c';
                
                List<AggregateResult> aggResultOpenOpps = Database.query(strQuery);
                
                for(AggregateResult agr : aggResultOpenOpps){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')))){
                        
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            w.rhinoFileCount += integer.valueof(agr.get('file'));
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            w.elfiFileCount += integer.valueof(agr.get('file'));
                        }                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);                        
                    }
                }
                
                
                String closedOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm,';
                closedOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                closedOppQuery += ' SUM(Amount__c) amt';
                closedOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                closedOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                closedOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
                closedOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                closedOppQuery += ' AND Payment_Method__c =:payment';  
                closedOppQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment OR Reference_Notes__c =:clientRebate)'; 
                closedOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedPaid';
                closedOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                closedOppQuery += ' AND Is_Rejected__c = false';
                closedOppQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                closedOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name';
                
                
            	List<AggregateResult> closedOppAggResult = Database.query(closedOppQuery);
                
                for(AggregateResult agr : closedOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w.rhinoClosedAmount += Double.valueof(agr.get('amt'));
                            w.rhinoClosedFileCount += integer.valueof(agr.get('file'));
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w.elfiClosedAmount += Double.valueof(agr.get('amt'));
                            w.elfiClosedFileCount += integer.valueof(agr.get('file'));
                        }
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                        
                    }
                }
                
                /**
                 * Bad Debt
                 * */
                String badDebtOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm,';
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
                
                
            	List<AggregateResult> badDebtOppAggResult = Database.query(badDebtOppQuery);
                
                for(AggregateResult agr : badDebtOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w.rhinoBadDebtAmount += Double.valueof(agr.get('amt'));
                            w.rhinoBadDebtFileCount += integer.valueof(agr.get('file'));
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w.elfiBadDebtAmount += Double.valueof(agr.get('amt'));
                            w.elfiBadDebtFileCount += integer.valueof(agr.get('file'));
                        }
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                        
                    }
                }
                
                /**
                 * ShortFall
                 * */
                
                String shortFallOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm,';
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
                
                
            	List<AggregateResult> shortFallOppQueryOppAggResult = Database.query(shortFallOppQuery);
                
                for(AggregateResult agr : shortFallOppQueryOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w.rhinoShortfallAmount += Double.valueof(agr.get('amt'));
                            w.rhinoShortfallFileCount += integer.valueof(agr.get('file'));
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w.elfiShortfallAmount += Double.valueof(agr.get('amt'));
                            w.elfiShortfallFileCount += integer.valueof(agr.get('file'));
                        }
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                        
                    }
                }
                
                /**
                 * Overage
                 * */
                String overageOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm,';
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
                
                
            	List<AggregateResult> overageOppAggResult = Database.query(overageOppQuery);
                
                for(AggregateResult agr : overageOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w.rhinoOverageAmount += Double.valueof(agr.get('amt'));
                            w.rhinoOverageFileCount += integer.valueof(agr.get('file'));
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w.elfiOverageAmount += Double.valueof(agr.get('amt'));
                            w.elfiOverageFileCount += integer.valueof(agr.get('file'));
                        }
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                        
                    }
                }
                
				list<Wrapper> finalWrapper = new list<Wrapper>(agrMap.values());
				/* 
				list<Wrapper> finalWrapper = new list<Wrapper>(); 
                
                for(string key : agrMap.keyset()){

					// split the key to get lawyer and firm
					string lawyer = key.split('-')[0];
					string firm = key.split('-')[1];
                    
                    Wrapper w = agrMap.get(key);
                    
                    if(w == null) continue;
                    
                    finalWrapper.add(new Wrapper(lawyer,firm, w.rhinoCount, w.rhinoAmount, w.elfiCount, w.elfiAmount));
                    
                    
                }
                */
                
                system.debug('Wrapper records are:');
                system.debug(finalWrapper);
                
                return finalWrapper;

                //return aggResult;
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
    public static void saveCustomSettings(String startDate, String endDate, String businessUnit, String typeOfLoan, String searchByName){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Lawyer_Sales_Summary_Report__c lsr = Lawyer_Sales_Summary_Report__c.getOrgDefaults();
            
            lsr.End_date__c = endDt;
            lsr.Start_Date__c = startDt;
            lsr.BusinessUnit__c = businessUnit;
            lsr.Type_of_Loan__c = typeOfLoan;
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
        public integer rhinoFileCount {get; set;}
        @AuraEnabled
        public integer rhinoClosedFileCount {get; set;}
        @AuraEnabled
        public integer rhinoShortfallFileCount {get; set;}
        @AuraEnabled
        public integer rhinoBadDebtFileCount {get; set;}
        @AuraEnabled
        public integer rhinoOverageFileCount {get; set;}
        @AuraEnabled
        public integer rhinoOpptyCount {get; set;}
        @AuraEnabled
        public decimal rhinoClosedAmount {get; set;}
        @AuraEnabled
        public decimal rhinoShortfallAmount {get; set;}
        @AuraEnabled
        public decimal rhinoBadDebtAmount {get; set;}
        @AuraEnabled
        public decimal rhinoOverageAmount {get; set;}
        @AuraEnabled
        public decimal rhinoAmount {get; set;}
        @AuraEnabled
        public integer elfiFileCount {get; set;}
        @AuraEnabled
        public integer elfiClosedFileCount {get; set;}
        @AuraEnabled
        public integer elfiShortfallFileCount {get; set;}
        @AuraEnabled
        public integer elfiBadDebtFileCount {get; set;}
        @AuraEnabled
        public integer elfiOverageFileCount {get; set;}
        @AuraEnabled        
        public integer elfiOpptyCount {get; set;}
        @AuraEnabled
        public decimal elfiClosedAmount{get; set;}
        @AuraEnabled
        public decimal elfiShortfallAmount {get; set;}
        @AuraEnabled
        public decimal elfiBadDebtAmount {get; set;}
        @AuraEnabled
        public decimal elfiOverageAmount {get; set;}
        @AuraEnabled
        public decimal elfiAmount {get; set;}
        
        wrapper(string l, string lawrId, string f, string frmId, integer rc, integer rcc, integer roc, decimal ra, integer ec, integer ecc, integer eoc, decimal ea){
            
            lawyer = l;
            lawyerId = lawrId;
            firm = f;
            firmId = frmId;
            
            rhinoFileCount = rc;
            rhinoClosedFileCount = rcc;
            rhinoOpptyCount = roc;
            rhinoAmount = ra;
            
            elfiFileCount = ec;
            elfiClosedFileCount = ecc;
            elfiOpptyCount = eoc;
            elfiAmount = ea;
            
            rhinoShortfallFileCount = 0;
            rhinoBadDebtFileCount = 0;
            rhinoOverageFileCount = 0;
            
            elfiShortfallFileCount = 0;
            elfiBadDebtFileCount = 0;
            elfiOverageFileCount = 0;
            
            rhinoShortfallAmount = 0.0;
            rhinoBadDebtAmount = 0.0;
            rhinoOverageAmount = 0.0;
            
            elfiShortfallAmount = 0.0;
            elfiBadDebtAmount = 0.0;
            elfiOverageAmount = 0.0;
        }
        
    }
}