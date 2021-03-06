/**
 * @File Name          : PpsaExpiryReportComponentCtrl.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 08-12-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    16/04/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class PpsaExpiryReportComponentCtrl {
    public class Wrapper {
        @AuraEnabled
        public String AccId {get; set;}
        @AuraEnabled
        public String OppId {get;set;}
        @AuraEnabled
        public String ExpiryDate {get; set;}
        @AuraEnabled
        public string FirstName {get; set;}
        @AuraEnabled
        public string LastName {get; set;}
        @AuraEnabled
        public string LoanNo {get; set;}
        @AuraEnabled
        public string StageStatus {get; set;}
        @AuraEnabled
        public string PPSANo {get; set;}
        @AuraEnabled
        public Decimal DaysToExpire {get; set;}

        public Wrapper(){
            OppId = '';
            AccId = '';
            ExpiryDate = '';
            FirstName = '';
            LastName = '';
            LoanNo = '';
            StageStatus = '';
            PPSANo = '';
            DaysToExpire = 0.00;
        }
    }

    // ============ | This wrapper class is for summary report for excel, pdf and print | ================
    public class SummaryDataWrapper {
        @AuraEnabled
        public String ExpiryDate {get; set;}
        @AuraEnabled
        public string FirstName {get; set;}
        @AuraEnabled
        public string LastName {get; set;}
        @AuraEnabled
        public string LoanNo {get; set;}
        @AuraEnabled
        public string StageStatus {get; set;}
        @AuraEnabled
        public string PPSANo {get; set;}
        @AuraEnabled
        public Decimal DaysToExpire {get; set;}
        @AuraEnabled
        public String congaViewAllURL{get;set;}
        @AuraEnabled
        public String congaPrintReportURL{get;set;}
        public SummaryDataWrapper(){
            ExpiryDate = '';
            FirstName = '';
            LastName = '';
            LoanNo = '';
            StageStatus = '';
            PPSANo = '';
            DaysToExpire = 0.00;
            congaViewAllURL = '';
            congaPrintReportURL = '';
        }
    }
    // ===================================================================================================

    @AuraEnabled
    public static List<Wrapper> getPPSExpiryLoans(String startDate, String endDate, String field, String direction, List<String> BusinessUnit, String searchByName, List<String> typeOfLoan, String expiryDateFilter, String statusFilter){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            Date ExpiryDtFilter = (!String.isEmpty(expiryDateFilter) && expiryDateFilter != null ? Date.valueOf(expiryDateFilter) : null);
            List<Wrapper> ExpiryLoansWrapperList = new List<Wrapper>();

            String ClosedPaid = 'Closed - Paid';
            String ClosedSurplus = 'Closed - Surplus';
            String ClosedShortFall = 'Closed - Shortfall';
            String ClosedNoLoan = 'Closed No Loan';

            String query = '';

            query = 'SELECT Id';
            query += ' FROM Opportunity Where (Date_Financing_Statement_Expires__c >= :startDt AND Date_Financing_Statement_Expires__c <= :endDt)';
            query += (BusinessUnit.isEmpty())? '' : ' AND Account.Business_Unit__c IN :BusinessUnit'; 
            query += (typeOfLoan.isEmpty()) ? '' : ' AND Type_of_Loan__c IN :typeOfLoan';
            query += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Law_firm__r.name LIKE \'%' + searchByName + '%\')'  : '';
            query += (!String.isEmpty(expiryDateFilter) && expiryDateFilter != null) ? ' AND Date_Financing_Statement_Expires__c = : ExpiryDtFilter' : '';
            query += (!String.isEmpty(statusFilter) && statusFilter != null) ? ' AND Stage_Status_Report__c = : statusFilter' : '';
            query += ' AND (Stage_Status__c != : ClosedPaid AND Stage_Status__c != : ClosedSurplus AND Stage_Status__c != : ClosedShortFall AND StageName != : ClosedNoLoan)';
            query += ' order by ' + field + ' ' + direction + ' NULLS LAST';

            List<Opportunity> PPSAExpiryListId = Database.query(query);

            Set<String> LoansIdSets = new Set<String>();
            for(Opportunity Oppo : PPSAExpiryListId){
                LoansIdSets.add(Oppo.Id);
            }

            // =========== Expiry Loan Query ===========
                String PPSAExpiryQuery = '';
                PPSAExpiryQuery = 'SELECT Id, Date_Financing_Statement_Expires__c, Primary_Contact__r.FirstName, Primary_Contact__r.LastName, AccountId, Account.Business_Unit__c, Type_of_Loan__c, Loan_No__c, Stage_Status_Report__c, Registration_Number__c, Days_To_Expire__c, Stage_Status__c, StageName';
                PPSAExpiryQuery += ' FROM Opportunity Where (Date_Financing_Statement_Expires__c >= :startDt AND Date_Financing_Statement_Expires__c <= :endDt)';
                PPSAExpiryQuery += (BusinessUnit.isEmpty())? '' : ' AND Account.Business_Unit__c IN :BusinessUnit'; 
                PPSAExpiryQuery += (typeOfLoan.isEmpty()) ? '' : ' AND Type_of_Loan__c IN :typeOfLoan';
                PPSAExpiryQuery += (!String.isEmpty(expiryDateFilter) && expiryDateFilter != null) ? ' AND Date_Financing_Statement_Expires__c = : ExpiryDtFilter' : '';
                PPSAExpiryQuery += (!String.isEmpty(statusFilter) && statusFilter != null) ? ' AND Stage_Status_Report__c = : statusFilter' : '';
                PPSAExpiryQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Law_firm__r.name LIKE \'%' + searchByName + '%\')'  : '';
                PPSAExpiryQuery += ' AND Id IN :LoansIdSets';
                PPSAExpiryQuery += ' AND (Stage_Status__c != : ClosedPaid AND Stage_Status__c != : ClosedSurplus AND Stage_Status__c != : ClosedShortFall AND StageName != : ClosedNoLoan)';
                PPSAExpiryQuery += ' order by ' + field + ' ' + direction + ' NULLS LAST';
                
                List<Opportunity> PPSAExpiryList = Database.query(PPSAExpiryQuery);
                Map<String, Wrapper> ExpiryLoansList = new Map<String, Wrapper>();
                for(Opportunity getOppo : PPSAExpiryList){
                    Wrapper w = new Wrapper();
                    w.AccId += getOppo.AccountId;
                    w.OppId += getOppo.Id;
                    if(getOppo.Date_Financing_Statement_Expires__c != null){
                        Datetime dt = Date.Valueof(getOppo.Date_Financing_Statement_Expires__c); 
                        w.ExpiryDate += dt.year() + '-' + dt.month() + '-' + dt.addDays(1).day();
                    } else {
                        w.ExpiryDate += null;
                    }
                    w.FirstName += (!String.isEmpty(getOppo.Primary_Contact__r.FirstName) ? getOppo.Primary_Contact__r.FirstName : '');
                    w.LastName += getOppo.Primary_Contact__r.LastName;
                    w.LoanNo += (!String.isEmpty(getOppo.Loan_No__c) ? getOppo.Loan_No__c : '-');
                    //w.StageStatus += getOppo.Stage_Status_Report__c + '(' + getOppo.StageName + ')' + '(' + getOppo.Stage_Status__c + ')';
                    w.StageStatus += getOppo.Stage_Status_Report__c;
                    w.PPSANo += (!String.isEmpty(getOppo.Registration_Number__c) ? getOppo.Registration_Number__c : '-');
                    w.DaysToExpire += ((getOppo.Days_To_Expire__c != null) ? getOppo.Days_To_Expire__c  : 0.00);
                    ExpiryLoansList.put(getOppo.Id, w);
                }
            // ==================================
            
            // =========== Note ===========
            //  just add values against id by calling wrapper class variables and put wrapper in same list (ExpiryLoansList).
            // ============================

            
                for(String Loanid : LoansIdSets){
                    String Key = Loanid;
                    if(ExpiryLoansList.containsKey(key))
                            ExpiryLoansWrapperList.add(ExpiryLoansList.get(key)); // this will add whole wrapper data to wrapper list.
                }
            return ExpiryLoansWrapperList;
            //return query;

        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static PPSA_Expiry_Summary_Report__c getCustomSetting(){
        PPSA_Expiry_Summary_Report__c pesr = PPSA_Expiry_Summary_Report__c.getOrgDefaults();
        return pesr;
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }

    @AuraEnabled
    public static void saveCustomSettings(String startDate, String endDate, List<String> businessUnit, List<String> typeOfLoan, String searchByName){
        system.debug(startDate+ '|' + endDate+ '|' + businessUnit+ '|' + typeOfLoan + '|' +searchByName);
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            PPSA_Expiry_Summary_Report__c pesr = PPSA_Expiry_Summary_Report__c.getOrgDefaults();
            pesr.End_date__c = endDt;
            pesr.Start_Date__c = startDt;
            pesr.Business_Unit__c = String.join(businessUnit, '|');
            pesr.Type_of_Loan__c = String.join(typeOfLoan, '|');
            pesr.Search_By_Name__c = searchByName;
            update pesr; 
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static SummaryDataWrapper getSummarizeData(String startDate, String endDate, List<String> BusinessUnit, List<String> typeOfLoan){
        Date startDt = Date.valueOf(startDate);
        Date endDt = Date.valueOf(endDate);
        String PPSAExpiryQuery = '';
        Set<String> LoansIdSets = new Set<String>();

        String ClosedPaid = 'Closed - Paid';
        String ClosedSurplus = 'Closed - Surplus';
        String ClosedShortFall = 'Closed - Shortfall';
        String ClosedNoLoan = 'Closed No Loan';

        try{
            PPSAExpiryQuery = 'SELECT Id, Date_Financing_Statement_Expires__c, Primary_Contact__r.FirstName, Primary_Contact__r.LastName, Account.Business_Unit__c, Type_of_Loan__c, Loan_No__c, Stage_Status_Report__c, Registration_Number__c, Days_To_Expire__c';
            PPSAExpiryQuery += ' FROM Opportunity Where (Date_Financing_Statement_Expires__c >= :startDt AND Date_Financing_Statement_Expires__c <= :endDt)';
            PPSAExpiryQuery += (BusinessUnit.isEmpty())? '' : ' AND Account.Business_Unit__c IN :BusinessUnit';
            PPSAExpiryQuery += (typeOfLoan.isEmpty()) ? '' : ' AND Type_of_Loan__c IN :typeOfLoan';
            PPSAExpiryQuery += ' AND (Stage_Status__c != : ClosedPaid AND Stage_Status__c != : ClosedSurplus AND Stage_Status__c != : ClosedShortFall AND StageName != : ClosedNoLoan)';

            List<Opportunity> PPSAExpiryListSummary = Database.query(PPSAExpiryQuery);
            SummaryDataWrapper sdw = new SummaryDataWrapper();
            if(PPSAExpiryListSummary.size() > 0){
                if(PPSAExpiryListSummary != null){
                    if(PPSAExpiryListSummary[0].Date_Financing_Statement_Expires__c != null){
                        Datetime dt = PPSAExpiryListSummary[0].Date_Financing_Statement_Expires__c; 
                        sdw.ExpiryDate += dt.year() + '-' + dt.month() + '-' + dt.addDays(1).day();
                    } else {
                        sdw.ExpiryDate += null;
                    }
                    sdw.FirstName += ((PPSAExpiryListSummary[0].Primary_Contact__r.FirstName != null) ? PPSAExpiryListSummary[0].Primary_Contact__r.FirstName : '');
                    sdw.LastName += PPSAExpiryListSummary[0].Primary_Contact__r.LastName;
                    sdw.LoanNo += ((PPSAExpiryListSummary[0].Loan_No__c != null) ? PPSAExpiryListSummary[0].Loan_No__c : '');
                    sdw.StageStatus += PPSAExpiryListSummary[0].Stage_Status_Report__c;
                    sdw.PPSANo += ((PPSAExpiryListSummary[0].Registration_Number__c != null) ? PPSAExpiryListSummary[0].Registration_Number__c : '');
                    sdw.DaysToExpire +=  (Integer)PPSAExpiryListSummary[0].Days_To_Expire__c;
                }
            }

            List<Drawdown__c> congaUrlHolder = [Select Conga_PPSA_Summary_Report_View_All__c, Conga_PPSA_Summary_Report_Print__c
                                            from Drawdown__c limit 1];
            if(congaUrlHolder.size() > 0){
                sdw.congaViewAllURL = congaUrlHolder.isEmpty() ? '' : congaUrlHolder[0].Conga_PPSA_Summary_Report_View_All__c;
                sdw.congaPrintReportURL = congaUrlHolder.isEmpty() ? '' : congaUrlHolder[0].Conga_PPSA_Summary_Report_Print__c;
            }
            return sdw;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean orgInstanceCheck(){
        //OrgCheckResult
        Boolean OrgCheckResult;
        OrgCheckResult = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        return OrgCheckResult;
    }
}