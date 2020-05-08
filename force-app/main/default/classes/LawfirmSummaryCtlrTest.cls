@isTest 
public class LawfirmSummaryCtlrTest {
    @TestSetup
    static void initailizeTestData(){
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No',business_unit__c = 'Rhino', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId()));
        accountList.add( new Account(Name = 'Test LawFirm Account', Authorization_Clause__c = 'No',business_unit__c = 'ELFI', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId()));
        accountList.add( new Account(Name = 'Firm Account', Account_Type__c = 'Treatment Provider Firm',business_unit__c = 'Rhino',
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
        Opp.CloseDate = Date.today().addDays(-1);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'Active';
        Opp.Payout_Date__c = Date.today();
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 15.0;
        insert Opp;
        
        insertDrawdowns(Opp.Id);
        
        insert new Conga_batch_setting__c(SetupOwnerId=UserInfo.getUserId(), Payout_Date_Law_Firm_Report__c = Date.today(),
                                          Report_Date_Law_Firm_Report__c = Date.today().addDays(5), Email_To_Id_Law_Firm_Summary__c = '',
                                  		  Email_Additional_Notes_Law_Firm_Report__c = '', Query_Selector_Law_Firm_Report__c = '',
                                          Conductor_Id_Law_Firm_Summary_Report__c = '');
    }
    
    public static void insertDrawdowns(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 4; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50), Payment_Method__c ='Cheque', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Payment to Client',Interest_Rate__c = 10));
        }
        if(drawdownList.size() > 0){
            insert (new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 1500, Payment_Method__c ='e-Transfer',
                                            Reference_Notes__c = 'Partial Payment'));
            insert drawdownList;
        }
    }
    
    public static testMethod void mainTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name FROM Account WHERE RecordType.Name = \'Law Firm\' AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null)';
        LawfirmSummaryCtlr.getLawfirmAccounts(strQuery, 'All', 'ELFI', 'Facility Loan');
        LawfirmSummaryCtlr.getLawfirmAccounts(strQuery, 'Active', 'ELFI', 'Facility Loan');
        LawfirmSummaryCtlr.getPickListValues('Account', 'Business_Unit__c');
        
        LawfirmSummaryCtlr.AccountInfo accInfo = new LawfirmSummaryCtlr.AccountInfo();
        accInfo.checked = true;
        
        //throwing exception to cover cath block
        strQuery = 'SELECT Id Name FROM Account WHERE RecordType.Name = \'Law Firm\' AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null)';
        
        try{
            LawfirmSummaryCtlr.getLawfirmAccounts(strQuery, 'All', 'ELFI', 'Facility Loan');
        }catch(Exception e){
            System.debug('success');
        }
        
        Test.stopTest();
    }
    public static testMethod void sendMethodTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name FROM Account WHERE RecordType.Name = \'Law Firm\' AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null)';
        
        Contact cc = [SELECT Id from Contact limit 1];
        List<String> selId = new List<String>{cc.Id};
        LawfirmSummaryCtlr.send(strQuery, selId, Date.today() + '' , Date.today() + '', '', 'Email body', 'All', 'ELFI', 'Facility Loan');
        
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());
        system.assertNotEquals(customSettings.Conductor_Id_Law_Firm_Summary_Report__c, null);
        
        LawfirmSummaryCtlr.send('', selId, Date.today() + '' , Date.today() + '', '', 'Email body', 'All', 'ELFI', 'Facility Loan');
        
        Test.stopTest();
    }
    
    public static testMethod void generateMethodTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name FROM Account WHERE RecordType.Name = \'Law Firm\' AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null)';
        
        Contact cc = [SELECT Id, AccountId from Contact WHERE Name = 'Test Lawyer Contact' limit 1];
        List<String> selId = new List<String>{cc.AccountId};
            
            LawfirmSummaryCtlr.generatePayoutBalance(cc.AccountId, ''+ Date.today(),'All', 'ELFI', 'Facility Loan');
            
        LawfirmSummaryCtlr.generate(strQuery, selId, Date.today() + '' , Date.today() + '', 'All', 'ELFI', 'Facility Loan');
        
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());
        system.assertNotEquals(customSettings.Conductor_Id_Law_Firm_Summary_Report__c, null);
        
        LawfirmSummaryCtlr.generate('', selId, Date.today() + '' , Date.today() + '', 'All', 'ELFI', 'Facility Loan');
        
        Test.stopTest();
    }
}