@isTest
public class OpportunityTriggerHandlerTest {
    
    @isTest static void setDiscountscheduleTest(){
        Test.startTest();
        Account NewTestAcc = new Account();
        NewTestAcc.Name = 'Test LawFirm Account';
        NewTestAcc.Authorization_Clause__c = 'No';
        NewTestAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        Insert NewTestAcc;
        
        Account NewTestAccAssess = new Account();
        NewTestAccAssess.Name = 'Assessment Account';
        NewTestAccAssess.Authorization_Clause__c = 'No';
        NewTestAccAssess.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assessment Provider').getRecordTypeId();
        Insert NewTestAccAssess;
        
        Contact NewTestCon = new Contact();
        NewTestCon.FirstName = 'Test';
        NewTestCon.LastName = 'Lawyer Contact';
        NewTestCon.AccountId = NewTestAcc.Id;
        NewTestCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId();
        Insert NewTestCon;
        
        Contact ClientCon = new Contact();
        ClientCon.FirstName = 'Test';
        ClientCon.LastName = 'Client Contact';
        ClientCon.AccountId = NewTestAcc.Id;
        ClientCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId();
        Insert ClientCon;
        
        Assessment_Provider_Schedule__c NewTestAps = new Assessment_Provider_Schedule__c();
        NewTestAps.Lawyer__c = NewTestCon.Id;
        NewTestAps.Assessment_Provider__c = NewTestAccAssess.Id;
        NewTestAps.Discount__c = 30;
        NewTestAps.Rebate_Discount__c = 10;
        Insert NewTestAps;
        
        Opportunity NewTestOpp = new Opportunity();
        NewTestOpp.Type_of_Loan__c = 'Assessment';
        NewTestOpp.Name = 'Test Opportunity';
        NewTestOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        NewTestOpp.Lawyer__c = NewTestCon.Id;
        NewTestOpp.CloseDate = Date.today().addDays(14);
        NewTestOpp.StageName = 'Closed With Loan';
        NewTestOpp.Law_Firm__c = NewTestAcc.Id;  
        NewTestOpp.Stage_Status__c = 'Approved';
        NewTestOpp.Primary_Contact__c = ClientCon.Id;
        NewTestOpp.Minimum_Interest_Period__c = '0 months';
        NewTestOpp.Compounding_Interest__c = 'Monthly';
        NewTestOpp.Interest_Rate__c = 15.0;
        NewTestOpp.Interest_Compounding_Period__c = 'Simple Interest';
        NewTestOpp.Interest_Deferral_Period__c = '0';
        NewTestOpp.Assessment_Provider__c = NewTestAccAssess.Id;
        Insert NewTestOpp;
        
        Account AccForUpdate = new Account();
        AccForUpdate.Name = 'New testing account';
        AccForUpdate.Authorization_Clause__c = 'No';
        AccForUpdate.RecordTypeId = NewTestAccAssess.RecordTypeId;
        Insert AccForUpdate;
        
        
        Opportunity Opps = [SELECT Id, Assessment_Provider__c FROM Opportunity Where Id =: NewTestOpp.Id];
        Opps.Assessment_Provider__c = AccForUpdate.Id;
        Update Opps;
        Test.stopTest();
    }
    
    @isTest static void lawyerAvailableCreditRollUpsTest1(){
        Test.startTest();
        Account NewTestAcc = new Account();
        NewTestAcc.Name = 'Test LawFirm Account';
        NewTestAcc.Authorization_Clause__c = 'No';
        NewTestAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        Insert NewTestAcc;
        
        Account NewTestAccAssess = new Account();
        NewTestAccAssess.Name = 'Assessment Account';
        NewTestAccAssess.Authorization_Clause__c = 'No';
        NewTestAccAssess.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assessment Provider').getRecordTypeId();
        Insert NewTestAccAssess;
        
        Contact NewTestCon = new Contact();
        NewTestCon.FirstName = 'Test';
        NewTestCon.LastName = 'Lawyer Contact';
        NewTestCon.AccountId = NewTestAcc.Id;
        NewTestCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId();
        Insert NewTestCon;
        
        Contact ClientCon = new Contact();
        ClientCon.FirstName = 'Test';
        ClientCon.LastName = 'Client Contact';
        ClientCon.AccountId = NewTestAcc.Id;
        ClientCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId();
        Insert ClientCon;
        
        Assessment_Provider_Schedule__c NewTestAps = new Assessment_Provider_Schedule__c();
        NewTestAps.Lawyer__c = NewTestCon.Id;
        NewTestAps.Assessment_Provider__c = NewTestAccAssess.Id;
        NewTestAps.Discount__c = 30;
        NewTestAps.Rebate_Discount__c = 10;
        Insert NewTestAps;
        
        Opportunity NewTestOpp = new Opportunity();
        NewTestOpp.Type_of_Loan__c = 'Assessment';
        NewTestOpp.Name = 'Test Opportunity';
        NewTestOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        NewTestOpp.Lawyer__c = NewTestCon.Id;
        NewTestOpp.CloseDate = Date.today().addDays(14);
        NewTestOpp.StageName = 'Closed With Loan';
        NewTestOpp.Law_Firm__c = NewTestAcc.Id;  
        NewTestOpp.Stage_Status__c = 'Active';
        NewTestOpp.Primary_Contact__c = ClientCon.Id;
        NewTestOpp.Minimum_Interest_Period__c = '0 months';
        NewTestOpp.Compounding_Interest__c = 'Monthly';
        NewTestOpp.Interest_Rate__c = 15.0;
        NewTestOpp.Interest_Compounding_Period__c = 'Simple Interest';
        NewTestOpp.Interest_Deferral_Period__c = '0';
        NewTestOpp.Assessment_Provider__c = NewTestAccAssess.Id;
        Insert NewTestOpp;
        
        
        Test.stopTest();
    }
    
