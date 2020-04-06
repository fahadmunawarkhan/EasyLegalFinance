/**
 * @File Name          : LawFirmSalesSummaryViewAllCtlrTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 06/04/2020, 12:29:08 pm
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    06/04/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
@isTest
public class LawFirmSalesSummaryViewAllCtlrTest {
    @isTest static void getAllDrawDownsTest() {
        LawFirmSalesSummaryComponentCtrlTest.initailizeTestData();
        Test.startTest();
            String loan = 'Facility Loan';
            Pagereference pr = Page.LawFirmSalesSummaryViewAllVF;
            Test.setCurrentPage(pr);
            ApexPages.currentPage().getParameters().put('BusinessUnit', 'Consolidated');
            ApexPages.currentPage().getParameters().put('StartDate', string.valueOf(date.today()));
            ApexPages.currentPage().getParameters().put('EndDate', string.valueOf(date.today()));
            ApexPages.currentPage().getParameters().put('ContentType', 'PDF');
            ApexPages.currentPage().getParameters().put('SearchByName', '');
            ApexPages.currentPage().getParameters().put('TypeOfLoan', loan);
            ApexPages.currentPage().getParameters().put('sortField', 'Amount');
            ApexPages.currentPage().getParameters().put('direction', 'DESC');

            LawFirmSalesSummaryViewAllCtlr lfssa = new LawFirmSalesSummaryViewAllCtlr();
            lfssa.getAllDrawdowns();
        Test.stopTest();
    }
}