/**
 * @File Name          : ReportingViewComponentCtlr.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 13/04/2020, 4:07:18 pm
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    13/04/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class ReportingViewComponentCtlr {
    
    @AuraEnabled
    public static User getCurrentUserInfo(){
        User currentUser = [SELECT Id,isActive,ProfileId, Lawyer_Summary__c, Law_Firm_Summary__c, Critical_Items_Dates__c,
                            Financial_Summary_Report__c, Payment_Summary_Report__c,Actual_Sales_By_Month_Report__c, 
                            Drawdowns__c, Loan_Overview_Edit__c,Law_Firm_Sales_Summary_Report__c,Lawyer_Sales_Summary__c,
                            Financing_Statement_Details__c, Loan_Set_up__c, Lump_Sum_drawdowns__c, Payments_tab__c,
                            Funding_Summary__c,Funding_Dashboard__c, Bad_Debt_Summary_Report__c, Payout_Details__c, 
                            Funding_Summary_Report__c FROM User Where Id = :UserInfo.getUserId()];
        return currentUser;
    } 
}