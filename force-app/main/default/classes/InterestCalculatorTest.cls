@isTest
public class InterestCalculatorTest {
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
        for(Integer i=0; i < 2; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.newInstance(2019, 1, 1), Opportunity__c = OppId,
                                            Amount__c = 2000));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }

    @isTest
    public static void testGetCompoundInterestMultiplier(){
        Decimal multiplier = InterestCalculator.getCompoundInterestMultiplier(27.6, 12.0, Date.newInstance(2020, 1, 1), Date.newInstance(2021, 1, 1));
        System.assertEquals(1.31471701, multiplier.setScale(8));        
    }
    @isTest
    public static void testGetCompoundInterest(){
        Decimal interest = InterestCalculator.getCompoundInterest(1000.0, 27.6, 12.0, Date.newInstance(2020, 1, 1), Date.newInstance(2021, 1, 1));
        System.assertEquals(1314.71701297, interest.setScale(8));        
    }    
	@isTest
    public static void testGetInterestStartDate(){    
        Opportunity opp = [select Id, Interest_Deferral_Period__c from Opportunity LIMIT 1];
        Drawdown__c d = [select Interest_Start_Date__c, Date__c from Drawdown__c LIMIT 1];
        Date dt = InterestCalculator.getInterestStartDate(d, opp);
        System.assertEquals(d.Interest_Start_Date__c, dt);
    }
	@isTest
    public static void testGetInterestStartDate1(){    
        Opportunity opp = [select Id, Interest_Deferral_Period__c from Opportunity LIMIT 1];
        Drawdown__c d  = new Drawdown__c();
        d.Opportunity__c = opp.Id;
        d.Date__c = Date.newInstance(2020, 1, 1);        
        Date dt = InterestCalculator.getInterestStartDate(d, opp);
        System.assertEquals(d.Date__c, dt);
    } 
	@isTest
    public static void testGetInterestEndDate(){    
        Opportunity opp = [select Id, Minimum_Interest_Period_Number__c from Opportunity LIMIT 1];
        Drawdown__c d  = new Drawdown__c();
        d.Opportunity__c = opp.Id;
        d.Date__c = Date.newInstance(2020, 1, 1);        
        Date dt = InterestCalculator.getInterestEndDate(Date.newInstance(2020, 5, 5), Date.newInstance(2020, 2, 5), d, opp);
        System.assertEquals(Date.newInstance(2020, 6, 4), dt);        
    }    
    @isTest
    public static void testGetVRListForSimpleInterestRateType(){    
        Opportunity opp = [select Id, Interest_Rate__c from Opportunity LIMIT 1];
        List<Variable_Rate__c> vrs =  InterestCalculator.getVRListForSimpleInterestRateType(opp);
    }
	@isTest
    public static void testGetDrawdowns(){    
        Opportunity opp = [select Id, Interest_Rate__c from Opportunity LIMIT 1];
        InterestCalculator.getDrawdowns(new List<Id>{opp.Id});
    }    
	@isTest
    public static void testGetOpps(){    
        Opportunity opp = [select Id, Interest_Rate__c from Opportunity LIMIT 1];
        InterestCalculator.getOpps(new List<Id>{opp.Id});
    }     
	@isTest
    public static void testCalculateVariableRates(){    
        Opportunity opp = [select Id, Interest_Rate__c from Opportunity LIMIT 1];        
        InterestCalculator.calculateVariableRates(opp.Id);
        List<Drawdown__c> drawdowns = [select Outstanding_Balance_VR__c from Drawdown__c];
        System.assertEquals(2629.43, drawdowns[0].Outstanding_Balance_VR__c.setScale(2));        
    }
}