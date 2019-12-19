@isTest
public class CustomerViewComponentCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){
        // Account
        Id RecordTypeIdAccount = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId();
        
        
        Account acct = new Account();
        acct.Name='account';
        acct.BillingStreet = 'Testtest';
        acct.BillingState = 'CA';
        acct.BillingCity = 'City';
        acct.BillingPostalCode = '10001';
        acct.Billingcountry='Canada';
        acct.ShippingStreet = 'Test';
        acct.ShippingState = 'New York';
        acct.ShippingCountry = 'UNITED STATES';
        acct.ShippingPostalCode = '10001';
        acct.ShippingCity = 'Lake Trees';
        acct.Account_Type__c = 'Treatment Provider Firm';
        acct.RecordTypeId = RecordTypeIdAccount;
        insert acct;
        
        // Account # 2
        Id RecordTypeIdAccount2 = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        
        
        Account acct2 = new Account();
        acct2.Name='sample account';
        acct2.BillingStreet = 'sample';
        acct2.BillingState = 'AK';
        acct2.BillingCity = 'City1';
        acct2.BillingPostalCode = '987654';
        acct2.Billingcountry='Uganda';
        acct2.ShippingStreet = 'Test1';
        acct2.ShippingState = 'Los Angeles';
        acct2.ShippingPostalCode = '123456';
        acct2.ShippingCity = 'Lake View';
        acct2.Account_Type__c = 'Treatment Provider Firm';
        acct2.RecordTypeId = RecordTypeIdAccount2;
        insert acct2;
        
        Account acct3 = new Account();
        acct3.Name='example account';
        acct3.BillingStreet = 'example';
        acct3.BillingState = 'SC';
        acct3.BillingCity = 'example city';
        acct3.BillingPostalCode = '012457';
        acct3.Billingcountry='Pakistan';
        acct3.ShippingStreet = 'Test1';
        acct3.ShippingState = 'New Jersey';
        acct3.ShippingPostalCode = '654321';
        acct3.ShippingCity = 'Lake View Park';
        acct3.Account_Type__c = 'Treatment Provider Firm';
        acct3.RecordTypeId = RecordTypeIdAccount2;
        insert acct3;
        
        // Contact
        Id RecordTypeIdContact = 
            Schema.SObjectType.Contact.getRecordTypeInfosByName().get('General Contact').getRecordTypeId();
        
        Contact contct = new Contact();
        
        contct.lastname = 'testtest';
        contct.email = 'testtest@testtest.com';
        contct.AccountId = acct.id;
        contct.RecordTypeId = RecordTypeIdContact;
        
        insert contct;
        
        // Contact # 2
        Id RecordTypeIdContact2 = 
            Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId();
        
        Contact contct2 = new Contact();
        
        contct2.lastname = 'test';
        contct2.email = 'test@test.com';
        contct2.AccountId = acct2.id;
        contct2.RecordTypeId = RecordTypeIdContact2;
        
        insert contct2;
        
        Contact contct3 = new Contact();
        
        contct3.lastname = 'testt';
        contct3.email = 'testt@testt.com';
        contct3.AccountId = acct3.id;
        contct3.RecordTypeId = RecordTypeIdContact2;
        
        insert contct3;
        
        // Opportunity 
        Opportunity Oppc = new Opportunity();
        Oppc.Name = 'Test Opportunity 4';
        Oppc.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        Oppc.AccountId = acct3.Id;
        Oppc.Lawyer__c = contct.Id;
        Oppc.CloseDate = Date.today().addDays(14);
        Oppc.StageName = 'Closed With Loan';
        Oppc.Law_Firm__c = acct2.Id;        
        Oppc.Stage_Status__c = 'Approved';
        Oppc.Type_of_Loan__c = 'Facility Loan';
        Oppc.Primary_Contact__c = contct3.Id;
        Oppc.Interest_Rate__c = 1.0;
        Oppc.Minimum_Interest_Period__c = '12 months';
        Oppc.Compounding_Interest__c = 'Annual';
        Oppc.Re_Assessed_Loan__c = null;
        
