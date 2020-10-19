/**
 * @File Name          : FundingDashboardReportVFCtlr.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 08-13-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    27/03/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class FundingDashboardReportVFCtlr {
    public String startDate{get;set;}
    public String endDate{get;set;}
    public List<String> businessUnit{get;set;}
    public List<String> TypeOfLoan {get;set;}

    public FundingDashboardReportVFCtlr() {
        Date dt = Date.today();
        List<String> paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit').split(',');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');
        List<String> paramtypeOfLoan = ApexPages.currentPage().getParameters().get('typeOfLoan').split(',');
        
        this.businessUnit = paramBusinessUnit;
        this.startDate = !String.isEmpty(paramStartDate)? paramStartDate : (dt.addDays(-30) + '');
        this.endDate = !String.isEmpty(paramEndDate)? paramEndDate : (dt + '');
        this.TypeOfLoan = paramtypeOfLoan;
    }

    public List<FundingDashboardCtrl.LoanProgressionData> getData(){
        return FundingDashboardCtrl.getData(this.startDate, this.endDate, this.businessUnit, this.TypeOfLoan);
    }
}