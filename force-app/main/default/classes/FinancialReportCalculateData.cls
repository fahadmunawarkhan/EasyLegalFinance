global class FinancialReportCalculateData implements Database.Batchable<sObject> {
    
    String query;
	public Date fromDate;  // date we are calcuating from
	public Date toDate;    // date we are calculating to
    public Date adhocAsOfDate;    
	public Boolean sinceInception;  // use this to indicate calculation since the drawdown date
    public String typeOfLoan;  // opportunity type of loan
    public Set<Id> oppIds;
    
    global FinancialReportCalculateData(Date fromDt, Date toDt, Boolean inception, String loanType, Date adhocDate){
        
        system.debug('loanType ' + loanType);
        oppIds = new Set<Id>();
        fromDate = (fromDt != null) ? fromDt.addDays(-1) : null;
		toDate = (toDt != null) ? toDt : null;    
		sinceInception = (inception == null) ? false : inception;
        typeOfLoan = !String.isEmpty(loanType) && loanType != null? loanType : '';
        //typeOfLoan = 'Testing';
        
        adhocAsOfDate = (adhocDate != null) ? adhocDate : null;
        
        String strQuery = 'SELECT Id, Opportunity__c FROM Drawdown__c WHERE Date__c >= :fromDate';
        strQuery += ' AND Date__c <= :toDate AND Opportunity__r.StageName = \'Closed With Loan\'';
        strQuery += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
        strQuery += ' AND (Opportunity__r.Stage_Status__c =\'Active\' OR Opportunity__r.Stage_Status__c =\'Active - Collections\' OR Opportunity__r.Stage_Status__c = \'Active - Partial Payment\'';
        strQuery += ' OR Opportunity__r.Stage_Status__c =\'Closed - Paid\' OR Opportunity__r.Stage_Status__c = \'Closed - Shortfall\'';
        strQuery += ' OR Opportunity__r.Stage_Status__c =\'Closed - Surplus\' OR Opportunity__r.Stage_Status__c =\'Closed - Bad Debt\')';
        strQuery += ' AND (Payment_Method__c =\'Cheque\' or Payment_Method__c = \'e-Transfer\')';
        
        
        List<Drawdown__c> drawdowns = Database.query(strQuery);
        
        system.debug('drawdowns ' + drawdowns.size());
        
        for(Drawdown__c dd : drawdowns){
            oppIds.add(dd.Opportunity__c);
        }
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String closedWithLoan = 'Closed With Loan';
        String none = '';
        String partialPayment = 'Active - Partial Payment';
        String active = 'Active';
        String activeCollections = 'Active - Collections';
        String closedSurplus = 'Closed - Surplus';
        String closedShortfall = 'Closed - Shortfall';
        String closedPaid = 'Closed - Paid';
        String closedBadDebt = 'Closed - Bad Debt';
                
        query='SELECT id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c,' +
            'Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c,'+
            'Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c, '+
            'Accrued_Interest_as_of_Temp_Date__c from drawdown__c where Opportunity__r.StageName =:closedWithLoan';
        query += !oppIds.isEmpty()? ' AND Opportunity__c in :oppIds' : ''; 
        query += (String.isEmpty(typeOfLoan) || typeOfLoan == null || typeOfLoan == 'Consolidated')? '' : ' AND Opportunity__r.Type_of_Loan__c =:typeOfLoan';
        query += ' AND (Opportunity__r.Stage_Status__c =:none OR Opportunity__r.Stage_Status__c =:active OR Opportunity__r.Stage_Status__c =:activeCollections OR Opportunity__r.Stage_Status__c =:partialPayment';
        query += ' OR Opportunity__r.Stage_Status__c =:closedPaid OR Opportunity__r.Stage_Status__c =:closedShortfall';
        query += ' OR Opportunity__r.Stage_Status__c =:closedSurplus OR Opportunity__r.Stage_Status__c =:closedBadDebt)';
        query += ' AND Interest_Rate__c > 0 AND Payment_Method__c != \'Payment\' ';
        
        /**
         * Updated the the above query. Added some more filters.
         * Date range filter is added.
         * Opportunity Type of loan filter is added
         * Added Opportunity stage status = Active
         * Modified Opportunity stage status filter from 'Partial Payment' to 'Active - Partial Payment'
         * 
         * Modified Date = March, 20, 2020.
         * */
        
        system.debug(query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        try{
			PortfolioReportCalculateData.calculateDataInStatic(scope, sinceInception,  adhocAsOfDate != null? adhocAsOfDate :fromDate, toDate);
		}
		catch (Exception e){
			
		}
    }
    global void finish(Database.BatchableContext BC){
        
    }
}
