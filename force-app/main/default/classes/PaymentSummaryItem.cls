public class PaymentSummaryItem{
    @AuraEnabled
    public Id id {get;set;}              
    @AuraEnabled
    public decimal amount {get;set;}          
    @AuraEnabled
    public Date paymentDate {get;set;}                  
    @AuraEnabled
    public String paymentDateString {get;set;}                  
    @AuraEnabled
    public string paymentType {get;set;}
    @AuraEnabled
    public string fileNumber {get;set;}    
    @AuraEnabled
    public string opportunityName {get;set;}         
    @AuraEnabled
    public decimal principal {get;set;}         
    @AuraEnabled
    public decimal interest {get;set;}         
    @AuraEnabled
    public decimal surplus {get;set;}            
    @AuraEnabled
    public decimal shortfall {get;set;}            
    @AuraEnabled
    public decimal shortfallPrincipal {get;set;}            
    @AuraEnabled
    public decimal shortfallInterest {get;set;}                
    @AuraEnabled
    public decimal badDebtPrincipal {get;set;}            
    @AuraEnabled
    public decimal badDebtInterest {get;set;}            
    @AuraEnabled
    public decimal reserve {get;set;}            
    @AuraEnabled
    public decimal badDebtRecovery {get;set;}            
    @AuraEnabled
    public string referenceNotes{get;set;}
    @AuraEnabled
    public string description{get{
    	return referenceNotes + ' of $' +  Utils.formatCurrency(amount) + ' on ' + Utils.formatDate(paymentDate, 'MMM dd, yyyy');    
    }}    
    @AuraEnabled
    public decimal wireFee {get;set;}              
    @AuraEnabled
    public decimal refund {get;set;}                
}