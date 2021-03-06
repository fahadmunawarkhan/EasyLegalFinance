/**
* @File Name          : PpsaExpiryReportComponentCtrlTest.cls
* @Description        : 
* @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
* @Group              : 
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 29/04/2020, 3:01:46 pm
* @Modification Log   : 
* Ver       Date            Author      		    Modification
* 1.0    22/04/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
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
        TestOpp.StageName = 'Closed With Loan';
        TestOpp.CloseDate = Date.valueOf('2019-08-01');
        Insert TestOpp;
        
        String startdate = '2019-08-01';
        String enddate = '2023-08-01';
        String field = 'Loan_No__c';
        String direction = 'DESC';
        String BusinessUnit = 'ELFI';
        String searchByName = '';
        String typeOfLoan = 'Facility Loan';
        String expiryDateFilter = '';
        String statusFilter = '';
        PpsaExpiryReportComponentCtrl.getPPSExpiryLoans(startDate, endDate, field, direction, new List<String>{BusinessUnit}, searchByName, new List<String>{typeOfLoan}, expiryDateFilter, statusFilter);
        PpsaExpiryReportComponentCtrl.getCustomSetting();
        PpsaExpiryReportComponentCtrl.getPickListValues('Opportunity', 'Type_of_Loan__c');
        PpsaExpiryReportComponentCtrl.saveCustomSettings(startdate, enddate, new List<String>{BusinessUnit}, new List<String>{typeOfLoan}, searchByName);
        PpsaExpiryReportComponentCtrl.getSummarizeData(startDate, endDate, new List<String>{BusinessUnit}, new List<String>{typeOfLoan});
        PpsaExpiryReportComponentCtrl.orgInstanceCheck();
        Test.stopTest();
    }
}