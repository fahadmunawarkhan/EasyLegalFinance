@isTest
public class VariableRateHelperTest {
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
        Variable_Rate__c vr = new Variable_Rate__c();
        vr.Month_Start__c = 1;
        vr.Month_End__c = 12;
        vr.Opportunity__c = Opp.Id;
        vr.Rate__c = 35.4;
		Variable_Rate__c vr1 = new Variable_Rate__c();
        vr1.Month_Start__c = 13;        
        vr1.Opportunity__c = Opp.Id;
        vr1.Rate__c = 19.8;        
        List<Variable_Rate__c> vrs = new List<Variable_Rate__c>{vr, vr1};
        insert vrs;
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
    
    @isTest
    public static void testGetVariableRatesByOppIdMap(){
        Opportunity opp = [select Id from Opportunity LIMIT 1];        
        Map<Id, List<Variable_Rate__c>> result = VariableRateHelper.getVariableRatesByOppIdMap(new Set<Id>{opp.Id});
        System.assertEquals(2, result.get(opp.Id).size());
    }
    
    @isTest
    public static void testGetAffectedVariableRatesCount(){
        List<Variable_Rate__c> variableRates = [select Id, Month_Start__c, Month_End__c, Rate__c, Opportunity__c from Variable_Rate__c];
        Integer count = VariableRateHelper.getAffectedVariableRatesCount(variableRates, Date.newInstance(2019, 1, 1), Date.newInstance(2019, 10, 1));
        System.assertEquals(2, count);
    }  
    
	@isTest
    public static void testGetVariableRateDescription(){
        List<Variable_Rate__c> variableRates = [select Id, Month_Start__c, Month_End__c, Rate__c, Opportunity__c from Variable_Rate__c];
        VariableRateHelper.VariableRateDescription vrd = VariableRateHelper.getVariableRateDescription(variableRates, Date.newInstance(2019, 1, 1), Date.newInstance(2019, 10, 1));        
        System.assertEquals('Variable...', vrd.variableRateText);
        System.assertEquals(true, vrd.variableRateHelpText != null);
    }     
}