        insert Oppc;
        
        // Opportunity 
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        Opp.AccountId = acct.Id;
        Opp.Lawyer__c = contct.Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = acct2.Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contct.Id;
        Opp.Interest_Rate__c = 1.0;
        Opp.Minimum_Interest_Period__c = '12 months';
        Opp.Compounding_Interest__c = 'Annual';
        Opp.Interest_Compounding_Period__c = 'Simple Interest';
        Opp.Interest_Deferral_Period__c = '0';
        Opp.Re_Assessed_Loan__c = null;
        Opp.Amount = 5.0;
        insert Opp; 
        
        // Opportunity 
        Opportunity Opp2 = new Opportunity();
        Opp2.Name = 'Test Opportunity 2';
        Opp2.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        Opp2.AccountId = acct.Id;
        Opp2.Lawyer__c = contct.Id;
        Opp2.CloseDate = Date.today().addDays(20);
        Opp2.StageName = 'Closed With Loan';
        Opp2.Law_Firm__c = acct2.Id;        
        Opp2.Stage_Status__c = 'Approved';
        Opp2.Type_of_Loan__c = 'Facility Loan';
        Opp2.Primary_Contact__c = contct.Id;
        Opp2.Interest_Rate__c = 1.0;
        Opp2.Minimum_Interest_Period__c = '12 months';
        Opp2.Compounding_Interest__c = 'Annual';
        Opp2.Re_Assessed_Loan__c = null;
        insert Opp2;
        
        // Opportunity 
        Opportunity Op = new Opportunity();
        Op.Name = 'Test Opportunity 3';
        Op.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        Op.AccountId = acct2.Id;
        Op.Lawyer__c = contct.Id;
        Op.CloseDate = Date.today().addDays(15);
        Op.StageName = 'Closed With Loan';
        Op.Law_Firm__c = acct2.Id;        
        Op.Stage_Status__c = 'Approved';
        //Op.Type_of_Loan__c = 'Facility Loan';
        Op.Primary_Contact__c = contct2.Id;
        Op.Re_Assessed_Loan__c = null;
        insert Op;
        
        // Drawdown
        Drawdown__c drw = new Drawdown__c();
        
        drw.Opportunity__c = Opp.id;
        drw.Amount__c = 2;
        drw.Reference_Notes__c = 'Referral Fee';
        
        insert drw;
        
        Drawdown__c drw2 = new Drawdown__c();
        
        drw2.Opportunity__c = Opp2.id;
        drw2.Amount__c = 2;
        drw2.Reference_Notes__c = 'Referral Fee';
        
        //insert drw2;
        
        Opportunity_Service_Provider__c sp = new Opportunity_Service_Provider__c();
        
        sp.Allowance__c = 1;
        sp.Opportunity__c = Opp.id;
        sp.Status__c = 'Waiting To Send Schedule';
        sp.Service_Provider_Facility__c = acct.id;
        
        insert sp;
        
        Service_Provider_Drawdown__c spd = new Service_Provider_Drawdown__c();
        
        spd.Amount__c = 1;
        spd.Drawdown_Date__c = date.today();
        spd.Opportunity_Service_Provider_MD__c = sp.id;
        spd.Payment_Method__c = 'Payment';
        
        insert spd;
        
        Amendment__c amnd = new Amendment__c();
        
        //amnd.name = 'test amendment';
        amnd.Opportunity__c = Opp.id;
        amnd.Amount__c = 1;
        
        insert amnd;
        
        Firm__c frm = new Firm__c();
        
        //frm.Name = 'test firm';
        frm.Law_Firm__c = acct2.id;
        frm.Lawyer__c = contct2.id;
        frm.Opportunity__c = Op.id;
        
