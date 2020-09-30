/**
 * @File Name          : LawFirmSalesSummaryViewAllCtlr.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : fahad.khan@toptal.com
 * @Last Modified On   : 09-21-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    02/04/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public class LawFirmSalesSummaryViewAllCtlr {

    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public List<String> businessUnit{get;set;}
    public string businessUnitString{get;set;}
    public String searchByName{get;set;}
    public List<String> typeOfLoan{get;set;}
    public String contentType{get;set;}
    public String renderAs{get;set;}
    public String SortField{get;set;}
    public String Direction{get;set;}
    public double TotalAmountPDF {get;set;}
    public double totalInterestRepaid {get;set;}

    public Integer NoOfFilestotal {get;set;}
    public Integer NoOfClosedFiles {get;set;}
    public Integer NoOfOpps {get;set;}
    public double PayoutsTotal {get;set;}
    public Integer NoOfBadDebtFilesTotal {get;set;}
    public double BadDebtAmtTotal {get;set;}
    public Integer NoOfShortFallFilesTotal {get;set;}
    public double ShortFallAmtTotal {get;set;}
    public Integer NoOfOverAgeFilesTotal {get;set;}
    public double OverAgeAmtTotal {get;set;}


    public LawFirmSalesSummaryViewAllCtlr() {
        Date dt = Date.today();
        

        List<String> paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit').split(',');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');
        String paramContentType = ApexPages.currentPage().getParameters().get('ContentType');
        
        String paramSearchByName = ApexPages.currentPage().getParameters().get('SearchByName');
        List<String> paramTypeOfLoan = ApexPages.currentPage().getParameters().get('TypeOfLoan').split(',');
        String paramSortField = ApexPages.currentPage().getParameters().get('sortField');
        String paramDirection = ApexPages.currentPage().getParameters().get('direction');
        if(paramContentType == 'PDF'){
            this.renderAs = 'PDF';
        }else{
            this.contentType = 'application/x-excel#LawFirmSalesSummaryViewAll.xls';
        }



        this.businessUnit = paramBusinessUnit;
        this.startDate = !String.isEmpty(paramStartDate)? Date.valueOf(paramStartDate) : dt.addDays(-30);
        this.endDate = !String.isEmpty(paramEndDate)? Date.valueOf(paramEndDate) : dt;
        this.searchByName = !String.isEmpty(paramSearchByName) ? paramSearchByName : '';
        this.typeOfLoan = paramTypeOfLoan;
        this.SortField = !String.isEmpty(paramSortField) ? paramSortField : '';
        this.Direction = !String.isEmpty(paramDirection) ? paramDirection : '';
        this.TotalAmountPDF = 0;
        this.NoOfFilestotal = 0;
        this.NoOfClosedFiles = 0;
        this.NoOfOpps = 0;
        this.PayoutsTotal = 0;
        this.NoOfBadDebtFilesTotal = 0;
        this.BadDebtAmtTotal = 0;
        this.NoOfShortFallFilesTotal = 0;
        this.ShortFallAmtTotal = 0;
        this.NoOfOverAgeFilesTotal = 0;
        this.OverAgeAmtTotal = 0;
        this.totalInterestRepaid = 0.00;
        this.businessUnitString = (this.businessUnit.size() == GetPickListValueSize()) ? 'Consolidated' : string.join(this.businessUnit, ',');
    }


    public List<Drawdown__c> getAllDrawdowns(){
        
        List<Drawdown__c> drawdowns = new List<Drawdown__c>();
        
        string filterByBusinessUnit = '';
        string Rhino = 'Rhino';
        string Elfi = 'ELFI';
        
        // Business Unit Filter
        
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
        String activePartialPayment = 'Active - Partial Payment';
        
        Set<Id> lawfirmIdsSet = new Set<Id>();

        /*=============
        Main
        =============*/
        strQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        strQuery += ' Opportunity__r.Loan_Requests__c, Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__r.Name,'; 
        strQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        strQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c, Interest_Repaid__c, ';
        strQuery += ' Amount__c';
        strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate'; 
        strQuery += ' AND Date__c <= :endDate'; 
        strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
        strQuery += ' OR (Payment_Method__c =:Cheque)';
        strQuery += ' OR (Payment_Method__c =:AdminFee))';
        strQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
        strQuery += ' AND Is_Rejected__c = false';
        strQuery += (businessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
        strQuery += ' AND Opportunity__r.Law_firm__c != \'\'';
        strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
        strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Opportunity__r.Lawyer__r.Name LIKE \'%' + searchByName + '%\')'  : '';

        List<Drawdown__c> activeDrawdowns = Database.query(strQuery);
        
        for(Drawdown__c dd : activeDrawdowns){
            lawfirmIdsSet.add(dd.Opportunity__r.Law_firm__c);
        }
        system.debug('====>Closed With Loan');
        system.debug(lawfirmIdsSet);
        drawdowns.addAll(activeDrawdowns);


        /**
         * PAYOUT
         * */
        
        String closedOppQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        closedOppQuery += ' Opportunity__r.Loan_Requests__c, Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
        closedOppQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        closedOppQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c, Interest_Repaid__c, ';
        closedOppQuery += ' Amount__c';        
        closedOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate';
        closedOppQuery += ' AND Date__c <= :endDate';
        closedOppQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
        closedOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
        closedOppQuery += ' AND Payment_Method__c =:payment';  
        closedOppQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment)'; 
        //closedOppQuery += ' AND (Opportunity__r.Stage_Status__c =:closedPaid OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
        closedOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
        closedOppQuery += ' AND Is_Rejected__c = false';
        closedOppQuery += (businessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
        List<Drawdown__c> payouts = DataBase.query(closedOppQuery);
        system.debug('====>Payouts');
        system.debug(payouts);
        drawdowns.addAll(payouts);


        /**
         * Bad Debt
         * */
        
        String badDebtOppQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        badDebtOppQuery += ' Opportunity__r.Loan_Requests__c, Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
        badDebtOppQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        badDebtOppQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c,Interest_Repaid__c, ';
        badDebtOppQuery += ' Amount__c';
        badDebtOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate';
        badDebtOppQuery += ' AND Date__c <= :endDate';
        badDebtOppQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
        badDebtOppQuery += ' AND Reference_Notes__c =:badDebt';                 
        badDebtOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
        badDebtOppQuery += ' AND Is_Rejected__c = false';
        badDebtOppQuery += (businessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
        
        List<Drawdown__c> badDebts = DataBase.query(badDebtOppQuery);
        system.debug('====>Bad Debts');
        system.debug(badDebts);
        drawdowns.addAll(badDebts);

        /**
		* ShortFall
		* */
        String shortFallOppQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        shortFallOppQuery += ' Opportunity__r.Loan_Requests__c, Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
        shortFallOppQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        shortFallOppQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c,Interest_Repaid__c, ';
        shortFallOppQuery += ' Amount__c';
        shortFallOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate';
        shortFallOppQuery += ' AND Date__c <= :endDate';
        shortFallOppQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
        shortFallOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
        shortFallOppQuery += ' AND Payment_Method__c =:payment';
        shortFallOppQuery += ' AND Reference_Notes__c =:paymentShortfall';                 
        shortFallOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedShortfall';
        shortFallOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
        shortFallOppQuery += ' AND Is_Rejected__c = false';
        shortFallOppQuery += (businessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
        
        List<Drawdown__c> shortFalls = DataBase.query(shortFallOppQuery);
        system.debug('====>ShortFalls');
        system.debug(shortFalls);
        drawdowns.addAll(shortFalls);


        /**
		* Overage
		* */
        
        String overageOppQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        overageOppQuery += ' Opportunity__r.Loan_Requests__c, Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
        overageOppQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        overageOppQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c,Interest_Repaid__c, ';
        overageOppQuery += ' Amount__c';
        overageOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate';
        overageOppQuery += ' AND Date__c <= :endDate';
        overageOppQuery += (typeOfLoan.isEmpty())? '' : ' AND Opportunity__r.Type_of_Loan__c IN :typeOfLoan';
        overageOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
        overageOppQuery += ' AND Payment_Method__c =:payment';  
        overageOppQuery += ' AND Reference_Notes__c =:paymentSurplus'; 
        overageOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedSurplus';
        overageOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
        overageOppQuery += ' AND Is_Rejected__c = false';
        overageOppQuery += (businessUnit.isEmpty()) ? '' : ' AND Opportunity__r.Account.Business_Unit__c IN :businessUnit';
        
        List<Drawdown__c> overages = DataBase.query(overageOppQuery);
        system.debug('====>overages');
        system.debug(overages);
        drawdowns.addAll(overages);

        for(Drawdown__c draw : drawdowns){
            TotalAmountPDF = TotalAmountPDF + draw.Amount__c;
            if(draw.Interest_Repaid__c != null){
                totalInterestRepaid = totalInterestRepaid + draw.Interest_Repaid__c;
            }
        }


        drawdowns.sort();
        return drawdowns;
    }

    public list<LawFirmSalesSummaryComponentCtrl.Wrapper> getGroupbyLawFirm(){
        List<LawFirmSalesSummaryComponentCtrl.Wrapper> LawSalesSummaryList = new List<LawFirmSalesSummaryComponentCtrl.Wrapper>();
        for(LawFirmSalesSummaryComponentCtrl.Wrapper LawSalesInfo : LawFirmSalesSummaryComponentCtrl.getAmountGroupByLawFirm(''+this.startDate, ''+this.endDate, SortField, Direction, this.businessUnit, this.searchByName, this.typeOfLoan)){
            LawSalesSummaryList.add(LawSalesInfo);
            
                this.NoOfFilestotal += LawSalesInfo.totalFileCount;
                this.NoOfClosedFiles += LawSalesInfo.totalClosedFileCount;
                this.NoOfOpps += LawSalesInfo.totalOpptyCount;
                this.PayoutsTotal += LawSalesInfo.totalClosedAmount;
                this.NoOfBadDebtFilesTotal += LawSalesInfo.totalbdfile;
                this.BadDebtAmtTotal += LawSalesInfo.totalbdamount;
                this.NoOfShortFallFilesTotal += LawSalesInfo.totalShortFallFile;
                this.ShortFallAmtTotal += LawSalesInfo.totalShortFallAmt;
                this.NoOfOverAgeFilesTotal += LawSalesInfo.totalOverAgeFile;
                this.OverAgeAmtTotal += LawSalesInfo.totalOverAgeAmt;
            
        }
        system.debug(LawSalesSummaryList);
        return LawSalesSummaryList;
    }
    public Integer GetPickListValueSize(){
        return LawyerSalesSummaryComponentCtrl.getPickListValues('Account','Business_Unit__c').size();
    }
}