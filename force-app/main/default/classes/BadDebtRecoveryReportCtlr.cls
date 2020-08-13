public with sharing class BadDebtRecoveryReportCtlr {
    
    @AuraEnabled
    public static list<Wrapper> getPaymentsGroupByProvince(String startDate, String endDate, List<string> BusinessUnit, List<String> typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = '';            
            
            string ClosedWithLoan = 'Closed With Loan';
            String badDebtRecovery = 'Bad Debt Recovery';
            
            
            strQuery = 'Select Opportunity__r.Account.ProvinceResidency__c province,Opportunity__r.Account.Business_Unit__c businessunit, COUNT_DISTINCT(Opportunity__r.AccountId) file,'; 
            strQuery += ' COUNT_DISTINCT(Opportunity__c) opptyCount, SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
            strQuery += BusinessUnit.isEmpty() ? '': ' AND Opportunity__r.Account.Business_Unit__c IN :BusinessUnit';
            strQuery += ' AND Reference_Notes__c =:badDebtRecovery';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' Group by Opportunity__r.Account.ProvinceResidency__c,Opportunity__r.Account.Business_Unit__c';
            strQuery += ' Order by SUM(Amount__c) desc NULLS LAST';
            
            List<AggregateResult> aggResult = Database.query(strQuery);
            if(!aggResult.isEmpty()){
                map<string, wrapper> agrMap = new map<string, wrapper>();
                
                for(AggregateResult agr : aggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('province')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('province')));
                        w.fileCount += Integer.valueof(agr.get('file'));
                        w.opptyCount += Integer.valueof(agr.get('opptyCount'));
                        w.amount += Double.valueof(agr.get('amt'));
                        agrMap.put(String.ValueOf(agr.get('province')), w);                        
                        
                    }else{
                        // new province
                        wrapper w = new wrapper(String.ValueOf(agr.get('province')),
                                                Integer.valueof(agr.get('file')),
                                                Integer.valueof(agr.get('opptyCount')),
                                                Double.valueof(agr.get('amt')));
                        
                        agrMap.put(String.ValueOf(agr.get('province')), w);
                    }
                }
                
                
                list<Wrapper> finalWrapper = new list<Wrapper>(agrMap.values());
                return finalWrapper;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled 
    public static Drawdown__c getDrawdown(){
        List<Drawdown__c> congaUrlHolder = [Select Conga_Bad_Debt_Recovery_Report_Print_All__c,
                                            Conga_Bad_Debt_Recovery_Report_View_All__c 
                                            from Drawdown__c limit 1];
        return congaUrlHolder[0];
    }
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static void saveCustomSettings(String startDate, String endDate, List<String> businessUnit, List<String> typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Bad_Debt_Recovery_Report__c bdr = Bad_Debt_Recovery_Report__c.getOrgDefaults();
            
            bdr.Business_Unit__c = String.join(businessUnit, '|');
            bdr.End_Date__c = endDt;
            bdr.Start_Date__c = startDt;
            bdr.Type_of_Loan__c = String.join(typeOfLoan, '|');
            
            upsert bdr;
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Bad_Debt_Recovery_Report__c getCustomSetting(){
        Bad_Debt_Recovery_Report__c bDSR = Bad_Debt_Recovery_Report__c.getOrgDefaults();
        bDSR.Type_of_Loan__c = bDSR.Type_of_Loan__c == null || String.isEmpty(bDSR.Type_of_Loan__c) ? 'Consolidated' : bDSR.Type_of_Loan__c;
        return bDSR;
    }
    
    public class Wrapper {
        @AuraEnabled
        public string province {get; set;}
        @AuraEnabled
        public integer fileCount {get; set;}
        @AuraEnabled
        public integer opptyCount {get; set;}
        @AuraEnabled
        public decimal amount {get; set;}        
        
        wrapper(string p, integer fc, integer oc, decimal amt){
            
            province = p;
            
            fileCount = fc;
            opptyCount = oc;
            amount = amt;
        }
        
    }
}