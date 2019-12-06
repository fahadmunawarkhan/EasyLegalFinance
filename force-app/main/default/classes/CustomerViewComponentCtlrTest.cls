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
        
        // Note insert
       /* ContentNote cnote = new ContentNote();
        cnote.Title = 'testt';
        cnote.Content = Blob.valueOf('Helloworld');
        insert (cnote);
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        
        cdl.ContentDocumentId = cnote.id;
        cdl.LinkedEntityId = acct2.id;
        cdl.ShareType = 'v';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;*/
        
    }
    
    public static testMethod void criticalDateTest() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'example account' LIMIT 1];
        List<Critical_Date__c> critcalDateList = new List<Critical_Date__c>();
        
        for(Integer i = 0; i<5; i++){
            critcalDateList.add(new Critical_Date__c(Name__c = 'Examination', Account__c = acc.Id, Date__c = Date.today()));
        }
        
        try{
            CustomerViewComponentCtlr.saveCriticalDateList(critcalDateList);
            List<Critical_Date__c> result = CustomerViewComponentCtlr.getCriticalDatesList(acc.Id);
            system.assertEquals(5, result.size());
            CustomerViewComponentCtlr.deleteCriticalDate(critcalDateList[0].Id);
        }catch(exception e){
            
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void startTestProcess(){
        
        String acct2 = [select id from account where name = 'sample account' limit 1].id;
        String acct = [select id from account where name = 'account' limit 1].id;
        
        String OppId = [select id from opportunity where name = 'Test Opportunity' limit 1].id;
        
        String OppId2 = [select id from opportunity where name = 'Test Opportunity 3' limit 1].id;
        
        test.startTest();
        ContentNote cnote = new ContentNote();
        cnote.Title = 'testt';
        cnote.Content = Blob.valueOf('Helloworld'.escapeHTML4());
        insert(cnote);
        
        String cnoteId = cnote.Id;        
        CustomerViewComponentCtlr.updateContentNote(cnoteId, 'UpdatedNote');
            
        ContentDocumentLink cdl = new ContentDocumentLink();
        
        cdl.ContentDocumentId = cnote.id;
        cdl.LinkedEntityId = acct2;
        cdl.ShareType = 'v';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        
        CustomerViewComponentCtlr.getAccountInfo(acct2);
        
        system.assertEquals(null, CustomerViewComponentCtlr.oppInfo);
        system.assertEquals(null, CustomerViewComponentCtlr.oppList);
        
        //CustomerViewComponentCtlr.NoteWrapper nwrapper = new CustomerViewComponentCtlr.NoteWrapper();
        
        //system.assertEquals(null, nwrapper.body);
        //system.assertEquals(null, nwrapper.note);
        
        
        
        CustomerViewComponentCtlr.getEnhancedNotes(acct2);
        
        CustomerViewComponentCtlr.getOpportunities(acct);
        
        CustomerViewComponentCtlr.getOpportunitiesOrderedByDate(acct);
        
        CustomerViewComponentCtlr.getSingleOpportunity(oppId);
        
        CustomerViewComponentCtlr.changeToShortfallStage(OppId, acct, '2018-01-01');
        CustomerViewComponentCtlr.applyPartialPayments(OppId, acct, '2018-01-01', 'eft', 'chq');
        
        CustomerViewComponentCtlr.delContentNote(cnoteId);
        test.stopTest();
        
    }
    @isTest
    static void startTestProcess2(){
        
        String acct2 = [select id from account where name = 'sample account' limit 1].id;
        String acct = [select id from account where name = 'account' limit 1].id;
        
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        
        String OppId2 = [select id from opportunity where name = 'Test Opportunity 3'].id;
        
        String contactId = [select id from contact where lastname = 'test' limit 1].id;
        
        test.startTest();
        
        decimal amount = 1;
        CustomerViewComponentCtlr.calculatePayments(acct, amount, 'Payout');
        
        amount = 5;
        CustomerViewComponentCtlr.calculatePayments(acct, amount, 'Payout');
        
        CustomerViewComponentCtlr.changeToBadDebtStage(OppId, acct, '2018-01-01');
        
        CustomerViewComponentCtlr.changeToSurplusStage(OppId, acct, '2018-01-01');
        
        //CustomerViewComponentCtlr.applyFullPayments(OppId2, acct, 'Payout');
        
        CustomerViewComponentCtlr.getTransactions(acct);
        
        CustomerViewComponentCtlr.OpportunityTransaction optr = new CustomerViewComponentCtlr.OpportunityTransaction();
        
        system.assertEquals(null, optr.Name);
        system.assertEquals(null, optr.opportunityNumber);
        system.assertEquals(null, optr.transactions);
        system.assertEquals(null, optr.paymentAmountSubtotal);
        system.assertEquals(null, optr.advanceSubtotal);
        system.assertEquals(null, optr.accruedInterestSubtotal);
        system.assertEquals(null, optr.outstandingBalanceSubtotal);
        system.assertEquals(null, optr.perDiemSubtotal);
        
        test.stopTest();
        
    }
    @isTest
    static void startTestProcess3(){
        
        Account acct3 = [select id,ShippingState from account where name = 'example account' limit 1];
        String acct2 = [select id from account where name = 'sample account' limit 1].id;
        String acct = [select id from account where name = 'account' limit 1].id;
        
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        
        String OppId2 = [select id from opportunity where name = 'Test Opportunity 3'].id;
        
        Opportunity Opp4 = [select id,Interest_Rate__c from opportunity where name = 'Test Opportunity 4' limit 1];
        
        String contactId = [select id from contact where lastname = 'test' limit 1].id;
        contact contcts = [select id,email from contact where lastname = 'testt' limit 1];
        
        test.startTest();
        
        CustomerViewComponentCtlr.getOpptyTransactions(acct);
        
        CustomerViewComponentCtlr.getLastOpportunity(acct);
        
        CustomerViewComponentCtlr.getLawyerInfo(contactId);
        
        CustomerViewComponentCtlr.getLastContact(acct2);
        
        CustomerViewComponentCtlr.getFinancingStatementHistory(acct2);
        
        CustomerViewComponentCtlr.getFirmHistory(acct2);
        
        CustomerViewComponentCtlr.getContactHistorySingle(contactId);
        
        CustomerViewComponentCtlr.getContactHistory(acct2);
        
        CustomerViewComponentCtlr.runPayoutForAllOpps(acct, String.valueOf(date.today()));
        
        CustomerViewComponentCtlr.getLoanSummary(acct);
        
        CustomerViewComponentCtlr.getLoanSummary(acct2);
        
        //CustomerViewComponentCtlr.generatePayoutBalance(acct3.id, String.valueOf(date.today()));
        
        CustomerViewComponentCtlr.getAccountLabelsMap();
        
        CustomerViewComponentCtlr.getPickListValues('Opportunity', 'Minimum_Interest_Period__c');
        
        acct3.ShippingState = 'Punjab';
        CustomerViewComponentCtlr.saveAccount(acct3);
        
        Opp4.Interest_Rate__c = 2;
        CustomerViewComponentCtlr.saveOppty(Opp4);
        
        contcts.email = 'email@email.com';
        CustomerViewComponentCtlr.saveContact(contcts);
        
        //CustomerViewComponentCtlr.deleteAccount(acct3.id);
        
        CustomerViewComponentCtlr.getLatestOppty(acct);
        
        /*ContentNote cn = new ContentNote();
        cn.Title = 'test';
        cn.Content = Blob.valueOf('Hello');
        insert cn;
        
        CustomerViewComponentCtlr.createRecord(cn, acct2);*/
        
        CustomerViewComponentCtlr.getCurrentUserInfo();
        
        test.stopTest();
        
    }
    
    
    // ----->>>>> Usama <<<<<------
    	@isTest
    	static void Process4(){
        	test.startTest();
            	insertAccount();
            	insertOpps(1);
            	Account acc = [SELECT id from Account where Name = 'Test Account'];
            	CustomerViewComponentCtlr.getOpportunitiesToGeneratePayout(acc.Id);
            test.stopTest();
    	}
    // ----------------------------
    
    
    public static void insertAccount(){
        Id RecordTypeIdAccount = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId();
        Account testAccount = new Account();
        testAccount.Name='Test Account';
        testAccount.BillingStreet = 'Testtest';
        testAccount.BillingState = 'CA';
        testAccount.BillingCity = 'City';
        testAccount.BillingPostalCode = '10001';
        testAccount.Billingcountry='Canada';
        testAccount.ShippingStreet = 'Test';
        testAccount.ShippingState = 'New York';
        testAccount.ShippingCountry = 'UNITED STATES';
        testAccount.ShippingPostalCode = '10001';
        testAccount.ShippingCity = 'Lake Trees';
        testAccount.Account_Type__c = 'Client';
        testAccount.RecordTypeId = RecordTypeIdAccount;
        insert testAccount;


	}
    
    public static void insertOpps(Integer oppsCount){        
        Account account = [select Id from Account where Name='Test Account'];
        Account acct2 = [select Id from Account where Name='sample account'];
        Contact contct = [select Id from Contact where lastname='test'];
        Contact testContact = [select Id from Contact where name='testtest'];
        system.debug(account);
        system.debug(acct2);
        system.debug(contct);
        system.debug(testContact);
        List<Opportunity> opps = new List<Opportunity>();
        for ( Integer i = 0; i < oppsCount; i++) {
            Opportunity testOpp = new Opportunity();
            testOpp.Name = 'Test Opportunity_' + i;
            testOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
            testOpp.AccountId = account.Id;
            testOpp.Lawyer__c = contct.Id;
            testOpp.CloseDate = Date.today().addDays(14);
            testOpp.StageName = 'Closed With Loan';
            testOpp.Law_Firm__c = acct2.Id;        
            testOpp.Stage_Status__c = 'Approved';
            testOpp.Type_of_Loan__c = 'Facility Loan';
            testOpp.Primary_Contact__c = testContact.Id;
            testOpp.Interest_Rate__c = 24.0;
            testOpp.Minimum_Interest_Period__c = '6 months';
            testOpp.Compounding_Interest__c = 'Semi-Annual';
            testOpp.Interest_Deferral_Period__c = '0';
            testOpp.Interest_Compounding_Period__c = 'Compounding Interest';
            testOpp.Re_Assessed_Loan__c = null;
            opps.add(testOpp);            
        }
        
        insert opps;
    }
    
    public static void insertDrawdowns(){
        Account account = [select Id from Account where Name='Test Account'];
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];
        List<Drawdown__c> drawdowns = new List<Drawdown__c>();
        for (Opportunity opp : opps){
            Drawdown__c d = new Drawdown__c();
        
            d.Opportunity__c = opp.id;
            d.Amount__c = 1000;
            d.Date__c = Date.today().addDays(-30);
            d.Payment_Method__c = 'e-Transfer';
            d.Reference_Notes__c = 'Payment to Client';
            
            drawdowns.add(d);            
        }
        insert drawdowns;
    }
    
    public static testMethod void testCalculatePayments(){
        Test.startTest();
        insertAccount();
        insertOpps(2);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];  
        List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq', 'Payout');
        System.assertEquals(oppsAfterCalculation[0].Total_Payout__c, oppsAfterCalculation[0].Temp_Payment_Received__c);
        System.assertEquals(oppsAfterCalculation[1].Temp_Payment_Received__c, 1500.0-oppsAfterCalculation[0].Total_Payout__c);        
        Task task = [select Id, Subject, Description from Task LIMIT 1];
        System.assertEquals('Complete posting payment of $1,500.00 for Test Account', task.Subject);
        System.assertEquals('Payment of $1,500.00 with EFT # of eft and CHQ # of chq was calculated but not applied to Test Account', task.Description);
        Test.stopTest();
    }
    
    public static testMethod void testApplyPayments1(){
        Test.startTest();
        insertAccount();
        insertOpps(2);
       // insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        //List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[0].Id, 'Bad Debt', false);
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[1].Id, 'Shortfall', true);        
        System.assertEquals('Closed - Shortfall', oppsAfterApplying[0].Stage_Status__c);
        System.assertEquals('Closed - Bad Debt', oppsAfterApplying[1].Stage_Status__c); 
        Test.stopTest();
    }
    
    
    public static testMethod void testApplyPayments(){
        Test.startTest();
        insertAccount();
        insertOpps(2);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        //List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[0].Id, 'Closed Paid', false);
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[1].Id, 'Partial Payment', true);
        System.assertEquals('Active - Partial Payment', oppsAfterApplying[0].Stage_Status__c);
        System.assertEquals('Closed - Paid', oppsAfterApplying[1].Stage_Status__c); 
        List<Task> tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }
	public static testMethod void testApplyPayments2(){
        Test.startTest();
        insertAccount();
        insertOpps(1);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        //List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[0].Id, 'Surplus', true);
        System.assertEquals('Closed - Surplus', oppsAfterApplying[0].Stage_Status__c);        
        Test.stopTest();
    }
    
    public static testMethod void testApplyMiscPayment(){
        Test.startTest();
        insertAccount();
        insertOpps(1);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        //List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1000.0, 'eft', 'chq');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Misc Income Payment', 'eft', 'chq', opps[0].Id, 'Misc Income Payment', true);
        List<Drawdown__c> drawdowns = [select Id, Reference_Notes__c from Drawdown__c where Payment_Method__c='Payment'];
        System.assertEquals('Miscellaneous Payment', drawdowns[0].Reference_Notes__c);
        Test.stopTest();
    }
	
    public static testMethod void testApplyRefund(){
        Test.startTest();
        insertAccount();
        insertOpps(1);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1000.0, 'eft', 'chq', 'Refund');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Refund', 'eft', 'chq', opps[0].Id, 'Refund', true);
        List<Drawdown__c> drawdowns = [select Id, Reference_Notes__c from Drawdown__c where Payment_Method__c='Other'];
        System.assertEquals('Refund', drawdowns[0].Reference_Notes__c);
        Test.stopTest();
    }    	
    
    public static testMethod void testTaskDeletion(){
        Test.startTest();
        insertAccount();
        insertOpps(1);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        List<Opportunity> opps = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq', 'Payout');
        List<Task> tasks = [select Id from Task];
        System.assertEquals(false, tasks.isEmpty());        
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[0].Id, 'Closed Paid', true);
        tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }
    
    public static testMethod void testTaskDeletionAmount0(){
        Test.startTest();
        insertAccount();
        insertOpps(1);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        List<Opportunity> opps = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq', 'Payout');
        List<Task> tasks = [select Id from Task];
        System.assertEquals(false, tasks.isEmpty());        
        CustomerViewComponentCtlr.calculatePayments(account.Id, 0.0, 'eft', 'chq', 'Payout');
        tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }
    
    public static testMethod void testCreateTaskOnPaymentApplyingError(){
        Test.startTest();
        insertAccount();
        insertOpps(1);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        List<Opportunity> opps = [select Id, Name, Loan_Requests__c from Opportunity];
        List<Task> tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty()); 
        CustomerViewComponentCtlr.createPaymentApplyingErrorTask(account.Id, opps[0].Id);
        tasks = [select Id, Subject, Description from Task];
        System.assertEquals(false, tasks.isEmpty());
        System.assertEquals('Payment allocation failed', tasks[0].Subject);
        System.assertEquals('Payment was not applied to: ' + opps[0].Name + ' ' + opps[0].Loan_Requests__c + '.', tasks[0].Description);
        Test.stopTest();
    }
    
    public static testMethod void testDeletePaymentApplyingErrorTasks(){
        Test.startTest();
        insertAccount();
        insertOpps(1);
        insertDrawdowns();
        Account account = [select Id from Account where Name='Test Account'];
        List<Opportunity> opps = [select Id, Name, Loan_Requests__c from Opportunity];
        CustomerViewComponentCtlr.createPaymentApplyingErrorTask(account.Id, opps[0].Id);
        List<Task> tasks = [select Id from Task];
        System.assertEquals(false, tasks.isEmpty());
        CustomerViewComponentCtlr.deletePaymentApplyingErrorTasks(account.Id, opps[0].Id);
        tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }

}
