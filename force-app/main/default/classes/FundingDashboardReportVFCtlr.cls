/**
 * @File Name          : FundingDashboardReportVFCtlr.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 27/03/2020, 10:58:46 am
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    27/03/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class FundingDashboardReportVFCtlr {
    public String startDate{get;set;}
    public String endDate{get;set;}
    public String businessUnit{get;set;}
    public String TypeOfLoan {get;set;}

    public FundingDashboardReportVFCtlr() {
        Date dt = Date.today();
        String paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');
        String paramtypeOfLoan = ApexPages.currentPage().getParameters().get('typeOfLoan');

        this.businessUnit = !String.isEmpty(paramBusinessUnit) ? paramBusinessUnit : 'ELFI';
        this.startDate = !String.isEmpty(paramStartDate)? paramStartDate : (dt.addDays(-30) + '');
        this.endDate = !String.isEmpty(paramEndDate)? paramEndDate : (dt + '');
        this.TypeOfLoan = !String.isEmpty(paramtypeOfLoan) ? paramtypeOfLoan : '';

    }

    public List<FundingDashboardCtrl.LoanProgressionData> getData(){
        return FundingDashboardCtrl.getData(this.startDate, this.endDate, this.businessUnit, this.TypeOfLoan);
    }
}