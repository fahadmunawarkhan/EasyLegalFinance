/**
 * @File Name          : LawyerSummaryGeneratePayoutBalance.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 01/07/2020, 5:18:12 pm
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    01/07/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
global class LawyerSummaryGeneratePayoutBalance implements Database.Batchable<sObject> {
    
    Public String query;
    Public String loanFilter;
    Public String businessUnitFilter;
    Public List<String> typeOfLoan;
    public Date payoutDate;
    public Set<Id> selectedIds;
    
    public LawyerSummaryGeneratePayoutBalance(Set<Id> ids, Date pDate, String lFilter, String bUnitFilter, List<String> typOfLoan){
        query = 'SELECT Id, Payout_Date__c';
        query += ' FROM Opportunity WHERE StageName != \'Closed No Loan\' ';
        
        selectedIds = !ids.isEmpty()? ids : new Set<Id>();
        payoutDate = pDate != null? pDate : Date.today();
		loanFilter = String.isEmpty(lFilter) ? 'All' : lFilter;        
        businessUnitFilter = String.isEmpty(bUnitFilter) ? 'ELFI' :bUnitFilter;
        typeOfLoan = typOfLoan;
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        query += ' AND Account.Exclude_from_Payout__c = false';
        query += ' AND Account.Business_Unit__c =:businessUnitFilter';
        query += loanFilter == 'Active'? ' AND isClosed = true AND isWon = true AND Stage_Status__c NOT IN (\'Closed - Paid\', \'Closed - Surplus\', \'Closed - Shortfall\', \'Closed - BadDebt\')' : '';
        query += typeOfLoan.isEmpty()? '' : ' AND Type_of_Loan__c IN:typeOfLoan';
        query += !selectedIds.isEmpty()? ' AND Lawyer__c IN :selectedIds' : '';        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        for(Opportunity opp : scope){
            opp.Payout_Date__c = payoutDate;
        }
        
        update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    
}