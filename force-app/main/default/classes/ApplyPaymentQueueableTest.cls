@isTest
public class ApplyPaymentQueueableTest {
    @TestSetup
    static void initailizeTestData(){
        // Account
        Id RecordTypeIdAccount = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId();
        
        
        Account generalBusinessAcc = new Account();
        generalBusinessAcc.Name='account';
        generalBusinessAcc.BillingStreet = 'Testtest';
        generalBusinessAcc.BillingState = 'CA';
        generalBusinessAcc.BillingCity = 'City';
        generalBusinessAcc.BillingPostalCode = '10001';
        generalBusinessAcc.Billingcountry='Canada';
        generalBusinessAcc.ShippingStreet = 'Test';
        generalBusinessAcc.ShippingState = 'New York';
        generalBusinessAcc.ShippingCountry = 'UNITED STATES';
        generalBusinessAcc.ShippingPostalCode = '10001';
        generalBusinessAcc.ShippingCity = 'Lake Trees';
        generalBusinessAcc.Account_Type__c = 'Treatment Provider Firm';
        generalBusinessAcc.RecordTypeId = RecordTypeIdAccount;
        
        
        // Account # 2
        Id RecordTypeIdAccount2 = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        
        
        Account lawfirm = new Account();
        lawfirm.Name='Test Lawfirm';
        lawfirm.BillingStreet = 'sample';
        lawfirm.BillingState = 'AK';
        lawfirm.BillingCity = 'City1';
        lawfirm.BillingPostalCode = '987654';
        lawfirm.Billingcountry='Uganda';
        lawfirm.ShippingStreet = 'Test1';
        lawfirm.ShippingState = 'Los Angeles';
        lawfirm.ShippingPostalCode = '123456';
        lawfirm.ShippingCity = 'Lake View';
        lawfirm.Account_Type__c = 'Treatment Provider Firm';
        lawfirm.RecordTypeId = RecordTypeIdAccount2;
        //insert lawfirm;
        
        Account lawfirm2 = new Account();
        lawfirm2.Name='example account';
        lawfirm2.BillingStreet = 'example';
        lawfirm2.BillingState = 'SC';
        lawfirm2.BillingCity = 'example city';
        lawfirm2.BillingPostalCode = '012457';
        lawfirm2.Billingcountry='Pakistan';
        lawfirm2.ShippingStreet = 'Test1';
        lawfirm2.ShippingState = 'New Jersey';
        lawfirm2.ShippingPostalCode = '654321';
        lawfirm2.ShippingCity = 'Lake View Park';
        lawfirm2.Account_Type__c = 'Treatment Provider Firm';
        lawfirm2.RecordTypeId = RecordTypeIdAccount2;
        //insert lawfirm2;
        //
        Id RecordTypeIdAccount3 = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assessment Provider').getRecordTypeId();
        
        
        Account assessmentProviderAcc = new Account();
        assessmentProviderAcc.Name='Test Assessment Provider';        
        assessmentProviderAcc.RecordTypeId = RecordTypeIdAccount3;
        
        insert (new SObject[]{generalBusinessAcc, assessmentProviderAcc, lawfirm, lawfirm2});          
        
        // Contact
        Id RecordTypeIdContact = 
            Schema.SObjectType.Contact.getRecordTypeInfosByName().get('General Contact').getRecordTypeId();
        
        Contact primaryContct = new Contact();
        
        primaryContct.lastname = 'testtest';
        primaryContct.email = 'testtest@testtest.com';
        primaryContct.AccountId = generalBusinessAcc.id;
        primaryContct.RecordTypeId = RecordTypeIdContact;
        
        //insert primaryContct;
        
        // Contact # 2
        Id RecordTypeIdContact2 = 
            Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId();
        
        Contact lawyerContact = new Contact();
        
        lawyerContact.lastname = 'test';
        lawyerContact.email = 'test@test.com';
        lawyerContact.AccountId = lawfirm.id;
        lawyerContact.RecordTypeId = RecordTypeIdContact2;
          
        
        insert (new SObject[]{primaryContct, lawyerContact});
        
        
        // Opportunity 
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        Opp.AccountId = generalBusinessAcc.Id;
        Opp.Lawyer__c = lawyerContact.Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = lawfirm.Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = primaryContct.Id;
        Opp.Interest_Rate__c = 1.0;
        Opp.Minimum_Interest_Period__c = '12 months';
        Opp.Compounding_Interest__c = 'Annual';
        Opp.Interest_Compounding_Period__c = 'Simple Interest';
        Opp.Interest_Deferral_Period__c = '0';
        Opp.Re_Assessed_Loan__c = null;
        Opp.Amount = 5.0;
        //insert Opp; 
        
        insert (new SObject[]{Opp});
                
        // Drawdown
        Drawdown__c drw = new Drawdown__c();
        
        drw.Opportunity__c = Opp.id;
        drw.Amount__c = 1000;
        drw.Date__c = Date.today().addDays(-30);
        drw.Payment_Method__c = 'e-Transfer';
        drw.Reference_Notes__c = 'Payment to Client';
        
        insert (new SObject[]{drw});
        
    }
    public static testmethod void testPaymentQueueable(){
        
        Account acc = [select id, Is_Async_Processing__c from account where name = 'account' limit 1];  
        acc.Is_Async_Processing__c = true;
        update acc;
        String oppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        PaymentInfo info = new PaymentInfo();
        info.accountId = acc.Id;
        info.payoutDate = '2018-01-01';
        info.searchType = 'Payout';
        info.oppId = oppId;
        info.action = 'Partial Payment';
        info.OppBadDebts = '';
        System.enqueueJob(new ApplyPaymentQueueable(acc.Id, new List<PaymentInfo>{info}));        
        test.stopTest();
        acc = [select id, Is_Async_Processing__c from account where name = 'account' limit 1]; 
        System.assertEquals(false, acc.Is_Async_Processing__c);
    }

}