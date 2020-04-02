/**
 * @File Name          : LawFirmSalesSummaryViewAllCtlr.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 02/04/2020, 4:40:51 pm
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    02/04/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public class LawFirmSalesSummaryViewAllCtlr {

    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public String businessUnit{get;set;}
    public String searchByName{get;set;}
    public String typeOfLoan{get;set;}
    public String contentType{get;set;}
    public String renderAs{get;set;}

    public LawFirmSalesSummaryViewAllCtlr() {
        Date dt = Date.today();
        

        String paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');
        String paramContentType = ApexPages.currentPage().getParameters().get('ContentType');
        
        String paramSearchByName = ApexPages.currentPage().getParameters().get('SearchByName');
        String paramTypeOfLoan = ApexPages.currentPage().getParameters().get('TypeOfLoan');

        if(paramContentType == 'PDF'){
            this.renderAs = 'PDF';
        }else{
            this.contentType = 'application/x-excel#LawFirmSalesSummaryViewAll.xls';
        }



        this.businessUnit = !String.isEmpty(paramBusinessUnit) ? paramBusinessUnit : 'ELFI';
        this.startDate = !String.isEmpty(paramStartDate)? Date.valueOf(paramStartDate) : dt.addDays(-30);
        this.endDate = !String.isEmpty(paramEndDate)? Date.valueOf(paramEndDate) : dt;
        this.searchByName = !String.isEmpty(paramSearchByName) ? paramSearchByName : '';
        this.typeOfLoan = !String.isEmpty(paramTypeOfLoan) ? paramTypeOfLoan : '';
        //Date startDt = Date.valueOf(startDate);
        //Date endDt = Date.valueOf(endDate);
    }


    public List<Drawdown__c> getAllDrawdowns(){
        
        List<Drawdown__c> drawdowns = new List<Drawdown__c>();
        
        string filterByBusinessUnit = '';
        string Rhino = 'Rhino';
        string Elfi = 'ELFI';
        
        // Business Unit Filter
        
        if(businessUnit == 'ELFI'){
            
            filterByBusinessUnit = 'ELFI';
        }else if(businessUnit == 'Rhino'){
            
            filterByBusinessUnit = 'Rhino';
        }else if(businessUnit == 'Consolidated'){
            
            filterByBusinessUnit = 'Consolidated';
        }
        
        String strQuery = '';
        String payment = 'Payment';
        String loanPayout = 'Loan Payout';
        String partialPayment = 'Partial Payment';
        String paymentShortfall = 'Payment Shortfall';
        String paymentSurplus = 'Payment Surplus';
        string eTransfer = 'e-Transfer';
        string Cheque = 'Cheque';
        string AdminFee = 'Admin Fee';
        String ClosedWithLoan = 'Closed With Loan';
        String closedPaid = 'Closed - Paid';
        String closedShortfall = 'Closed - Shortfall';
        String closedSurplus = 'Closed - Surplus';
        String badDebt = 'Bad Debt';
        String clientRebate = 'Client Rebate';
        
        Set<Id> lawfirmIdsSet = new Set<Id>();

        /*=============
        
        =============*/
        strQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        strQuery += ' Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__r.Name,'; 
        strQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        strQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c, ';
        strQuery += ' Amount__c';
        strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate'; 
        strQuery += ' AND Date__c <= :endDate'; 
        strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
        strQuery += ' OR (Payment_Method__c =:Cheque)';
        strQuery += ' OR (Payment_Method__c =:AdminFee))';
        strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
        strQuery += ' AND Is_Rejected__c = false';
        strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        strQuery += ' AND Opportunity__r.Lawyer__c != \'\'';
        strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
        strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Opportunity__r.Lawyer__r.Name LIKE \'%' + searchByName + '%\')'  : '';

        List<Drawdown__c> activeDrawdowns = Database.query(strQuery);
        
        for(Drawdown__c dd : activeDrawdowns){
            lawfirmIdsSet.add(dd.Opportunity__r.Law_firm__c);
        }
        system.debug('====>Closed With Loan');
        system.debug(lawfirmIdsSet);
        drawdowns.addAll(activeDrawdowns);

        drawdowns.sort();
        return drawdowns;
    }

}