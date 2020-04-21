@isTest(SeeAllData=true)
public class PpsaExpiryReportComponentCtrlTest {
    @isTest static void mentod1(){
        Test.startTest();
            Account TestAcc = new Account();
            TestAcc.Name = 'Test Account';
            TestAcc.Business_Unit__c = 'ELFI';
            Insert TestAcc;
            
            Contact TestCon = new Contact();
            TestCon.FirstName = 'Test';
            TestCon.LastName = 'Contact';
            Insert TestCon;
            
            Opportunity TestOpp = new Opportunity();
            TestOpp.Date_Financing_Statement_Expires__c = Date.valueOf('2023-01-06');
            TestOpp.Primary_Contact__c = TestCon.Id;
            TestOpp.AccountId = TestAcc.Id;
            TestOpp.Type_of_Loan__c = 'Facility Loan';
            TestOpp.Loan_Requests__c = '1st Loan';
            TestOpp.Registration_Number__c = '757098306';
        	TestOpp.Name = 'Test Opportunity';
        	TestOpp.StageName = 'Closed No Loan';
        	TestOpp.CloseDate = Date.valueOf('2019-08-01');
            Insert TestOpp;
        
        	String startdate = '2019-08-01';
            String enddate = '2023-08-01';
            String field = 'Loan_No__c';
            String direction = 'DESC';
            String BusinessUnit = 'Consolidated';
            String searchByName = '';
            String typeOfLoan = 'Consolidated';
        
        	PpsaExpiryReportComponentCtrl.getPPSExpiryLoans(startDate, endDate, field, direction, BusinessUnit, searchByName, typeOfLoan);
        	PpsaExpiryReportComponentCtrl.getCustomSetting();
        	PpsaExpiryReportComponentCtrl.getPickListValues('Opportunity', 'Type_of_Loan__c');
        	PpsaExpiryReportComponentCtrl.saveCustomSettings(startdate, enddate, BusinessUnit, typeOfLoan, searchByName);
        	PpsaExpiryReportComponentCtrl.getSummarizeData(startDate, endDate, BusinessUnit, typeOfLoan);
        Test.stopTest();
    }
}