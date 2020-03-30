public class LawyerSalesSummaryViewAllCtlr {
    
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public String businessUnit{get;set;}
    public String searchByName{get;set;}
    public String typeOfLoan{get;set;}
    public String contentType{get;set;}
    public String renderAs{get;set;}
    
    public LawyerSalesSummaryViewAllCtlr(){
        
        contentType = '';
        renderAs = '';
        Date dt = Date.today();
        
        Date startDt = Date.valueOf(startDate);
        Date endDt = Date.valueOf(endDate);
        
        String paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');
        String paramContentType = ApexPages.currentPage().getParameters().get('ContentType');
        
        String paramSearchByName = ApexPages.currentPage().getParameters().get('SearchByName');
        String paramTypeOfLoan = ApexPages.currentPage().getParameters().get('TypeOfLoan');
        
        if(paramContentType == 'PDF'){
            renderAs = 'PDF';
        }else{
            contentType = 'application/x-excel#LawyerSalesSummaryViewAll.xls';
        }
        
        this.businessUnit = !String.isEmpty(paramBusinessUnit) ? paramBusinessUnit : 'ELFI';
        this.startDate = !String.isEmpty(paramStartDate)? Date.valueOf(paramStartDate) : dt.addDays(-30);
        this.endDate = !String.isEmpty(paramEndDate)? Date.valueOf(paramEndDate) : dt;
        this.searchByName = !String.isEmpty(paramSearchByName) ? paramSearchByName : '';
        this.typeOfLoan = !String.isEmpty(paramTypeOfLoan) ? paramTypeOfLoan : '';
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
        
        Set<Id> lawyerIdsSet = new Set<Id>();
        
        strQuery = 'Select Id, Name, Date__c, Payment_Method__c, Reference_Notes__c, '; 
        strQuery += ' Opportunity__r.Type_of_Loan__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name,'; 
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
            lawyerIdsSet.add(dd.Opportunity__r.Lawyer__c);
        }
        
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
        closedOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
        closedOppQuery += ' AND Is_Rejected__c = false';
        closedOppQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        
        List<Drawdown__c> payouts = DataBase.query(closedOppQuery);        
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
        //badDebtOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
        //badDebtOppQuery += ' AND Payment_Method__c =:payment';  
        badDebtOppQuery += ' AND Reference_Notes__c =:badDebt';                 
        badDebtOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
        badDebtOppQuery += ' AND Is_Rejected__c = false';
        badDebtOppQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        
        List<Drawdown__c> badDebts = DataBase.query(badDebtOppQuery);        
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
        shortFallOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
        shortFallOppQuery += ' AND Is_Rejected__c = false';
        shortFallOppQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        
        List<Drawdown__c> shortFalls = DataBase.query(shortFallOppQuery);        
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
        overageOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
        overageOppQuery += ' AND Is_Rejected__c = false';
        overageOppQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        
        List<Drawdown__c> overages = DataBase.query(overageOppQuery);        
        drawdowns.addAll(overages);
        
        
        drawdowns.sort();
        return drawdowns;
    }
    
    public list<LawyerSalesSummaryComponentCtrl.Wrapper> getGroupbyLawyer(){
        return LawyerSalesSummaryComponentCtrl.getAmountGroupByLawyer(''+this.startDate, ''+this.endDate, 'Opportunity__r.Lawyer__r.name', 'DESC', this.businessUnit, this.searchByName, this.typeOfLoan);
    }
}