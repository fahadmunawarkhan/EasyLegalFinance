public with sharing class ReportingViewComponentCtlr {
    
    @AuraEnabled
    public static User getCurrentUserInfo(){
        User currentUser = [SELECT Id,isActive,ProfileId, Custom_Reports__c, Drawdowns__c, Financial_Summary__c,
                            Financing_Statement_Details__c, Loan_Set_up__c, Lump_Sum_drawdowns__c, Payments_tab__c,
                            Payout_Details__c FROM User Where Id = :UserInfo.getUserId()];
        return currentUser;
    } 
    
    /******************* Method to return all lawyers *********************/
    /*@AuraEnabled
    public static List<ContactInfo> getLawyersContacts(String strQuery, String LoanFilter ) {
        try{
            LoanFilter = String.isEmpty(LoanFilter) ? 'All' : LoanFilter;
            system.debug('LoanFilter ' + LoanFilter);
            
            // Initializing the contact variable
            List<ContactInfo> contactInfo = new List<ContactInfo>();
            List<Contact> contacts = new List<Contact>();
            
                        
            // *** Still need to handle exceptions ***
            // Executing the query to retrieve the account information
            contacts = Database.query(strQuery);        
            
            
            Set<Id> contactIds = new Map<Id,Contact>(contacts).keySet();
            for(contact con : contacts)
            {
                System.debug('## getLawyersContacts - RESULT: ' + con.Id);
            }
            
            strQuery = 'Select Law_Firm_Lawyer__c, Lawyer__c, AccountId, Loan_Available_to_Drawdown__c from Opportunity where Lawyer__c in :contactIds ';
            strQuery += LoanFilter == 'Active'? ' AND isClosed = true AND isWon = true AND Stage_Status__c != \'Paid Off\'' : '';
            
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
    @AuraEnabled
    public static Id send(String query, List<Id> selectedIds, String payoutDate, String reportDate, String emailBody, String LoanFilter){       
        
        system.debug('Email Body');
        system.debug(emailBody);         
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());        
        customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
        customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
        customSettings.Email_body__c = emailBody;
        customSettings.Query_Selector__c = LoanFilter;
        update customSettings;
		
        APXT_BPM__Conductor__c conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE 	Name='Conductor-0000' limit 1];
        APXTConga4__Conga_Merge_Query__c congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
        conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Summary_Send_Email__c';
        update conductor;
        
        String ids = '';
        if(String.isEmpty(query) || query == null) {
            ids = String.Join(selectedIds,',');
        	query = 'select id from contact WHERE Id in ('+ ids +')';
        }
        
        congaQuery.APXTConga4__Query__c = query;
        update congaQuery;        
        return conductor.id;
    }
    
    @AuraEnabled
    public static Id generate(String query, List<Id> selectedIds, String payoutDate, String reportDate, String LoanFilter){
		       
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());        
        customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
        customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
        customSettings.Query_Selector__c = LoanFilter;
        update customSettings;
		
        APXT_BPM__Conductor__c conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Name='Conductor-0000' limit 1];
        APXTConga4__Conga_Merge_Query__c congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
        conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Summary__c';
        update conductor;
        
        String ids = '';
        if(String.isEmpty(query) || query == null) {
            ids = String.Join(selectedIds,',');
        	query = 'select id from contact WHERE Id in ('+ ids +')';
        }
        
        congaQuery.APXTConga4__Query__c = query;
        update congaQuery;        
        return conductor.id;
    }
    
   	@AuraEnabled
    public static User getCurrentUserInfo(){
        User currentUser = [SELECT Id,isActive,ProfileId, Custom_Reports__c, Drawdowns__c, Financial_Summary__c,
                            Financing_Statement_Details__c, Loan_Set_up__c, Lump_Sum_drawdowns__c, Payments_tab__c,
                            Payout_Details__c FROM User Where Id = :UserInfo.getUserId()];
        return currentUser;
    } 
    
    public class ContactInfo{
        @AuraEnabled
        public Contact contact{get;set;}
        
        @AuraEnabled
        public Integer noOfFiles{get;set;} 
        
        @AuraEnabled
        public Boolean checked{get;set;} 
    }*/
}