    @isTest static void lawyerAvailableCreditRollUpsTest2(){
        Test.startTest();
        Account NewTestAcc = new Account();
        NewTestAcc.Name = 'Test LawFirm Account';
        NewTestAcc.Authorization_Clause__c = 'No';
        NewTestAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        Insert NewTestAcc;
        
        Account NewTestAccAssess = new Account();
        NewTestAccAssess.Name = 'Assessment Account';
        NewTestAccAssess.Authorization_Clause__c = 'No';
        NewTestAccAssess.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assessment Provider').getRecordTypeId();
        Insert NewTestAccAssess;
        
        Contact NewTestCon = new Contact();
        NewTestCon.FirstName = 'Test';
        NewTestCon.LastName = 'Lawyer Contact';
        NewTestCon.AccountId = NewTestAcc.Id;
        NewTestCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId();
        Insert NewTestCon;
        
        Contact ClientCon = new Contact();
        ClientCon.FirstName = 'Test';
        ClientCon.LastName = 'Client Contact';
        ClientCon.AccountId = NewTestAcc.Id;
        ClientCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId();
        Insert ClientCon;
        
        Assessment_Provider_Schedule__c NewTestAps = new Assessment_Provider_Schedule__c();
        NewTestAps.Lawyer__c = NewTestCon.Id;
        NewTestAps.Assessment_Provider__c = NewTestAccAssess.Id;
        NewTestAps.Discount__c = 30;
        NewTestAps.Rebate_Discount__c = 10;
        Insert NewTestAps;
        
        Opportunity NewTestOpp = new Opportunity();
        NewTestOpp.Type_of_Loan__c = 'Assessment';
        NewTestOpp.Name = 'Test Opportunity';
        NewTestOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        NewTestOpp.Lawyer__c = NewTestCon.Id;
        NewTestOpp.CloseDate = Date.today().addDays(14);
        NewTestOpp.StageName = 'Loan Approved';
        NewTestOpp.Law_Firm__c = NewTestAcc.Id;  
        NewTestOpp.Stage_Status__c = 'Invoice Pre-Approved';
        NewTestOpp.Primary_Contact__c = ClientCon.Id;
        NewTestOpp.Minimum_Interest_Period__c = '0 months';
        NewTestOpp.Compounding_Interest__c = 'Monthly';
        NewTestOpp.Interest_Rate__c = 15.0;
        NewTestOpp.Interest_Compounding_Period__c = 'Simple Interest';
        NewTestOpp.Interest_Deferral_Period__c = '0';
        NewTestOpp.Assessment_Provider__c = NewTestAccAssess.Id;
        Insert NewTestOpp;
        
        
        Test.stopTest();
    }
    
    public static testMethod void updateLoanStatusTest() {        
                Account NewTestAcc = new Account();
        NewTestAcc.Name = 'Test LawFirm Account';
        NewTestAcc.Authorization_Clause__c = 'No';
        NewTestAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        Insert NewTestAcc;
        
        Contact ClientCon = new Contact();
        ClientCon.FirstName = 'Test';
        ClientCon.LastName = 'Client Contact';
        ClientCon.AccountId = NewTestAcc.Id;
        ClientCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId();
        Insert ClientCon;

        Opportunity NewTestOpp = new Opportunity();
        NewTestOpp.Type_of_Loan__c = 'Facility Loan';
        NewTestOpp.Name = 'Test Opportunity';
        NewTestOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();        
        NewTestOpp.CloseDate = Date.today().addDays(14);
        NewTestOpp.StageName = 'Closed With Loan';        
        NewTestOpp.Stage_Status__c = 'Active';
        NewTestOpp.Primary_Contact__c = ClientCon.Id;
        NewTestOpp.Minimum_Interest_Period__c = '0 months';
        NewTestOpp.Compounding_Interest__c = 'Monthly';
        NewTestOpp.Interest_Rate__c = 15.0;
        NewTestOpp.Interest_Compounding_Period__c = 'Simple Interest';
        NewTestOpp.Interest_Deferral_Period__c = '0';
        NewTestOpp.Is_Reserve_Applied__c = true;
        NewTestOpp.Reserve_Date__c = Date.today();
        Insert NewTestOpp;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        opp.Stage_Status__c = 'Active - Collections';
        update opp;
        opp = [SELECT Id, Stage_Status__c, Loan_Status__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];        
        System.assertEquals('Active - Collections', opp.Loan_Status__c);
        Test.stopTest();
    }
    
