@isTest
public class noOfLeadsPerMonthReportCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){
        
        Datetime yesterday = Datetime.now().addDays(-1);        
        
        // lead
        List<Lead> leads = new List<Lead>();
        Lead openlead;
        for(Integer i=0; i < 10; i++){
            openlead = new Lead();
            openlead.FirstName = 'Mike ' + i * i;
            openlead.LastName = 'Jakson ' + i;
            openlead.Company = 'Easylegal';
            openlead.status = 'Open';
            leads.add(openlead);
        }
        
        insert leads;
        Integer days = -1;
        for(Lead ld : leads){
            Test.setCreatedDate(ld.Id, Datetime.now().addDays(days * 2));
            days -= 15;
        }
        
        //Test.setCreatedDate(openlead.Id, yesterday);
        
        // Account
        Account clientAcc = new Account();
        clientAcc.Name = 'Test Client Account';
        clientAcc.Authorization_Clause__c = 'No';
        clientAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        insert clientAcc;        
        
        Account firmAcc = new Account();
        firmAcc.Name = 'Test Firm Account';
        firmAcc.Account_Type__c = 'Treatment Provider Firm';
        firmAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId();
        insert firmAcc;
        
        //contact
        Contact clientContact = new Contact();
        clientContact.LastName = 'Test Client Contact';
        clientContact.AccountId = clientAcc.Id;
        clientContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId();
        insert clientContact;
        
        Contact lawyerContact = new Contact();
        lawyerContact.LastName = 'Test Client Contact';
        lawyerContact.AccountId = firmAcc.Id;
        lawyerContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId();
        insert lawyerContact;
        
        Opportunity Opp = new Opportunity(Name = 'Test Opportunity', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                          AccountId = clientAcc.Id);
        Opp.Lawyer__c = lawyerContact.Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = firmAcc.Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Payout_Date__c = Date.today();
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = clientContact.Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Interest_Rate__c = 15.0;
        insert Opp;
        Test.setCreatedDate(Opp.Id, yesterday);
        
        insertDrawdown(Opp.Id);
    }    
    public static void insertDrawdown(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        Date dt = Date.today();
        for(Integer i=0; i < 5; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = dt.addDays(i), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50), Payment_Method__c ='Payment', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Partial Payment'));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    @isTest
    static void startTestProcess(){
        
        Test.startTest();
        Datetime lmonth = Datetime.now().addDays(-31);
        
        Lead leadtoBeConverted = new Lead();
        leadtoBeConverted.FirstName = 'Cole';
        leadtoBeConverted.LastName = 'Swain';
        leadtoBeConverted.Company = 'Easylegal';
        leadtoBeConverted.status = 'Qualified';
        insert leadtoBeConverted;
        //Test.setCreatedDate(leadtoBeConverted.Id, lmonth);
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(leadtoBeConverted.Id);        
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        System.assert(lcr.isSuccess());
        
        noOfLeadsPerMonthReportCtlr ctlr = new noOfLeadsPerMonthReportCtlr();
        ctlr.getLeadsByMonth();
        Test.stopTest();
    }
}