@isTest
public class VariableRateCtlrTest {
	@TestSetup
    static void initailizeTestData(){        
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', Business_Unit__c = 'Rhino',
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
    
    public static void insertVariableRates(Id oppId){
        Variable_Rate__c vr = new Variable_Rate__c();
        vr.Month_Start__c = 1;
        vr.Month_End__c = 12;
        vr.Opportunity__c = oppId;
        vr.Rate__c = 35.4;
		Variable_Rate__c vr1 = new Variable_Rate__c();
        vr1.Month_Start__c = 13;        
        vr1.Opportunity__c = oppId;
        vr1.Rate__c = 19.8;        
        List<Variable_Rate__c> vrs = new List<Variable_Rate__c>{vr, vr1};
        insert vrs;
    }
    
    public static void insertVariableFees(Id oppId){
        Variable_Fee__c vf = new Variable_Fee__c();
        vf.Fee_Type__c = '%';
        vf.Effective_At__c = 'Loan Setup';
        vf.Rate__c = 10.0;
        vf.Opportunity__c = oppId;
        vf.Is_BOM__c = false;        
        Variable_Fee__c vfBOM = new Variable_Fee__c();
        vfBOM.Fee_Type__c = '%';
        vfBOM.Effective_At__c = 'One Time';
        vfBOM.Month__c = 12;
        vfBOM.Rate__c = 4.0;
        vfBOM.Opportunity__c = oppId;
        vfBOM.Is_BOM__c = true;
        List<Variable_Fee__c> vfs = new List<Variable_Fee__c>{vf, vfBOM};
        insert vfs;

    }
    @isTest
    public static void testGetVariableRateInfoFromProfile(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];
        List<VariableRateCtlr.VariableRateInfo> variableRateInfos = VariableRateCtlr.getVariableRateInfo(opp.Id, opp.AccountId);
        System.assertEquals(false, variableRateInfos.isEmpty());
    }
    @isTest
    public static void testGetVariableRateInfo(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];
        insertVariableRates(opp.Id);
        List<VariableRateCtlr.VariableRateInfo> variableRateInfos = VariableRateCtlr.getVariableRateInfo(opp.Id, opp.AccountId);        
        System.assertEquals(false, variableRateInfos.isEmpty());
    }    
	@isTest
    public static void testGetVariableFeeInfo(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];
        insertVariableFees(opp.Id);
        List<VariableRateCtlr.VariableFeeInfo> variableFeeInfos = VariableRateCtlr.getVariableFeeInfo(opp.Id, opp.AccountId, false);
        System.assertEquals(1, variableFeeInfos.size());
    }
	@isTest
    public static void testGetVariableFeeInfoBOM(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];
        insertVariableFees(opp.Id);
        List<VariableRateCtlr.VariableFeeInfo> variableFeeInfos = VariableRateCtlr.getVariableFeeInfo(opp.Id, opp.AccountId, true);
        System.assertEquals(1, variableFeeInfos.size());
    }
	@isTest
    public static void testGetVariableFeeInfoFromProfile(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];        
        List<VariableRateCtlr.VariableFeeInfo> variableFeeInfos = VariableRateCtlr.getVariableFeeInfo(opp.Id, opp.AccountId, false);
        System.assertEquals(false, variableFeeInfos.isEmpty());
    }      
	@isTest
    public static void testValidateVariableRates(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];        
        VariableRateCtlr.VariableRateInfo vr = new VariableRateCtlr.VariableRateInfo();                   
        vr.rate = 35.4;
		VariableRateCtlr.VariableRateInfo vr1 = new VariableRateCtlr.VariableRateInfo();
        vr1.periodStart = 13;                
        vr1.rate = 19.8;        
        List<VariableRateCtlr.VariableRateInfo> vrs = new List<VariableRateCtlr.VariableRateInfo>{vr, vr1};
        Integer errorsCount = 0;
        try{
            VariableRateCtlr.validateVariableRates(vrs);
        }
        catch(AuraHandledException ex){        	 
            errorsCount += 1;
        }
        System.assertEquals(1, errorsCount);        
    }      
	@isTest
    public static void testValidateVariableRates1(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];        
        VariableRateCtlr.VariableRateInfo vr = new VariableRateCtlr.VariableRateInfo();        
        vr.periodStart = 1;
        vr.periodEnd = 12;                
		VariableRateCtlr.VariableRateInfo vr1 = new VariableRateCtlr.VariableRateInfo();
        vr1.periodStart = 13;                
        vr1.rate = 19.8;        
        List<VariableRateCtlr.VariableRateInfo> vrs = new List<VariableRateCtlr.VariableRateInfo>{vr, vr1};
        Integer errorsCount = 0;
        try{
            VariableRateCtlr.validateVariableRates(vrs);
        }
        catch(AuraHandledException ex){            
            errorsCount += 1;
        }
        System.assertEquals(1, errorsCount);        
    }      
	@isTest
    public static void testValidateVariableRates2(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];        
        VariableRateCtlr.VariableRateInfo vr = new VariableRateCtlr.VariableRateInfo();        
        vr.periodStart = 1;
        vr.periodEnd = 12;                
        vr.rate = 35.4;
		VariableRateCtlr.VariableRateInfo vr1 = new VariableRateCtlr.VariableRateInfo();
        vr1.periodStart = 20;                
        vr1.rate = 19.8;        
        List<VariableRateCtlr.VariableRateInfo> vrs = new List<VariableRateCtlr.VariableRateInfo>{vr, vr1};
        Integer errorsCount = 0;
        try{
            VariableRateCtlr.validateVariableRates(vrs);
        }
        catch(AuraHandledException ex){
            errorsCount += 1;
        }
        System.assertEquals(1, errorsCount);        
    }    
	@isTest
    public static void testSaveVariableRates(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];        
        VariableRateCtlr.VariableRateInfo vr = new VariableRateCtlr.VariableRateInfo();        
        vr.periodStart = 1;
        vr.periodEnd = 12;                
        vr.rate = 35.4;
		VariableRateCtlr.VariableRateInfo vr1 = new VariableRateCtlr.VariableRateInfo();
        vr1.periodStart = 13;                
        vr1.rate = 19.8;        
        List<VariableRateCtlr.VariableRateInfo> vrInfos = new List<VariableRateCtlr.VariableRateInfo>{vr, vr1};
        VariableRateCtlr.saveVariableRates(opp.Id, vrInfos);
        List<Variable_Rate__c> vrs = [select Id from Variable_Rate__c];
        System.assertEquals(2, vrs.size());
    } 
    
	@isTest
    public static void testSaveVariableFees(){
        Opportunity opp = [select Id, AccountId from Opportunity LIMIT 1];        
        VariableRateCtlr.VariableFeeInfo vf = new VariableRateCtlr.VariableFeeInfo();
		vf.month = 12;
        vf.effectiveAt = 'Annual';
        vf.feeType = '%';
        vf.rate = 4.0;
        List<VariableRateCtlr.VariableFeeInfo> vfInfos = new List<VariableRateCtlr.VariableFeeInfo>{vf};
        VariableRateCtlr.saveVariableFees(opp.Id, vfInfos, true);
        List<Variable_Fee__c> vfs = [select Id from Variable_Fee__c];
        System.assertEquals(1, vfs.size());
    }     
    
    
    
}