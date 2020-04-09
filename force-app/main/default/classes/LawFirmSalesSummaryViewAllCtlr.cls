/**
 * @File Name          : LawFirmSalesSummaryViewAllCtlr.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 08/04/2020, 3:49:55 pm
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
    public String SortField{get;set;}
    public String Direction{get;set;}
    public double TotalAmountPDF {get;set;}

    public Integer NoOfFilestotal {get;set;}
    public Integer NoOfClosedFiles {get;set;}
    public Integer NoOfOpps {get;set;}
    public double PayoutsTotal {get;set;}
    public double AmountTotal {get;set;}
    public Integer NoOfBadDebtFilesTotal {get;set;}
    public double BadDebtAmtTotal {get;set;}
    public Integer NoOfShortFallFilesTotal {get;set;}
    public double ShortFallAmtTotal {get;set;}
    public Integer NoOfOverAgeFilesTotal {get;set;}
    public double OverAgeAmtTotal {get;set;}


    public LawFirmSalesSummaryViewAllCtlr() {
        Date dt = Date.today();
        

        String paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');
        String paramContentType = ApexPages.currentPage().getParameters().get('ContentType');
        
        String paramSearchByName = ApexPages.currentPage().getParameters().get('SearchByName');
        String paramTypeOfLoan = ApexPages.currentPage().getParameters().get('TypeOfLoan');
        String paramSortField = ApexPages.currentPage().getParameters().get('sortField');
        String paramDirection = ApexPages.currentPage().getParameters().get('direction');
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
        this.SortField = !String.isEmpty(paramSortField) ? paramSortField : '';
        this.Direction = !String.isEmpty(paramDirection) ? paramDirection : '';
        this.TotalAmountPDF = 0;
        this.NoOfFilestotal = 0;
        this.NoOfClosedFiles = 0;
        this.NoOfOpps = 0;
        this.PayoutsTotal = 0;
        this.AmountTotal = 0;
        this.NoOfBadDebtFilesTotal = 0;
        this.BadDebtAmtTotal = 0;
        this.NoOfShortFallFilesTotal = 0;
        this.ShortFallAmtTotal = 0;
        this.NoOfOverAgeFilesTotal = 0;
        this.OverAgeAmtTotal = 0;
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
        Main
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
        closedOppQuery += ' Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
        closedOppQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        closedOppQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c, ';
        closedOppQuery += ' Amount__c';        
        closedOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDate';
        closedOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDate';
        closedOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
        closedOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
        closedOppQuery += ' AND Payment_Method__c =:payment';  
        closedOppQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment OR Reference_Notes__c =:clientRebate)'; 
        closedOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedPaid';
        closedOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
        closedOppQuery += ' AND Is_Rejected__c = false';
        closedOppQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        List<Drawdown__c> payouts = DataBase.query(closedOppQuery);
        system.debug('====>Payouts');
        system.debug(payouts);
        drawdowns.addAll(payouts);


        /**
         * Bad Debt
         * */
        
        String badDebtOppQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        badDebtOppQuery += ' Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
        badDebtOppQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        badDebtOppQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c, ';
        badDebtOppQuery += ' Amount__c';
        badDebtOppQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate';
        badDebtOppQuery += ' AND Date__c <= :endDate';
        badDebtOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
        badDebtOppQuery += ' AND Reference_Notes__c =:badDebt';                 
        badDebtOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
        badDebtOppQuery += ' AND Is_Rejected__c = false';
        badDebtOppQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        
        List<Drawdown__c> badDebts = DataBase.query(badDebtOppQuery);
        system.debug('====>Bad Debts');
        system.debug(badDebts);
        drawdowns.addAll(badDebts);

        /**
		* ShortFall
		* */
        String shortFallOppQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        shortFallOppQuery += ' Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
        shortFallOppQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        shortFallOppQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c, ';
        shortFallOppQuery += ' Amount__c';
        shortFallOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDate';
        shortFallOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDate';
        shortFallOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
        shortFallOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
        shortFallOppQuery += ' AND Payment_Method__c =:payment';
        shortFallOppQuery += ' AND Reference_Notes__c =:paymentShortfall';                 
        shortFallOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedShortfall';
        shortFallOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
        shortFallOppQuery += ' AND Is_Rejected__c = false';
        shortFallOppQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        
        List<Drawdown__c> shortFalls = DataBase.query(shortFallOppQuery);
        system.debug('====>ShortFalls');
        system.debug(shortFalls);
        drawdowns.addAll(shortFalls);


        /**
		* Overage
		* */
        
        String overageOppQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        overageOppQuery += ' Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
        overageOppQuery += ' Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c,';
        overageOppQuery += ' Opportunity__r.Account.Name, Opportunity__r.Account.AccountNumber, Opportunity__c, ';
        overageOppQuery += ' Amount__c';
        overageOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDate';
        overageOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDate';
        overageOppQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
        overageOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
        overageOppQuery += ' AND Payment_Method__c =:payment';  
        overageOppQuery += ' AND Reference_Notes__c =:paymentSurplus'; 
        overageOppQuery += ' AND Opportunity__r.Stage_Status__c =:closedSurplus';
        overageOppQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
        overageOppQuery += ' AND Is_Rejected__c = false';
        overageOppQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        
        List<Drawdown__c> overages = DataBase.query(overageOppQuery);
        system.debug('====>overages');
        system.debug(overages);
        drawdowns.addAll(overages);

        for(Drawdown__c draw : drawdowns){
            TotalAmountPDF = TotalAmountPDF + draw.Amount__c;
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
                this.AmountTotal += LawSalesInfo.totalAmount;
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
}