        insert frm;
    }
    
    public static testmethod void test_Process1(){
        
        Account acc = [select id from account where name = 'sample account' limit 1];        
        test.startTest();
        ContentNote cnote = new ContentNote();
        cnote.Title = 'testt';
        cnote.Content = Blob.valueOf('Helloworld'.escapeHTML4());
        insert(cnote);
        
        String cnoteId = cnote.Id;        
        CustomerViewComponentCtlr.updateContentNote(cnoteId, 'UpdatedNote');
            
        ContentDocumentLink cdl = new ContentDocumentLink();
        
        cdl.ContentDocumentId = cnote.id;
        cdl.LinkedEntityId = acc.Id;
        cdl.ShareType = 'v';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        
        CustomerViewComponentCtlr.getAccountInfo(acc.Id);
        
        system.assertEquals(null, CustomerViewComponentCtlr.oppInfo);
        system.assertEquals(null, CustomerViewComponentCtlr.oppList);
        
        CustomerViewComponentCtlr.getEnhancedNotes(acc.Id);
        CustomerViewComponentCtlr.delContentNote(cnoteId);
        
        //exception coverage
        try{
            string cId = 'Invalid Id';
            CustomerViewComponentCtlr.updateContentNote(cId, 'UpdatedNote');
        }catch(exception e){
            
        }
        
        try{
            string cId = 'Invalid Id';
            CustomerViewComponentCtlr.delContentNote(cId);
        }catch(exception e){
            
        }
        
        //update account
        CustomerViewComponentCtlr.saveAccount(acc);
        
        try{
            CustomerViewComponentCtlr.saveAccount(new Account());
        }catch(exception e){
            
        }
        Account testAcc = new Account();
        testAcc.Name = 'Test Acc del';
        insert testAcc;
        CustomerViewComponentCtlr.deleteAccount(testAcc.Id);
        test.stopTest();
    }
    
    public static testmethod void test_Process2(){
        
        String acct = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity' limit 1].id;
        test.startTest();        
        List<Opportunity> opps = CustomerViewComponentCtlr.getOpportunities(acct);
        CustomerViewComponentCtlr.getOpportunitiesOrderedByDate(acct);        
        Opportunity opp = CustomerViewComponentCtlr.getSingleOpportunity(oppId);
        
        CustomerViewComponentCtlr.getRecentOpportunity(acct);
        CustomerViewComponentCtlr.getLatestOppty(acct);
        
        CustomerViewComponentCtlr.saveOppty(opp);
        try{
            CustomerViewComponentCtlr.saveOppty(new Opportunity());
        }catch(exception e){
            
        }
        test.stopTest();
    }
    
    public static testmethod void test_Process3(){
        
        String accId = [select id from account where name = 'account' limit 1].id;         
        test.startTest();        
        List<Opportunity> opps = CustomerViewComponentCtlr.getOpportunitiesToGeneratePayout(accId);        
        system.assert(!opps.isEmpty());
        test.stopTest();
    }
    
    public static testmethod void test_Process4(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();        
        decimal amount = 1;
        List<Opportunity> opps = CustomerViewComponentCtlr.calculatePayments(accId, amount, 'Payout');        
        system.assert(!opps.isEmpty());
        amount = 5;
        CustomerViewComponentCtlr.calculatePayments(accId, amount, 'Payout');
        test.stopTest();
    }
    
    public static testmethod void test_Process5(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.changeToBadDebtStage(OppId, accId, '2018-01-01');
        test.stopTest();
    }
    public static testmethod void test_Process6(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.changeToSurplusStage(OppId, accId, '2018-01-01');
        test.stopTest();
    }
    public static testmethod void test_Process7(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.changeToShortfallStage(OppId, accId, '2018-01-01');
        test.stopTest();
    }
    
    public static testmethod void test_Process8(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.applyPartialPayments(OppId, accId, '2018-01-01', 'eft', 'chq');
        test.stopTest();
    }
    public static testmethod void test_Process9(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.applyFullPayments(OppId, accId, null, '2018-01-01', 'eft', 'chq');
        test.stopTest();
    }
    public static testmethod void test_Process10(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.applyMiscPayments(OppId, accId, '2018-01-01', 'eft', 'chq');
        CustomerViewComponentCtlr.getTransactions(accId);
        test.stopTest();
    }
    
    public static testmethod void test_Process11(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        List<Opportunity> opps = CustomerViewComponentCtlr.getOpportunities(accId);
        test.startTest();
        CustomerViewComponentCtlr.closeMultipleLoans(opps, accId, null, '2018-01-01');
        CustomerViewComponentCtlr.getOpptyTransactions(accId);
        test.stopTest();
    }
    public static testmethod void test_Process12(){
        
        String accId = [select id from account where name = 'account' limit 1].id;
        String lawyerId = [select id from contact where lastname ='test' limit 1].Id;
        test.startTest();
        CustomerViewComponentCtlr.getLastOpportunity(accId);
        CustomerViewComponentCtlr.getLawyerInfo(lawyerId);
        Contact con = CustomerViewComponentCtlr.getLastContact(accId);
        
        CustomerViewComponentCtlr.saveContact(con);
        try{
            CustomerViewComponentCtlr.saveContact(con);
        }catch(exception e){
            CustomerViewComponentCtlr.saveContact(new Contact());
        }
        test.stopTest();
    }
    
    public static testmethod void test_Process13(){
        String acct2 = [select id from account where name = 'sample account' limit 1].id;
        String contactId = [select id from contact where lastname = 'test' limit 1].id;
        test.startTest();
        CustomerViewComponentCtlr.getFinancingStatementHistory(acct2);
        CustomerViewComponentCtlr.getFirmHistory(acct2);
        CustomerViewComponentCtlr.getContactHistorySingle(contactId);
        CustomerViewComponentCtlr.getContactHistory(acct2);
        test.stopTest();
    }
    
    public static testmethod void test_Process14(){
        String accId = [select id from account where name = 'account' limit 1].id;
        String acct2 = [select id from account where name = 'sample account' limit 1].id;
        test.startTest();
        CustomerViewComponentCtlr.runPayoutForAllOpps(accId,'2018-01-01');
        try{
            CustomerViewComponentCtlr.generatePayoutBalance(acct2,'2018-01-01');
        }catch(exception e){
        }
        CustomerViewComponentCtlr.getAccountLabelsMap();
        CustomerViewComponentCtlr.getPickListValues('Opportunity', 'Minimum_Interest_Period__c');
        
        CustomerViewComponentCtlr.getLoanSummary(accId);
        CustomerViewComponentCtlr.getLoanSummary(acct2);
        try{
             CustomerViewComponentCtlr.runPayoutForAllOpps(accId,null);
        }catch(exception e){
                   }
        test.stopTest();
    }
    
    public static testMethod void criticalDateTest() {
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'account' LIMIT 1];
        List<Critical_Date__c> critcalDateList = new List<Critical_Date__c>();
        
        for(Integer i = 0; i<5; i++){
            critcalDateList.add(new Critical_Date__c(Name__c = 'Examination', Account__c = acc.Id, Date__c = Date.today()));
        }
        
        try{
            CustomerViewComponentCtlr.saveCriticalDateList(critcalDateList);
            Test.startTest();
            List<Critical_Date__c> result = CustomerViewComponentCtlr.getCriticalDatesList(acc.Id);
            system.assertEquals(5, result.size());
            CustomerViewComponentCtlr.deleteCriticalDate(critcalDateList[0].Id);
            Test.stopTest();
        }catch(exception e){
            
        }
    }
    
    public static testmethod void test_Process15(){
        String accId = [select id from account where name = 'account' limit 1].id;
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.getCurrentUserInfo();
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        CustomerViewComponentCtlr.applyPayment(accId, payoutDateStr, 'Payout', 'eft', 'chq', OppId, 'Bad Debt', false);
        test.stopTest();
    }
    
    public static testmethod void test_Process16(){
        String accId = [select id from account where name = 'account' limit 1].id;
        test.startTest();
        CustomerViewComponentCtlr.createPaymentTask(accId, 300.89, 'eft', 'chq');
        CustomerViewComponentCtlr.deletePaymentTasks(accId);
        //calculatePayments
        test.stopTest();
    }
}