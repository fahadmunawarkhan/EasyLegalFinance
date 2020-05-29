public class LawfirmSummaryGeneratePayoutBalance implements Database.Batchable<sObject> {
    
    Public String query;
    Public String loanFilter;
    Public String businessUnitFilter;
    Public String typeOfLoan;
    public Date payoutDate;
    public Set<Id> selectedIds;
    
    public LawfirmSummaryGeneratePayoutBalance(Set<Id> ids, Date pDate, String lFilter, String bUnitFilter, String typOfLoan){
        query = 'SELECT Id, Payout_Date__c';
        query += ' FROM Opportunity WHERE StageName != \'Closed No Loan\' ';
        
        selectedIds = !ids.isEmpty()? ids : new Set<Id>();
        payoutDate = pDate != null? pDate : Date.today();
		loanFilter = String.isEmpty(lFilter) ? 'All' : lFilter;        
        businessUnitFilter = String.isEmpty(bUnitFilter) ? 'ELFI' :bUnitFilter;
        typeOfLoan = typOfLoan;
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        query += ' AND Account.Business_Unit__c =:businessUnitFilter';
        query += loanFilter == 'Active'? ' AND isClosed = true AND isWon = true AND Stage_Status__c NOT IN (\'Closed - Paid\', \'Closed - Surplus\', \'Closed - Shortfall\', \'Closed - BadDebt\')' : '';
        query += (typeOfLoan == null || String.isEmpty(typeOfLoan) || typeOfLoan == 'Consolidated')? '' : ' AND Type_of_Loan__c =:typeOfLoan';
        query += !selectedIds.isEmpty()? ' AND Law_Firm__c IN :selectedIds' : '';        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> scope){
        for(Opportunity opp : scope){
            opp.Payout_Date__c = payoutDate;
        }
        
        update scope;
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}