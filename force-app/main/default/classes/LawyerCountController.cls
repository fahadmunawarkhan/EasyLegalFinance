/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-18-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-13-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class LawyerCountController {
    /******************* Method to return all lawyers *********************/
    @AuraEnabled
    public static List<ContactInfo> getLawyersContacts(String strQuery, String LoanFilter, List<String> businessUnitFilter, List<String> typeofloans, String startDate, String endDate) {
        try{
            LoanFilter = String.isEmpty(LoanFilter) ? 'All' : LoanFilter;
            
            // Initializing the contact variable
            List<ContactInfo> contactInfo = new List<ContactInfo>();
            List<Contact> contacts = new List<Contact>();
                   
            // *** Still need to handle exceptions ***
            // Executing the query to retrieve the account information
            contacts = Database.query(strQuery);        

            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);

            Report_Settings__c reportSettings = Report_Settings__c.getOrgDefaults();
            reportSettings.Start_Date__c=startDt;
            reportSettings.End_Date__c=endDt;
            upsert reportSettings;
            
            
            Set<Id> contactIds = new Map<Id,Contact>(contacts).keySet();
            for(contact con : contacts)
            {
                System.debug('## getLawyersContacts - RESULT: ' + con.Id);
            }


            
            strQuery = 'Select Law_Firm_Lawyer__c, Lawyer__c, AccountId, Loan_Available_to_Drawdown__c from Opportunity where Lawyer__c in :contactIds ';
            strQuery += (typeofloans.isEmpty()) ? '' : ' AND Type_of_Loan__c IN :typeofloans';
            strQuery += ' AND StageName = \'Closed With Loan\' AND Account.Exclude_from_Payout__c = false AND Drawdown_Total__c > 0 AND Stage_Status__c LIKE \'%Active%\'';
            // strQuery += LoanFilter == 'Active'? ' AND isClosed = true AND isWon = true AND Stage_Status__c != \'Paid Off\'' : '';
            strQuery += (businessUnitFilter.isEmpty()) ? '' : ' AND Account.Business_Unit__c IN :businessUnitFilter';
            List<Opportunity> oppties = new List<Opportunity>();
            oppties = Database.query(strQuery);
            System.debug('Oppty: Query: '+strQuery);
            Map<Id,Set<Id>> lawyerToClients = new Map<Id,Set<Id>>();
            
            for(Opportunity opp : oppties)
            {
                if(!lawyerToClients.containsKey(opp.Lawyer__c))
                {
                    lawyerToClients.put(opp.Lawyer__c, new Set<Id>());
                }
                lawyerToClients.get(opp.Lawyer__c).add(opp.AccountId);
            }
            for(contact c : contacts)
            {
                ContactInfo info = new ContactInfo();
                info.contact = c;
                info.noOfFiles = lawyerToClients.containsKey(c.Id) ? lawyerToClients.get(c.Id).size() : 0;
                if(info.noOfFiles > 0)
                {
                    contactInfo.add(info);
                }
            }
            return contactInfo;
        }
        catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage());
        }
    }  
    /******************* Method to get all picklists values for Account *********************/  
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    @AuraEnabled
    public static Id send(String query, List<String> selectedIds, String payoutDate, String reportDate, String emailBody, String LoanFilter, List<String> businessUnitFilter, List<String> typeofloans){       
        try{
            system.debug('-Here in Send function -');
            system.debug(selectedIds);
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;        
            String ids = '';
            
            if(String.isEmpty(query) || query == null) {
                ids = String.Join(selectedIds,',');
                query = 'select id from contact WHERE Id in ('+ ids +')';
            }
            
            Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());        
            customSettings.Lawyer_Count_Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Lawyer_Count_Payout_Date__c;
            customSettings.Lawyer_Count_Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Lawyer_Count_Report_Date__c;
            customSettings.Lawyer_Count_Business_Unit__c = String.join(businessUnitFilter, '|');
            customSettings.Email_Additional_Notes_Lawyer_Summary__c = emailBody;
            customSettings.Query_Selector_Lawyer_Count_Report__c = LoanFilter;
            customSettings.Lawyer_Count_Type_Of_Loan__c = String.join(typeofloans, '|');        
            
            if(String.isEmpty(customSettings.Conductor_Id_Lawyer_Summary_Report__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Lawyer summary conductor query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of lawyer summary custom report for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Lawyer Summary - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Count_Send_Email__c');
                insert conductor;            
                customSettings.Conductor_Id_Lawyer_Summary_Report__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conductor_Id_Lawyer_Summary_Report__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Count_Send_Email__c';
                update conductor;
                congaQuery.APXTConga4__Query__c = query;
                update congaQuery;
            }
            upsert customSettings;
            return conductor.id;
        }
        catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static void SaveCustomSettings(String startdate, String enddate, String payoutDate, String reportDate, List<String> typeofloans, List<String> businessUnitFilter, String LoanFilter){
        
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());
        customSettings.Lawyer_Count_Start_Date__c = (!String.isEmpty(startdate) || startdate != null) ? Date.valueOf(startdate) : customSettings.Lawyer_Count_Start_Date__c;
        customSettings.Lawyer_Count_End_Date__c = (!String.isEmpty(enddate) || enddate != null) ? Date.valueOf(enddate) : customSettings.Lawyer_Count_End_Date__c;
        customSettings.Lawyer_Count_Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Lawyer_Count_Payout_Date__c;
        customSettings.Lawyer_Count_Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Lawyer_Count_Report_Date__c;
        customSettings.Lawyer_Count_Type_Of_Loan__c = String.join(typeofloans, '|');
        customSettings.Lawyer_Count_Business_Unit__c = String.join(businessUnitFilter, '|');
        customSettings.Query_Selector_Lawyer_Count_Report__c = LoanFilter;
        upsert customSettings;

    }
    
    @AuraEnabled
    public static Conga_batch_setting__c GetCustomSettings(){
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());
        return customSettings;
    }

    @AuraEnabled
    public static Id generate(String query, List<String> selectedIds, String payoutDate, String reportDate, String LoanFilter, List<String> businessUnitFilter, List<String> typeofloans){
        try{
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;        
            String ids = '';
            
            if(String.isEmpty(query) || query == null) {
                ids = String.Join(selectedIds,',');
                query = 'select id from contact WHERE Id in ('+ ids +')';
            }
            
            Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());        
            customSettings.Lawyer_Count_Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Lawyer_Count_Payout_Date__c;
            customSettings.Lawyer_Count_Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Lawyer_Count_Report_Date__c;
            customSettings.Lawyer_Count_Business_Unit__c = String.join(businessUnitFilter, '|');
            customSettings.Lawyer_Count_Type_Of_Loan__c = String.join(typeofloans, '|');
            customSettings.Query_Selector_Lawyer_Count_Report__c = LoanFilter;
            
            if(String.isEmpty(customSettings.Conductor_Id_Lawyer_Summary_Report__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Lawyer summary conductor query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of lawyer summary custom report for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Lawyer Summary - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Count__c');
                insert conductor;            
                customSettings.Conductor_Id_Lawyer_Summary_Report__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conductor_Id_Lawyer_Summary_Report__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Count__c';
                update conductor;
                congaQuery.APXTConga4__Query__c = query;
                update congaQuery;
            }
            upsert customSettings;
            return conductor.id;	
        }
        catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }
    
    public class ContactInfo{
        @AuraEnabled
        public Contact contact{get;set;}
        
        @AuraEnabled
        public Integer noOfFiles{get;set;} 
        
        @AuraEnabled
        public Boolean checked{get;set;} 
    }
}