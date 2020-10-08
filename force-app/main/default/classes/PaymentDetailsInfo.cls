public class PaymentDetailsInfo {
 	@AuraEnabled
    public Id id {get;set;}              
    @AuraEnabled
    public decimal amount {get;set;}          
    @AuraEnabled
    public Date paymentDate {get;set;}     
    @AuraEnabled
    public String referenceNotes {get;set;}      
    @AuraEnabled
    public String chequeNumber {get;set;}  
    @AuraEnabled
    public Id paymentId {get;set;}       
    @AuraEnabled
    public Id opportunityId {get;set;}    
    @AuraEnabled
    public decimal fvAtPayoutDate {get;set;}       
    @AuraEnabled
    public String dateString {get{
        return Utils.formatDate(paymentDate, 'dd-MMM-yy');
    }}                  
    @AuraEnabled
    public string opportunityName {get;set;}             
    @AuraEnabled
    public decimal principal {get;set;}         
    @AuraEnabled
    public decimal interest {get;set;}         
    @AuraEnabled
    public decimal surplus {get;set;}             
    @AuraEnabled
    public decimal clientRebate {get;set;}     
    @AuraEnabled
    public string description{get{
    	return 'Payment of $' +  Utils.formatCurrency(amount) + ' on ' + Utils.formatDate(paymentDate, 'MMM dd, yyyy');    
    }}    
    @AuraEnabled
    public string title{get{
    	return opportunityName +' - ' + description;    
    }}     
    @AuraEnabled
    public decimal wireFee {get;set;}              
    @AuraEnabled
    public decimal refund {get;set;}                
    @AuraEnabled
    public decimal shortfall {get;set;}              
    @AuraEnabled
    public decimal badDebt {get;set;}                
    @AuraEnabled
    public decimal badDebtRecovery {get;set;}                    
    
}