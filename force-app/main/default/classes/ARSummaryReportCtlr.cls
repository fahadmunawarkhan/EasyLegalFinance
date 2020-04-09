public with sharing class ARSummaryReportCtlr {

    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static AR_Summary_Report__c getCustomSetting(){
        AR_Summary_Report__c aRSR_CustomSetting = AR_Summary_Report__c.getOrgDefaults();
        aRSR_CustomSetting.Type_of_Loan__c = aRSR_CustomSetting.Type_of_Loan__c == null || aRSR_CustomSetting.Type_of_Loan__c == '' ? 'Consolidated' : aRSR_CustomSetting.Type_of_Loan__c;
        return aRSR_CustomSetting;
    }
    
    @AuraEnabled
    public static list<Wrapper> getReportDataByProvince(String startDate, String endDate, string businessUnit, String typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);            
            string filterByBusinessUnit = (businessUnit != null && !String.isEmpty(businessUnit))? businessUnit : 'ELFI';
            
            String strQuery = '';
            
            string cheque = 'Cheque';
            string eTransfer = 'e-Transfer';
            string adminFee = 'Admin Fee';
            string otherFee = 'Other Fee';
            string activePartialPayment = 'Active - Partial Payment';
        	String closedWithLoan = 'Closed With Loan';
        	String statusActive = 'Active';
            
            strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Account.ProvinceResidency__c province,'; 
            strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
            strQuery += ' SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt';
            strQuery += ' AND Opportunity__r.StageName =:closedWithLoan';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:statusActive OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
            strQuery += ' AND (Payment_Method__c =:cheque or Payment_Method__c =:eTransfer)'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += ' Group by Opportunity__r.Account.ProvinceResidency__c, Opportunity__r.Account.Business_Unit__c';
            
            List<AggregateResult> aggResult = Database.query(strQuery);
            
            list<Wrapper> finalWrapper = new List<Wrapper>();
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
                finalWrapper = new list<Wrapper>(agrMap.values());
                return finalWrapper;                
            }
            return finalWrapper;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
    }
    
    @AuraEnabled
    public static ARSummaryDataWrapper getSummarizeData(String startDate, String endDate, String businessUnit, String typeOfLoan){
        
        ARSummaryDataWrapper reportDataW = new ARSummaryDataWrapper();
        String strQuery = '';
        string cheque = 'Cheque';
        string eTransfer = 'e-Transfer';
        string adminFee = 'Admin Fee';
        string activePartialPayment = 'Active - Partial Payment';        
        String closedWithLoan = 'Closed With Loan';
        String active = 'Active';
        
        String filterByBusinessUnit = (!String.isEmpty(businessUnit) && businessUnit != null)? businessUnit : 'ELFI';
        
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            strQuery = 'Select COUNT_DISTINCT(Opportunity__r.AccountId) noOfFiles, COUNT_DISTINCT(Opportunity__c) noOfOppties,'; 
            strQuery += ' SUM(Amount__c) amt,';
            strQuery += ' SUM(Accrued_Interest_In_Reporting_Period__c) accruedInterest,';
            strQuery += ' SUM(Admin_Fee__c) adminFee';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt';
            strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
            strQuery += ' AND Opportunity__r.StageName =:closedWithLoan';
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:active OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
            strQuery += ' AND (Payment_Method__c =:cheque or Payment_Method__c =:eTransfer)'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? '': ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';			
            AggregateResult aggResult = Database.query(strQuery); 
            
            if(aggResult != null){
                reportDataW.noOfFiles = aggResult.get('noOfFiles') != null? (Integer)aggResult.get('noOfFiles') : 0;
                reportDataW.amountOfAdvances = aggResult.get('amt') != null? (Decimal)aggResult.get('amt') : 0.0;
                reportDataW.adminFee = aggResult.get('adminFee') != null? (Decimal)aggResult.get('adminFee') : 0.0;                
            }
            
            reportDataW.total = reportDataW.amountOfAdvances;
            reportDataW.total += reportDataW.adminFee;
            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        List<Drawdown__c> congaUrlHolder = [Select Conga_AR_Summary_Report_View_All__c, Conga_AR_Summary_Report_Print__c
                                            from Drawdown__c limit 1];
        
        reportDataW.congaViewAllURL = congaUrlHolder.isEmpty() ? '' : congaUrlHolder[0].Conga_AR_Summary_Report_View_All__c;
        reportDataW.congaPrintReportURL = congaUrlHolder.isEmpty() ? '' : congaUrlHolder[0].Conga_AR_Summary_Report_Print__c;
        return reportDataW;        
    }
    
    @AuraEnabled
    public static void saveCustomSettings(String startDate, String endDate, String businessUnit, String typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            AR_Summary_Report__c arsp = AR_Summary_Report__c.getOrgDefaults();
            
            arsp.End_date__c = endDt;
            arsp.Start_Date__c = startDt;
            arsp.Type_of_Loan__c = typeOfLoan;
            arsp.Business_Unit__c = businessUnit;            
            upsert arsp;
            
        }catch(Exception ex){            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public class Wrapper {
        @AuraEnabled
        public String province {get; set;}
        @AuraEnabled
        public Integer fileCount {get; set;}
        @AuraEnabled
        public Integer opptyCount {get; set;}
        @AuraEnabled
        public Decimal amount {get; set;}
        
        wrapper(string p, integer fc, integer opc, decimal amt){
            
            province = p;            
            fileCount = fc;
            opptyCount = opc;
            amount = amt;
        }
        
    }
    
    /******************* Wrapper Class for Summary Report Data *********************/
    public Class ARSummaryDataWrapper {
        
        @AuraEnabled
        public Integer noOfFiles{get;set;}
        @AuraEnabled
        public Decimal amountOfAdvances{get;set;}
        @AuraEnabled
        public Decimal adminFee{get;set;}
        @AuraEnabled
        public Decimal total{get;set;}
        @AuraEnabled
        public String congaViewAllURL{get;set;}
        @AuraEnabled
        public String congaPrintReportURL{get;set;}
        
        public ARSummaryDataWrapper(){
            congaViewAllURL = '';
            congaPrintReportURL = '';
            noOfFiles = 0;
            amountOfAdvances = 0.0;
            adminFee = 0.0;
            total = 0.0;
        }
    }
}