    public static testMethod void sendEmailOnReserveChangeTest() {
        Account NewTestAcc = new Account();
        NewTestAcc.Name = 'Test LawFirm Account';
        NewTestAcc.Authorization_Clause__c = 'No';
        NewTestAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        Insert NewTestAcc;
        
        Contact ClientCon = new Contact();
        ClientCon.FirstName = 'Test';
        ClientCon.LastName = 'Client Contact';
        ClientCon.AccountId = NewTestAcc.Id;
        ClientCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId();
        Insert ClientCon;

        Opportunity NewTestOpp = new Opportunity();
        NewTestOpp.Type_of_Loan__c = 'Facility Loan';
        NewTestOpp.Name = 'Test Opportunity';
        NewTestOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();        
        NewTestOpp.CloseDate = Date.today().addDays(14);
        NewTestOpp.StageName = 'Closed With Loan';        
        NewTestOpp.Stage_Status__c = 'Active';
        NewTestOpp.Primary_Contact__c = ClientCon.Id;
        NewTestOpp.Minimum_Interest_Period__c = '0 months';
        NewTestOpp.Compounding_Interest__c = 'Monthly';
        NewTestOpp.Interest_Rate__c = 15.0;
        NewTestOpp.Interest_Compounding_Period__c = 'Simple Interest';
        NewTestOpp.Interest_Deferral_Period__c = '0';
        insert NewTestOpp;
        Test.startTest();
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];        
        Map<String, Object> reserveInfoMap = new Map<String, Object>();
        reserveInfoMap.put('Id', opp.Id);
        reserveInfoMap.put('Is_Reserve_Applied__c', true);
        reserveInfoMap.put('Stop_Interest__c', true);
        reserveInfoMap.put('Reserve_Date__c', Date.today());
        reserveInfoMap.put('Reserve_Amount__c', 100.0);
        List<Map<String, Object>> reserveInfos = new List<Map<String, Object>>{reserveInfoMap};
        ReserveHelper.applyReserveOpps(reserveInfos);
        Test.stopTest();
    }
    
    public static testMethod void clearReserveAmountWhenClosedTest() {        
        Account NewTestAcc = new Account();
        NewTestAcc.Name = 'Test LawFirm Account';
        NewTestAcc.Authorization_Clause__c = 'No';
        NewTestAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        Insert NewTestAcc;
        
        Contact ClientCon = new Contact();
        ClientCon.FirstName = 'Test';
        ClientCon.LastName = 'Client Contact';
        ClientCon.AccountId = NewTestAcc.Id;
        ClientCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId();
        Insert ClientCon;

        Opportunity NewTestOpp = new Opportunity();
        NewTestOpp.Type_of_Loan__c = 'Facility Loan';
        NewTestOpp.Name = 'Test Opportunity';
        NewTestOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();        
        NewTestOpp.CloseDate = Date.today().addDays(14);
        NewTestOpp.StageName = 'Closed With Loan';        
        NewTestOpp.Stage_Status__c = 'Active';
        NewTestOpp.Primary_Contact__c = ClientCon.Id;
        NewTestOpp.Minimum_Interest_Period__c = '0 months';
        NewTestOpp.Compounding_Interest__c = 'Monthly';
        NewTestOpp.Interest_Rate__c = 15.0;
        NewTestOpp.Interest_Compounding_Period__c = 'Simple Interest';
        NewTestOpp.Interest_Deferral_Period__c = '0';
        NewTestOpp.Is_Reserve_Applied__c = true;
        NewTestOpp.Reserve_Amount__c = 1000.0;
        NewTestOpp.Reserve_Date__c = Date.today();
        insert NewTestOpp;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        opp.Stage_Status__c = 'Closed - Paid';
        update opp;
        opp = [SELECT Id, Reserve_Amount__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];        
        System.assertEquals(0.0, opp.Reserve_Amount__c);
        Test.stopTest();
    }
    
}