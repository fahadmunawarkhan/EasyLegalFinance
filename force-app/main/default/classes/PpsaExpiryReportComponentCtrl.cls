/**
 * @File Name          : PpsaExpiryReportComponentCtrl.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 16/04/2020, 6:13:41 pm
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    16/04/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class PpsaExpiryReportComponentCtrl {
    public PpsaExpiryReportComponentCtrl() {

    }

    @AuraEnabled
    public static List<Opportunity> getPPSExpiryLoans(String startDate, String endDate, String field, String direction, String BusinessUnit, String searchByName, String typeOfLoan){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            

            String query = '';
            BusinessUnit = (BusinessUnit != null && !String.isEmpty(BusinessUnit)) ? BusinessUnit : 'ELFI';
            typeOfLoan = (typeOfLoan != null && !String.isEmpty(typeOfLoan)) ? typeOfLoan : 'Facility Loan';

            query = 'SELECT Id, Date_Financing_Statement_Expires__c, Primary_Contact__r.FirstName, Primary_Contact__r.LastName, Account.Business_Unit__c, Type_of_Loan__c';
            query += ' FROM Opportunity Where (Date_Financing_Statement_Expires__c >= :startDt AND Date_Financing_Statement_Expires__c <= :endDt)';
            query += (BusinessUnit == 'Consolidated')? '' : ' AND Account.Business_Unit__c = :BusinessUnit'; 
            query += ' AND Type_of_Loan__c = : typeOfLoan';

            List<Opportunity> PPSAExpiryList = Database.query(query);

            return PPSAExpiryList;

        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Law_Firm_Sales_Summary_Report__c getCustomSetting(){
        Law_Firm_Sales_Summary_Report__c LFSR = Law_Firm_Sales_Summary_Report__c.getOrgDefaults();
        return LFSR;
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
}
