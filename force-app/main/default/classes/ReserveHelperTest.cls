@isTest
public class ReserveHelperTest {
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
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 15.0;
        Opp.Interest_Compounding_Period__c = 'Simple Interest';
        Opp.Interest_Deferral_Period__c = '0';
        insert Opp;
        
        Opportunity OppoRe = new Opportunity(Name = 'Test Opportunity 2', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                             AccountId = accountList[0].Id);
        OppoRe.Lawyer__c = contactList[1].Id;
        OppoRe.CloseDate = Date.today().addDays(14);
        OppoRe.StageName = 'Closed With Loan';
        OppoRe.Law_Firm__c = accountList[1].Id;        
        OppoRe.Stage_Status__c = 'Approved';
        OppoRe.Type_of_Loan__c = 'Treatment Loan';
        OppoRe.Primary_Contact__c = contactList[0].Id;        
        OppoRe.Re_Assessed_Loan__c = Opp.Id;
        insert OppoRe;
    }
    
    public static void insertDrawdown(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 5; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50)));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    
	public static testMethod void testPrepareReserveMap1() { 
        Map<String, Object> reserveInfoMap = new Map<String, Object>();        
        Test.startTest();
        ReserveHelper.prepareReserveMap(reserveInfoMap);
        System.assertEquals(false, reserveInfoMap.get('Is_Reserve_Applied__c'));
        Test.stopTest();
    }
    public static testMethod void testPrepareReserveMap2() { 
        Map<String, Object> reserveInfoMap = new Map<String, Object>();
        reserveInfoMap.put('Is_Reserve_Applied__c', true);                
        Test.startTest();
        ReserveHelper.prepareReserveMap(reserveInfoMap);
        System.assertEquals(0.0, reserveInfoMap.get('Reserve_Amount__c'));        
        System.assertEquals(false, reserveInfoMap.get('Stop_Interest__c'));
        Test.stopTest();
    }
    public static testMethod void testUpdateReserveFields1() { 
        Opportunity opp = new Opportunity();
        opp.Reserve_Date__c = Date.today();            
        opp.Reserve_Amount__c = 100.0;
        //opp.Accrued_Interest_as_of_Reserve_Date__c = 100.0;
        Map<String, Object> reserveInfoMap = new Map<String, Object>();
        reserveInfoMap.put('Is_Reserve_Applied__c', false);        
        reserveInfoMap.put('Stop_Interest__c', false);        
        Test.startTest();
        ReserveHelper.updateOppReserveFields(opp, reserveInfoMap);
        System.assertEquals(null, opp.Reserve_Date__c);
        System.assertEquals(null, opp.Reserve_Amount__c);
        //System.assertEquals(null, opp.Accrued_Interest_as_of_Reserve_Date__c);
        Test.stopTest();        
    }
    public static testMethod void testUpdateReserveFields2() { 
        Opportunity opp = new Opportunity();
        Map<String, Object> reserveInfoMap = new Map<String, Object>();
        reserveInfoMap.put('Is_Reserve_Applied__c', true);    
        reserveInfoMap.put('Stop_Interest__c', true);        
        reserveInfoMap.put('Reserve_Date__c', Date.today());        
        reserveInfoMap.put('Reserve_Amount__c', 100.0);        
        Test.startTest();
        ReserveHelper.updateOppReserveFields(opp, reserveInfoMap);
        System.assertEquals(Date.today(), opp.Reserve_Date__c);        
        System.assertEquals(100.0, opp.Reserve_Amount__c);
        Test.stopTest();        
    }
    
    public static testMethod void testApplyReserveOn() {        
        List<Opportunity> clientOpportunities = [SELECT Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c FROM Opportunity  LIMIT 2];
        List<Map<String, Object>> reserveInfos = new List<Map<String, Object>>();
        reserveInfos.add( new Map<String, Object>() );
        reserveInfos.add( new Map<String, Object>() );
        reserveInfos[0].put('Id', clientOpportunities[0].Id);
        reserveInfos[0].put('Is_Reserve_Applied__c', true);
        reserveInfos[0].put('Reserve_Amount__c', 1000.0);
        reserveInfos[0].put('Reserve_Date__c', Date.today());
        reserveInfos[1].put('Id', clientOpportunities[1].Id);
        reserveInfos[1].put('Is_Reserve_Applied__c', true);
        reserveInfos[1].put('Reserve_Amount__c', 2000.0);
        reserveInfos[1].put('Reserve_Date__c', Date.today().addDays(1));
        Test.startTest();
        List<Opportunity> opps = ReserveHelper.applyReserveOpps(reserveInfos);
        System.assertEquals(2, opps.size());
        Opportunity opp0 = opps[0].Id == clientOpportunities[0].Id ? opps[0] : opps[1];
        Opportunity opp1 = opps[0].Id == clientOpportunities[1].Id ? opps[0] : opps[1];
        System.assertEquals(true, opp0.Is_Reserve_Applied__c);
        System.assertEquals(1000.0, opp0.Reserve_Amount__c);
        System.assertEquals(Date.today(), opp0.Reserve_Date__c);
        System.assertEquals(true, opp1.Is_Reserve_Applied__c);
        System.assertEquals(2000.0, opp1.Reserve_Amount__c);
        System.assertEquals(Date.today().addDays(1), opp1.Reserve_Date__c);        
        Test.stopTest();
    }

    public static testMethod void testApplyReserveOff() {        
        List<Opportunity> clientOpportunities = [SELECT Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c FROM Opportunity  LIMIT 2];
        List<Map<String, Object>> reserveInfos = new List<Map<String, Object>>();
        reserveInfos.add( new Map<String, Object>() );
        reserveInfos.add( new Map<String, Object>() );
        reserveInfos[0].put('Id', clientOpportunities[0].Id);
        reserveInfos[0].put('Is_Reserve_Applied__c', false);
        reserveInfos[1].put('Id', clientOpportunities[1].Id);
        reserveInfos[1].put('Is_Reserve_Applied__c', false);
        Test.startTest();
        List<Opportunity> opps = ReserveHelper.applyReserveOpps(reserveInfos);
        System.assertEquals(2, opps.size());
        Opportunity opp0 = opps[0].Id == clientOpportunities[0].Id ? opps[0] : opps[1];
        Opportunity opp1 = opps[0].Id == clientOpportunities[1].Id ? opps[0] : opps[1];
        System.assertEquals(false, opp0.Is_Reserve_Applied__c);
        System.assertEquals(null, opp0.Reserve_Amount__c);
        System.assertEquals(null, opp0.Reserve_Date__c);
        System.assertEquals(false, opp1.Is_Reserve_Applied__c);
        System.assertEquals(null, opp1.Reserve_Amount__c);
        System.assertEquals(null, opp1.Reserve_Date__c);        
        Test.stopTest();
    }
    private static User insertUser(){
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'ELFI - Case Management'].Id,
            LastName = 'last',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
			IsActive = true,            
			Reserve__c = true
        );
        insert testUser;
        
        return testUser;
    }
    public static testMethod void testCreateTaskUponPayment(){
        User testUser = insertUser();        
        Test.startTest();        	
        Account account = [select Id, Is_Reserve_Applied__c from Account where Name='Test Client Account'];
        Opportunity clientOpportunity = [SELECT Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c FROM Opportunity  LIMIT 1];
        clientOpportunity.Is_Reserve_Applied__c = true;
        clientOpportunity.Reserve_Date__c = Date.today();
        update clientOpportunity;
        ReserveHelper.createTaskUponPayment(account.Id);
        Task task = [select Id, Subject from Task where OwnerId=:testUser.Id];
        system.assertEquals('Payment received on account marked "Reserve"', task.Subject);
        Test.stopTest();
    }

    public static testMethod void testCreateTaskUponPaymentWithoutReserve(){
        User testUser = insertUser();        
        Test.startTest();        	
        Account account = [select Id, Is_Reserve_Applied__c from Account where Name='Test Client Account'];
        ReserveHelper.createTaskUponPayment(account.Id);
        List<Task> tasks = [select Id, Subject from Task where OwnerId=:testUser.Id];
        system.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }
    
    public static testMethod void testNotifyUponPayment(){
        User testUser = insertUser();        
        Test.startTest();        	
        Account account = [select Id, Is_Reserve_Applied__c from Account where Name='Test Client Account'];
        Opportunity clientOpportunity = [SELECT Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c FROM Opportunity  LIMIT 1];
        clientOpportunity.Is_Reserve_Applied__c = true;
        clientOpportunity.Reserve_Date__c = Date.today();
        update clientOpportunity;
        ReserveHelper.notifyUponPayment(account.Id);
        Test.stopTest();
    }
    
    public static testMethod void testGetEMailRecipients(){
        User testUser = insertUser();        
        Test.startTest();        	
        List<String> recipients = ReserveHelper.getEMailRecipients();                
        Test.stopTest();
    }
    
    public static testMethod void testGetReserveEMailSubject(){
        Opportunity oldOpp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = false);
        Opportunity opp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true);
        System.assertEquals( 'Reserve Enabled on John Smith account', ReserveHelper.getReserveEMailSubject(false, oldOpp, opp));
    }

    public static testMethod void testGetReserveEMailSubject1(){
        Opportunity oldOpp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true);
        Opportunity opp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = false);
        System.assertEquals( 'Reserve Disabled on John Smith account', ReserveHelper.getReserveEMailSubject(false, oldOpp, opp));
    }
    
    public static testMethod void testGetReserveEMailSubject2(){
        Opportunity oldOpp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Date__c = Date.today());
        Opportunity opp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Date__c = Date.today().addDays(1));
        System.assertEquals( 'Reserve Details Updated on John Smith account', ReserveHelper.getReserveEMailSubject(false, oldOpp, opp));
    }

    public static testMethod void testGetReserveEMailMessage(){
        Opportunity oldOpp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = false, Reserve_Date__c = Date.newInstance(2019, 12, 27));
        Opportunity opp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Date__c = Date.newInstance(2019, 12, 28));
        System.assertEquals( 'Reserve date of Dec 28, 2019 was set for this account.', ReserveHelper.getReserveEMailMessage(false, oldOpp, opp));
    }
    
    public static testMethod void testGetReserveEMailMessage1(){
        Opportunity oldOpp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Date__c = Date.newInstance(2019, 12, 27));
        Opportunity opp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Date__c = Date.newInstance(2019, 12, 28));
        System.assertEquals( 'Reserve date of Dec 28, 2019 was set for this account.', ReserveHelper.getReserveEMailMessage(false, oldOpp, opp));
    }
    

    public static testMethod void testGetReserveEMailMessage2(){
        Opportunity oldOpp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Amount__c = 500.0);
        Opportunity opp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Amount__c = 1000.0);
        System.assertEquals( 'Reserve of 1,000.00$ was added to account John Smith', ReserveHelper.getReserveEMailMessage(false, oldOpp, opp));
    }

    public static testMethod void testGetReserveEMailMessage3(){
        Opportunity oldOpp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Date__c = Date.newInstance(2019, 12, 27), Reserve_Amount__c = 500.0);
        Opportunity opp = new Opportunity(Name = 'John Smith', Is_Reserve_Applied__c = true, Reserve_Date__c = Date.newInstance(2019, 12, 28), Reserve_Amount__c = 1000.0);
        System.assertEquals( 'Multiple fields updated', ReserveHelper.getReserveEMailMessage(false, oldOpp, opp));
    }

    
}