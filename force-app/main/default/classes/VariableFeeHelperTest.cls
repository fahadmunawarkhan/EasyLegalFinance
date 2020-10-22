@isTest
public class VariableFeeHelperTest {
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
        Variable_Fee__c vf = new Variable_Fee__c();
        vf.Fee_Type__c = '%';
        vf.Effective_At__c = 'Loan Setup';
        vf.Rate__c = 10.0;
        vf.Opportunity__c = Opp.Id;
        vf.Is_BOM__c = false;        
        Variable_Fee__c vfBOM = new Variable_Fee__c();
        vfBOM.Fee_Type__c = '%';
        vfBOM.Effective_At__c = 'One Time';
        vfBOM.Month__c = 12;
        vfBOM.Rate__c = 4.0;
        vfBOM.Opportunity__c = Opp.Id;
        vfBOM.Is_BOM__c = true;
        List<Variable_Fee__c> vfs = new List<Variable_Fee__c>{vf, vfBOM};
        insert vfs;
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
    public static void testGetVariableFees(){
        Opportunity opp = [select Id from Opportunity LIMIT 1];
        List<Variable_Fee__c> vfs = VariableFeeHelper.getVariableFees(opp.Id, false);
        System.assertEquals(1, vfs.size());
        System.assertEquals(false, vfs[0].Is_BOM__c);
    }
    @isTest
    public static void testGetVariableFeesBOM(){
        Opportunity opp = [select Id from Opportunity LIMIT 1];
        List<Variable_Fee__c> vfs = VariableFeeHelper.getVariableFees(opp.Id, true);
        System.assertEquals(1, vfs.size());
        System.assertEquals(true, vfs[0].Is_BOM__c);        
    }    
    @isTest
    public static void testCreateDrawdowns(){
        Opportunity opp = [select Id from Opportunity LIMIT 1];
        List<Variable_Fee__c> vfs = VariableFeeHelper.getVariableFees(opp.Id, false);
        List<Drawdown__c> drawdowns = VariableFeeHelper.createDrawdowns(vfs[0]);
        System.assertEquals(1, drawdowns.size());
        System.assertEquals(200.0, drawdowns[0].Amount__c);
        System.assertEquals(Date.newInstance(2019, 1, 1), drawdowns[0].Date__c);
    }       
    @isTest
    public static void testCreateFeesForOpp(){
        Opportunity opp = [select Id from Opportunity LIMIT 1];        
        VariableFeeHelper.createFeesForOpp(opp.Id);
        List<Drawdown__c> drawdowns = [select Id, Amount__c, Date__c from Drawdown__c where Reference_Notes__c='Admin Fee' order by Date__c];
        System.assertEquals(1, drawdowns.size());
        System.assertEquals(200.0, drawdowns[0].Amount__c);
        System.assertEquals(Date.newInstance(2019, 1, 1), drawdowns[0].Date__c);        
    }           
    
    @isTest
    public static void testCreateBOMFeesForOpp(){
        Opportunity opp = [select Id from Opportunity LIMIT 1];        
        VariableFeeHelper.createBOMFeesForOpp(opp.Id);
        List<Drawdown__c> drawdowns = [select Id, Amount__c, Date__c from Drawdown__c where Reference_Notes__c='Admin Fee - BOM' order by Date__c];
        System.assertEquals(2, drawdowns.size());
        System.assertEquals(105.10, drawdowns[0].Amount__c.setScale(2));
        System.assertEquals(Date.newInstance(2020, 1, 1), drawdowns[0].Date__c);
		System.assertEquals(105.10, drawdowns[1].Amount__c.setScale(2));
        System.assertEquals(Date.newInstance(2020, 3, 2), drawdowns[1].Date__c);        
    }           
    @isTest
    public static void testGenerateVariableFees(){
        Opportunity opp = [select Id from Opportunity LIMIT 1]; 
        Variable_Fee__c vfBOM = new Variable_Fee__c();
        vfBOM.Fee_Type__c = '%';
        vfBOM.Effective_At__c = 'Annual';
        vfBOM.Month__c = 12;
        vfBOM.Rate__c = 4.0;
        vfBOM.Opportunity__c = opp.Id;
        vfBOM.Is_BOM__c = true;
        List<Variable_Fee__c> vfs = VariableFeeHelper.generateVariableFees(vfBOM, Date.newInstance(2015, 3, 3), Date.newInstance(2020, 6, 6));
        System.assertEquals(5, vfs.size());
    }    
    
    @isTest
    public static void testMergeVariableFeesList(){
        Opportunity opp = [select Id from Opportunity LIMIT 1]; 
        Variable_Fee__c vfBOM1 = new Variable_Fee__c();
        vfBOM1.Fee_Type__c = '%';
        vfBOM1.Effective_At__c = 'Annual';
        vfBOM1.Month__c = 12;
        vfBOM1.Rate__c = 4.0;
        vfBOM1.Opportunity__c = opp.Id;
        vfBOM1.Is_BOM__c = true;
        Variable_Fee__c vfBOM2 = new Variable_Fee__c();
        vfBOM2.Fee_Type__c = '%';
        vfBOM2.Effective_At__c = 'Annual';
        vfBOM2.Month__c = 24;
        vfBOM2.Rate__c = 4.0;
        vfBOM2.Opportunity__c = opp.Id;
        vfBOM2.Is_BOM__c = true;
        Variable_Fee__c vfBOM3 = new Variable_Fee__c();
        vfBOM3.Fee_Type__c = '%';
        vfBOM3.Effective_At__c = 'Annual';
        vfBOM3.Month__c = 15;
        vfBOM3.Rate__c = 4.0;
        vfBOM3.Opportunity__c = opp.Id;
        vfBOM3.Is_BOM__c = true;        
        List<Variable_Fee__c> vfs = new List<Variable_Fee__c>{vfBOM1, vfBOM2};
        VariableFeeHelper.mergeVariableFeesList(vfs, new List<Variable_Fee__c>{vfBOM3});
        System.assertEquals(3, vfs.size());
        System.assertEquals(15, vfs[1].Month__c);
    }        
}