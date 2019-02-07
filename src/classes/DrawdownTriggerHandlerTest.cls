@isTest
public with sharing class DrawdownTriggerHandlerTest {
    
    @TestSetup
    static void initailizeTestData(){
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId()));
        accountList.add( new Account(Name = 'Test LawFirm Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId()));
        accountList.add( new Account(Name = 'Firm Account', Account_Type__c = 'Treatment Provider Firm',
                                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId()));
        
        insert accountList;
        
        contactList.add( new Contact(LastName = 'Test Client Contact', AccountId = accountList[0].Id,
                                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId()));
        contactList.add( new Contact(LastName = 'Test Lawyer Contact', AccountId = accountList[1].Id,
                                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId()));
        insert contactList;
        
        Opportunity Opp = new Opportunity(Name = 'Test Opportunity', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                          AccountId = accountList[0].Id);
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Payout_Date__c = Date.today();
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Interest_Rate__c = 15.0;
        insert Opp;
        
        insertDrawdown(Opp.Id);
    }
    
    public static void insertDrawdown(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 5; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50), Payment_Method__c ='Payment', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Partial Payment'));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    public static testMethod void validatePaymentChangeInsertTest(){
        Test.startTest();
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        insertDrawdown(clientOpportunity.Id);
        Test.stopTest();
    }
    
    public static testMethod void validatePaymentChangeUpdateTest(){
        Test.startTest();
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        List<Drawdown__c> dlist = [SELECT Id, Date__c, Amount__c, Payment_Method__c FROM Drawdown__c];
        dlist[0].Amount__c = 3851;
        dlist[1].Payment_Method__c = 'Admin Fee';
        dlist[1].Reference_Notes__c = 'Admin Fee';
        dlist[2].Date__c = Date.today();
        update dlist;
        Test.stopTest();
    }

    public static testMethod void validatePaymentDeleteTest(){
        Test.startTest();
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        List<Drawdown__c> dlistOriginal = new List<Drawdown__c>();
        dlistOriginal.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = clientOpportunity.id,
                                            Amount__c = 2000, Payment_Method__c ='e-Transfer', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Payment to Client'));
        insert dlistOriginal;
        List<Drawdown__c> dlistUpdated = [SELECT Id, Date__c, Amount__c, Payment_Method__c,Sum_of_Repayments__c  FROM Drawdown__c where id =: dlistOriginal[0].id];
        system.assertEquals(2000, dlistUpdated[0].Sum_of_Repayments__c,'Payments should be fully allocated to Drawdown');

        // delete the payment with an allocation
        List<Drawdown__c> dlistPayment = [SELECT Id, Date__c, Amount__c, Payment_Method__c,Sum_of_Payment_Allocations__c  FROM Drawdown__c where Payment_Method__c = 'Payment' AND Sum_of_Payment_Allocations__c > 0];
        delete dlistPayment;   

        dlistUpdated = [SELECT Id, Date__c, Amount__c, Payment_Method__c,Sum_of_Repayments__c  FROM Drawdown__c where id =: dlistOriginal[0].id];
        system.assertEquals(0, dlistUpdated[0].Sum_of_Repayments__c,'Payments Allocated should again be zero.');

        delete dlistUpdated; // for good measure make sure the original drawdown can be deleted too.

        Test.stopTest();
    }
}