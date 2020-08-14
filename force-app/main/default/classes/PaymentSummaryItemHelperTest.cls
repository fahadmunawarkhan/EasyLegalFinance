@isTest
public class PaymentSummaryItemHelperTest {    
    @TestSetup
    static void initailizeTestData(){        
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId()));
        accountList.add( new Account(Name = 'Test LawFirm Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId()));
        
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
    }
    
    public static void insertDrawdowns(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 1; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50)));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    public static testMethod void testFillRealPaymentSummaryItem(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        PaymentSummaryItemHelper.fillRealPaymentSummaryItem(paymentSummaryItem, 100.0, 50.0, 40.0, true);
        System.assertEquals('Partial Payment', paymentSummaryItem.referenceNotes);
        System.assertEquals(50.0, paymentSummaryItem.principal);
        System.assertEquals(40.0, paymentSummaryItem.interest);
    }
    public static testMethod void testFillRealPaymentSummaryItem1(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        PaymentSummaryItemHelper.fillRealPaymentSummaryItem(paymentSummaryItem, 0.0, 50.0, 40.0, true);
        System.assertEquals('Loan Payout', paymentSummaryItem.referenceNotes);
        System.assertEquals(50.0, paymentSummaryItem.principal);
        System.assertEquals(40.0, paymentSummaryItem.interest);
    }    
    public static testMethod void testFillSurplusPaymentSummaryItem(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        PaymentSummaryItemHelper.fillSurplusPaymentSummaryItem(paymentSummaryItem, -100.0);
        System.assertEquals('Payment Surplus', paymentSummaryItem.referenceNotes);
        System.assertEquals(100.0, paymentSummaryItem.surplus);        
    } 
    public static testMethod void testFillShortfallPaymentSummaryItem(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        PaymentSummaryItemHelper.fillShortfallPaymentSummaryItem(paymentSummaryItem, -100.0, 0.0, 0.0);
        System.assertEquals('Payment Surplus', paymentSummaryItem.referenceNotes);
        System.assertEquals(100.0, paymentSummaryItem.surplus);        
    }
    public static testMethod void testFillShortfallPaymentSummaryItem1(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        PaymentSummaryItemHelper.fillShortfallPaymentSummaryItem(paymentSummaryItem, 200.0, 100.0, 100.0);
        System.assertEquals('Payment Shortfall', paymentSummaryItem.referenceNotes);
        System.assertEquals(100.0, paymentSummaryItem.shortfallPrincipal);        
        System.assertEquals(100.0, paymentSummaryItem.shortfallInterest);        
    }
    public static testMethod void testFillBadDebtPaymentSummaryItem(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        PaymentSummaryItemHelper.fillBadDebtPaymentSummaryItem(paymentSummaryItem, -100.0, 50.0, 40.0);
        System.assertEquals('Payment Surplus', paymentSummaryItem.referenceNotes);
        System.assertEquals(100.0, paymentSummaryItem.surplus);        
    }    
    public static testMethod void testFillBadDebtPaymentSummaryItem1(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        PaymentSummaryItemHelper.fillBadDebtPaymentSummaryItem(paymentSummaryItem, 90.0, 50.0, 40.0);
        System.assertEquals('Bad Debt', paymentSummaryItem.referenceNotes);
        System.assertEquals(50.0, paymentSummaryItem.badDebtPrincipal);        
        System.assertEquals(40.0, paymentSummaryItem.badDebtInterest);        
    }
    public static testMethod void testFillBadDebtRecoveryPaymentSummaryItem(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        PaymentSummaryItemHelper.fillBadDebtRecoveryPaymentSummaryItem(paymentSummaryItem, 100.0, 50.0);
        System.assertEquals('Bad Debt Recovery', paymentSummaryItem.referenceNotes);
        System.assertEquals(50.0, paymentSummaryItem.badDebtRecovery);       
    }
    public static testMethod void testFillOtherPaymentSummaryItem(){
        PaymentSummaryItem paymentSummaryItem = new PaymentSummaryItem();
        Drawdown__c d = new Drawdown__c(Payment_Method__c = 'Payment', Reference_Notes__c = 'Client Rebate', Amount__c = 100.0, Date__c = Date.today(), Principal_Repaid__c = 60.0, Interest_Repaid__c = 40.0);
        PaymentSummaryItemHelper.fillOtherPaymentSummaryItem(paymentSummaryItem, d);
        System.assertEquals('Client Rebate', paymentSummaryItem.referenceNotes);
    }
    public static testMethod void testGetPaymentSummaryItemWithReserve(){
        Opportunity opp = new Opportunity(Name = 'OppName');
        Drawdown__c drawdown = new Drawdown__c(Date__c = Date.today(), Payment_Method__c = 'Payment', Reference_Notes__c = 'Partial Payment');
        PaymentSummaryItem paymentSummaryItem = PaymentSummaryItemHelper.getPaymentSummaryItemWithReserve(drawdown, opp, 50.0, 50.0, 100.0, 0.0, 50.0, 50.0, true);
        System.assertEquals('Partial Payment', paymentSummaryItem.referenceNotes);
    }
    public static testMethod void testGetPaymentSummaryItemWithReserve1(){
        Opportunity opp = new Opportunity(Name = 'OppName');
        Drawdown__c drawdown = new Drawdown__c(Date__c = Date.today(), Payment_Method__c = 'Payment', Reference_Notes__c = 'Bad Debt');
        PaymentSummaryItem paymentSummaryItem = PaymentSummaryItemHelper.getPaymentSummaryItemWithReserve(drawdown, opp, 50.0, 50.0, 100.0, 0.0, 50.0, 50.0, true);
        System.assertEquals('Bad Debt', paymentSummaryItem.referenceNotes);
    }    
    public static testMethod void testGetPaymentSummaryItemWithReserve2(){
        Opportunity opp = new Opportunity(Name = 'OppName');
        Drawdown__c drawdown = new Drawdown__c(Date__c = Date.today(), Payment_Method__c = 'Payment', Reference_Notes__c = 'Payment Shortfall');
        PaymentSummaryItem paymentSummaryItem = PaymentSummaryItemHelper.getPaymentSummaryItemWithReserve(drawdown, opp, 50.0, 50.0, 100.0, 0.0, 50.0, 50.0, true);
        System.assertEquals('Payment Shortfall', paymentSummaryItem.referenceNotes);
    }  
    public static testMethod void testGetPaymentSummaryItemWithReserve3(){
        Opportunity opp = new Opportunity(Name = 'OppName');
        Drawdown__c drawdown = new Drawdown__c(Date__c = Date.today(), Payment_Method__c = 'Payment', Reference_Notes__c = 'Payment Surplus');
        PaymentSummaryItem paymentSummaryItem = PaymentSummaryItemHelper.getPaymentSummaryItemWithReserve(drawdown, opp, 50.0, 50.0, 100.0, 0.0, 50.0, 50.0, true);
        System.assertEquals('Payment Surplus', paymentSummaryItem.referenceNotes);
    }
    public static testMethod void testGetPaymentSummaryItemWithReserve4(){
        Opportunity opp = new Opportunity(Name = 'OppName');
        Drawdown__c drawdown = new Drawdown__c(Date__c = Date.today(), Payment_Method__c = 'Payment', Reference_Notes__c = 'Bad Debt Recovery');
        PaymentSummaryItem paymentSummaryItem = PaymentSummaryItemHelper.getPaymentSummaryItemWithReserve(drawdown, opp, 50.0, 50.0, 100.0, 0.0, 50.0, 50.0, true);
        System.assertEquals('Bad Debt Recovery', paymentSummaryItem.referenceNotes);
    } 
    public static testMethod void testGetPaymentSummaryItemWithReserve5(){
        Opportunity opp = new Opportunity(Name = 'OppName');
        Drawdown__c drawdown = new Drawdown__c(Date__c = Date.today(), Payment_Method__c = 'Payment', Reference_Notes__c = 'Payment Rejected');
        PaymentSummaryItem paymentSummaryItem = PaymentSummaryItemHelper.getPaymentSummaryItemWithReserve(drawdown, opp, 50.0, 50.0, 100.0, 0.0, 50.0, 50.0, true);
        System.assertEquals('Payment Rejected', paymentSummaryItem.referenceNotes);
    } 
    public static testMethod void testGetPaymentSummaryItemsWithReserve(){
        List<Opportunity> opps = new List<Opportunity>();
        opps.add(new Opportunity(Name = 'OppName', Is_Reserve_Applied__c = false));
        List<Drawdown__c> drawdowns = new List<Drawdown__c>();
        drawdowns.add(new Drawdown__c(Date__c = Date.today(), Payment_Method__c = 'Payment', Reference_Notes__c = 'Partial Payment', Principal_Repaid__c = 60.0, Interest_Repaid__c = 40.0));
        drawdowns.add(new Drawdown__c(Date__c = Date.today(), Payment_Method__c = 'Payment', Reference_Notes__c = 'Loan Payout', Principal_Repaid__c = 70.0, Interest_Repaid__c = 30.0));
        List<PaymentSummaryItem> items = PaymentSummaryItemHelper.getPaymentSummaryItemsWithReserve(opps, drawdowns);
        System.assertEquals(2, items.size());
        System.assertEquals(60.0, items[0].principal);
        System.assertEquals(40.0, items[0].interest);
        System.assertEquals(70.0, items[1].principal);
        System.assertEquals(30.0, items[1].interest);
    }     
    
    public static testMethod void testGetPaymentSummaryItems() {       
        List<Opportunity> clientOpportunities = [SELECT AccountId, Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c FROM Opportunity  LIMIT 1];
        insertDrawdowns(clientOpportunities[0].Id);
        List<Map<String, Object>> reserveInfos = new List<Map<String, Object>>();
        reserveInfos.add( new Map<String, Object>() );
        reserveInfos[0].put('Id', clientOpportunities[0].Id);
        reserveInfos[0].put('Is_Reserve_Applied__c', true);                
        reserveInfos[0].put('Reserve_Date__c', Date.today().addDays(10));
        List<Opportunity> opps = ReserveHelper.applyReserveOpps(reserveInfos);
        Drawdown__c drawdown = new Drawdown__c(Opportunity__c = clientOpportunities[0].Id, Date__c = Date.today().addDays(300), Payment_Method__c = 'Payment', Reference_Notes__c = 'Partial Payment', Amount__c = 10000.0);
        insert drawdown;
        Test.startTest();                
        List<PaymentSummaryItem> items = PaymentSummaryItemHelper.getPaymentSummaryItems(clientOpportunities[0].AccountId);
        System.assertEquals(1, items.size());
        System.assertEquals(2000.0, items[0].principal);
        System.assertEquals(247.40, items[0].interest);
        Test.stopTest();    
    }
    public static testMethod void testGetPaymentSummaryItems1() {       
        List<Opportunity> clientOpportunities = [SELECT AccountId, Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c FROM Opportunity  LIMIT 1];
        insertDrawdowns(clientOpportunities[0].Id);
        List<Map<String, Object>> reserveInfos = new List<Map<String, Object>>();
        reserveInfos.add( new Map<String, Object>() );
        reserveInfos[0].put('Id', clientOpportunities[0].Id);
        reserveInfos[0].put('Is_Reserve_Applied__c', true);        
        reserveInfos[0].put('Stop_Interest__c', true);        
        reserveInfos[0].put('Reserve_Date__c', Date.today().addDays(10));
        List<Opportunity> opps = ReserveHelper.applyReserveOpps(reserveInfos);
        Drawdown__c drawdown = new Drawdown__c(Opportunity__c = clientOpportunities[0].Id, Date__c = Date.today().addDays(300), Payment_Method__c = 'Payment', Reference_Notes__c = 'Partial Payment', Amount__c = 10000.0);
        insert drawdown;
        Test.startTest();                
        List<PaymentSummaryItem> items = PaymentSummaryItemHelper.getPaymentSummaryItems(clientOpportunities[0].AccountId);
        System.assertEquals(1, items.size());
        System.assertEquals(2000.0, items[0].principal);
        System.assertEquals(9.04, items[0].interest);
        Test.stopTest();
    }    
    public static testMethod void testGetPaymentSummaryItems2() {       
        List<Opportunity> clientOpportunities = [SELECT AccountId, Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c FROM Opportunity  LIMIT 1];
        insertDrawdowns(clientOpportunities[0].Id);
        List<Map<String, Object>> reserveInfos = new List<Map<String, Object>>();
        reserveInfos.add( new Map<String, Object>() );
        reserveInfos[0].put('Id', clientOpportunities[0].Id);
        reserveInfos[0].put('Is_Reserve_Applied__c', true);        
        reserveInfos[0].put('Stop_Interest__c', true);        
        reserveInfos[0].put('Reserve_Date__c', Date.today().addDays(10));
        List<Opportunity> opps = ReserveHelper.applyReserveOpps(reserveInfos);        
        Drawdown__c drawdown = new Drawdown__c(Opportunity__c = clientOpportunities[0].Id, Date__c = Date.today().addDays(300), Payment_Method__c = 'Payment', Reference_Notes__c = 'Bad Debt', Amount__c = 2247.4);
        insert drawdown;
        Test.startTest();                
        List<PaymentSummaryItem> items = PaymentSummaryItemHelper.getPaymentSummaryItems(clientOpportunities[0].AccountId);
        System.assertEquals(1, items.size());
        System.assertEquals(2000.0, items[0].badDebtPrincipal);
        System.assertEquals(9.04, items[0].badDebtInterest);
        Test.stopTest();
    }
    
    public static testMethod void testGetLastPaymentSummaryItems() {          
        List<Opportunity> clientOpportunities = [SELECT AccountId, Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c FROM Opportunity  LIMIT 1];
        insertDrawdowns(clientOpportunities[0].Id);
        List<Map<String, Object>> reserveInfos = new List<Map<String, Object>>();
        reserveInfos.add( new Map<String, Object>() );
        reserveInfos[0].put('Id', clientOpportunities[0].Id);
        reserveInfos[0].put('Is_Reserve_Applied__c', true);        
        reserveInfos[0].put('Stop_Interest__c', true);        
        reserveInfos[0].put('Reserve_Date__c', Date.today().addDays(10));
        List<Opportunity> opps = ReserveHelper.applyReserveOpps(reserveInfos);        
        Drawdown__c drawdown = new Drawdown__c(Opportunity__c = clientOpportunities[0].Id, Date__c = Date.today().addDays(300), Payment_Method__c = 'Payment', Reference_Notes__c = 'Bad Debt', Amount__c = 2247.4);
        insert drawdown;
        Test.startTest();                
        List<Id> paymentIds = new List<Id>{drawdown.Id};        
        List<PaymentSummaryItem> items = PaymentSummaryItemHelper.getLastPaymentSummaryItems(clientOpportunities[0].AccountId, paymentIds);
        System.assertEquals(1, items.size());
        System.assertEquals(2000.0, items[0].badDebtPrincipal);
        System.assertEquals(9.04, items[0].badDebtInterest);
        Test.stopTest();
    }

}