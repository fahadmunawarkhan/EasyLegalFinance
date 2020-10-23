@isTest
public class VRFeesClearGeneratingSchedulableTest {
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
        Opp.Amount = 2000.0;
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '4 months';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 27.6;
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Interest_Deferral_Period__c = '0';
        Opp.Payout_Date__c = Date.newInstance(2020, 1, 1);
        insert Opp;        
        insertDrawdowns(Opp.Id);        
    }
    public static void insertDrawdowns(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();        
        drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.newInstance(2019, 1, 1), Opportunity__c = OppId,
                                            Amount__c = 2000, Payment_Method__c='e-Transfer', Reference_Notes__c='Payment to Client'));        
		drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.newInstance(2019, 3, 3), Opportunity__c = OppId,
                                            Amount__c = 2000, Payment_Method__c='e-Transfer', Reference_Notes__c='Payment to Client'));        
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    
	public static testMethod void testSchedule() {
        Opportunity opp = [select Id, VR_Fees_Generating_In_Progress__c, VR_Fees_Generating_Start_Time__c from Opportunity LIMIT 1];        
        opp.VR_Fees_Generating_Start_Time__c = DateTime.now().addHours(-1);
        opp.VR_Fees_Generating_In_Progress__c = true;
        update opp;
		Test.startTest();
        VRFeesClearGeneratingSchedulable vfsSchedulable = new VRFeesClearGeneratingSchedulable();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test', sch, vfsSchedulable); 
        Test.stopTest();
        opp = [select Id, VR_Fees_Generating_In_Progress__c, VR_Fees_Generating_Start_Time__c from Opportunity LIMIT 1];        
        System.assertEquals(false, opp.VR_Fees_Generating_In_Progress__c);
    }
}