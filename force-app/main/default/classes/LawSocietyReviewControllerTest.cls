@isTest
private with sharing class LawSocietyReviewControllerTest {
    
    @testSetup
    static void initailizeTestData(){
        
        RecordType lawFirmRTAccount = [SELECT Id FROM RecordType Where SobjectType = 'Account' AND Name = 'Law Firm'];
        RecordType lawyerRTContact = [SELECT Id FROM RecordType Where SobjectType = 'Contact' AND Name = 'Lawyers'];
        RecordType clientOppoRT = [SELECT Id FROM RecordType Where SobjectType = 'Opportunity' AND Name = 'Client Opportunity Record Type'];
        
        Account LawFirmAccount = new Account(Name = 'Test Lawfirm Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = lawFirmRTAccount.Id);
        insert LawFirmAccount;
        
        Contact LawyerContact = new Contact(LastName = 'Test Lawyer Contact', AccountId = LawFirmAccount.Id,
                                            RecordTypeId = lawyerRTContact.Id,Upcoming_Hearings__c='No');
        insert LawyerContact;
        
        Opportunity clientOpp = new Opportunity(Name = 'Test Client Opportunity', RecordTypeId = clientOppoRT.Id, AccountId = LawFirmAccount.Id);
        clientOpp.Lawyer__c = LawyerContact.Id;
        clientOpp.CloseDate = Date.today().addDays(14);
        clientOpp.StageName = 'Closed With Loan';
        clientOpp.Law_Firm__c = LawFirmAccount.Id;        
        clientOpp.Stage_Status__c = 'Approved';
        insert clientOpp; 
    }

    static testMethod void test_getLawyersList(){
        Test.startTest();
        User currentUser = [SELECT Id, Law_Society_Review__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        currentUser.Law_Society_Review__c = false;
        update currentUser;
        System.assertEquals(false,(Boolean)LawSocietyReviewController.getLawyersList(Date.today().addYears(-3)+'',Date.today()+'','ELFI', '', 'SUM(Amount__c)','ASC','','','',null,null).get('isCurrentUserSeeLawSocietyReviewReport'));
        Test.stopTest();
    }

    static testMethod void test_ContentNotes(){
        Test.startTest();
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Test Lawyer Contact' LIMIT 1];
        System.assertEquals(0,LawSocietyReviewController.getContentNotes(contact.Id).size());
        LawSocietyReviewController.saveNewNote('Test',contact.Id);
        System.assertEquals(1,LawSocietyReviewController.getContentNotes(contact.Id).size());
        Test.stopTest();
    }

    static testMethod void test_saveContacts(){
        Test.startTest();
        Contact contact = [SELECT Id, Upcoming_Hearings__c FROM Contact WHERE LastName = 'Test Lawyer Contact' LIMIT 1];
        System.assertEquals('No',contact.Upcoming_Hearings__c);
        contact.Upcoming_Hearings__c = 'Yes';
        List<LawSocietyReviewController.Lawyer> lawyersList = new List<LawSocietyReviewController.Lawyer>();
        lawyersList.add(new LawSocietyReviewController.Lawyer(contact,0,0));
        LawSocietyReviewController.saveContacts(JSON.serialize(lawyersList));
        contact = [SELECT Id, Upcoming_Hearings__c FROM Contact WHERE LastName = 'Test Lawyer Contact' LIMIT 1];
        System.assertEquals('Yes',contact.Upcoming_Hearings__c);
        Test.stopTest();
    }
}