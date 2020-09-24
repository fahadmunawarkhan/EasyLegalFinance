/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-23-2020
 * @last modified by  : fahad.khan@toptal.com
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   07-15-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class ClientSummaryReportCtlr {
    /******************* Method to get all picklists values for Account *********************/  
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }

    @AuraEnabled
    public static List<ClientInfo> getClientList(String searchByName, String sortField, String sortOrder, String loanFilter, String businessUnitFilter, List<String> typeOfLoan){
        
        Boolean ExcludeFromPayout = false;
        loanFilter = String.isEmpty(loanFilter) ? 'All' : loanFilter;
        businessUnitFilter = String.isEmpty(businessUnitFilter) ? 'ELFI' :businessUnitFilter;
        searchByName = (searchByName == null || String.isEmpty(searchByName))? '' : searchByName;
        
        system.debug('searchByName ' + searchByName);
        
        String strQuery = 'SELECT Id, Name, Email, Account.Name, Account.AccountNumber, AccountId,';
        strQuery += ' (Select id,createddate from tasks where subject LIKE \'%Client Payout Summary%\' and type=\'Email\' and createddate = today order by createddate desc limit 1 )';
        strQuery += ' FROM Contact WHERE AccountId != null';
        strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Name_Formula__c LIKE \'%' + searchByName + '%\' OR Account.Name LIKE \'%' + searchByName + '%\' OR Account.AccountNumber LIKE \'%' + searchByName + '%\' )' : '';
        strQuery += ' AND Id in (SELECT Primary_Contact__c FROM Opportunity WHERE accountId !=null AND Account.Exclude_from_Payout__c = false AND StageName = \'Closed With Loan\' AND Drawdown_Total__c > 0';
        strQuery += ' AND Account.Business_Unit__c =:businessUnitFilter';
        strQuery += loanFilter == 'Active'? ' AND Stage_Status__c LIKE \'%Active%\'' : '';
        strQuery += typeOfLoan.isEmpty() ? ')' : ' AND Type_of_Loan__c IN:typeOfLoan)';
        strQuery += ' order by ' + sortField + ' ' + sortOrder + ' limit 10000';
        
        
        system.debug('strQuery ' + strQuery);
        
        List<Contact> contacts = new List<Contact>();        
        contacts = Database.query(strQuery);
        
        system.debug('contacts size ' + contacts.size());
        
        Set<Id> accountIds = new Set<Id>();
        
        for(Contact con : contacts){
            accountIds.add(con.AccountId);
        }
        
        Map<Id, String> accountToAttachPDF = new Map<Id, String>();
        for(Attachment attach : [Select id ,parentId
                                 from Attachment 
                                 where parentId IN : accountIds
                                 AND parentId != null
                                 and name like '%Payout Loan%pdf' and 
                                 createddate = today order by createddate desc]){
                                     if(!accountToAttachPDF.containsKey(attach.parentId))
                                         accountToAttachPDF.put(attach.parentId, attach.Id);
                                 }
        
        
        List<ClientInfo> clientInfo = new List<ClientInfo>();
        
        for(Contact con : contacts)
        {
            ClientInfo info = new ClientInfo();
            info.contact = con;
			info.PdfId = accountToAttachPDF.containsKey(con.AccountId) ? accountToAttachPDF.get(con.AccountId) : '';
            if(contact.AccountId != null)  clientInfo.add(info);
            
        }
        return ClientInfo;
    }
    
    @AuraEnabled 
    public static void abortBatchJobs(){
        for(AsyncApexJob aJob : [SELECT id FROM AsyncApexJob WHERE Status!='Aborted' AND Status!='Completed'
                                 AND ApexClass.Name = 'ClientSummaryGeneratePayoutBalance'] ){                                     
                                     System.AbortJob(aJob.Id);                                     
                                 }
    }
    
    @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(){
        List<AsyncApexJob> aaj = null;
        try{
            aaj = [SELECT Id, ApexClassId, Status, NumberOfErrors, TotalJobItems, JobItemsProcessed, createdBy.Name, createdDate, CompletedDate FROM AsyncApexJob
                   WHERE ApexClass.Name = 'ClientSummaryGeneratePayoutBalance' AND Status != 'Aborted' order by CreatedDate DESC LIMIT 1];
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
        return (aaj.size() > 0 )? aaj[0] : null;
    }
    
    @AuraEnabled
    public static Id generate(String query, List<String> selectedIds, String payoutDate, String reportDate, String LoanFilter, String businessUnitFilter, List<string> typeOfLoan){
        try{
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;        
            String ids = '';
            String CongaBatchField = '';
            
            if(String.isEmpty(query) || query == null) {
                ids = String.Join(selectedIds,',');
                query = 'select id from Contact WHERE Id in ('+ ids +')';
            }
            
            CongaBatchField = 'Conga_Client_Summary_Report__c';
   
                        
            Client_Summary_Report__c customSettings = Client_Summary_Report__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
            customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
            customSettings.Business_Unit__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';
            customSettings.Query_Selector__c = LoanFilter;
            customSettings.Type_of_Loan__c = String.join(typeOfLoan, '|');
            
            if(String.isEmpty(customSettings.Conductor_Id__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Client summary conductor query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of Client summary custom report for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Client Summary - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = CongaBatchField);
                insert conductor;            
                customSettings.Conductor_Id__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conductor_Id__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = CongaBatchField;
                update conductor;
                congaQuery.APXTConga4__Query__c = query;
                update congaQuery;
            }
            upsert customSettings;
            return conductor.id;	
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage() + '');
        }
    }
    
    @AuraEnabled
    public static Id send(String query, List<String> selectedIds, String payoutDate, String reportDate, String emailBody, String LoanFilter, String businessUnitFilter, List<String> typeOfLoan){       
        try{
            system.debug('-Here in Send function -');
            system.debug(selectedIds);
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;        
            String ids = '';
            
            if(String.isEmpty(query) || query == null) {
                ids = String.Join(selectedIds,',');
                query = 'select id from Contact WHERE Id in ('+ ids +')';
            }
            
            Client_Summary_Report__c customSettings = Client_Summary_Report__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
            customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
            customSettings.Business_Unit__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';
            customSettings.Query_Selector__c = LoanFilter;
            customSettings.Type_of_Loan__c = String.join(typeOfLoan, '|');
            customSettings.Email_Body__c = emailBody;
            
            if(String.isEmpty(customSettings.Conductor_Id__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Client summary conductor query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of Client summary custom report for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Client Summary - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Send_Client_Summary_Report__c');
                insert conductor;            
                customSettings.Conductor_Id__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conductor_Id__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Send_Client_Summary_Report__c';
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
    public static void generatePayoutBalance(List<Id> selectedIds, String payoutDate, String searchByName, String loanFilter, String businessUnitFilter, List<String> typeOfLoan){
        try{
            
            Set<Id> contactIds = new Set<Id>(selectedIds);
            
            PayoutJobsHelper.checkJobs();
            
            loanFilter = String.isEmpty(loanFilter) ? 'All' : loanFilter;
            businessUnitFilter = String.isEmpty(businessUnitFilter) ? 'ELFI' :businessUnitFilter;
            searchByName = (searchByName == null || String.isEmpty(searchByName))? '' : searchByName;
            
            if(selectedIds.isEmpty()){
                
                loanFilter = String.isEmpty(loanFilter) ? 'All' : loanFilter;
                businessUnitFilter = String.isEmpty(businessUnitFilter) ? 'ELFI' :businessUnitFilter;
                searchByName = (searchByName == null || String.isEmpty(searchByName))? '' : searchByName;
                
                String strQuery = 'SELECT Id, Name, Account.Name';
                strQuery += ' FROM Contact WHERE AccountId != null';
                strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Name_Formula__c LIKE \'%' + searchByName + '%\' OR Account.Name LIKE \'%' + searchByName + '%\' OR Account.AccountNumber LIKE \'%' + searchByName + '%\' )' : '';
                strQuery += ' AND Id in (SELECT Primary_Contact__c FROM Opportunity WHERE accountId !=null AND StageName = \'Closed With Loan\' AND Drawdown_Total__c > 0';
                strQuery += ' AND Account.Business_Unit__c =:businessUnitFilter';
                strQuery += loanFilter == 'Active'? ' AND Stage_Status__c LIKE \'%Active%\'' : '';
                strQuery += typeOfLoan.isEmpty() ? ')' : ' AND Type_of_Loan__c IN:typeOfLoan)';
                strQuery += ' limit 10000';
                
                List<Contact> contacts = new List<Contact>();
                contacts = Database.query(strQuery); 
                contactIds = new Map<Id,Contact>(contacts).keySet();
            }
            
            ClientSummaryGeneratePayoutBalance csgpb = new ClientSummaryGeneratePayoutBalance(contactIds, Date.valueOf(payoutDate), loanFilter, businessUnitFilter, typeOfLoan);
            Database.executeBatch(csgpb, 50);
            
        }catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class ClientInfo{
        
        @AuraEnabled
        public Contact contact{get;set;}
        
        @AuraEnabled
        public Boolean checked{get;set;} 

        @AuraEnabled
        public String ExcelId{get;set;}

        @AuraEnabled
        public String PdfId{get;set;}
        
        @AuraEnabled
        public Task task{get;set;}
    }
}