public class ChequePaymentInfo {
 	@AuraEnabled
    public Id id {get;set;}              
    @AuraEnabled
    public decimal chequeAmount {get;set;}          
    @AuraEnabled
    public Date chequeDate {get;set;}                  
    @AuraEnabled
    public String chequeNumber {get;set;}                  
    @AuraEnabled
    public decimal fvAtPayoutDate {get;set;}       
    @AuraEnabled
    public String chequeDateString {get{
        return Utils.formatDate(chequeDate, 'dd-MMM-yy');
    }}                  
    @AuraEnabled
    public string chequeType {get;set;}
    @AuraEnabled
    public string opportunityName {get;set;}             
    @AuraEnabled
    public decimal principal {get;set;}         
    @AuraEnabled
    public decimal interest {get;set;}         
    @AuraEnabled
    public decimal surplus {get;set;}             
    @AuraEnabled
    public string description{get{
    	return 'Payment of $' +  Utils.formatCurrency(chequeAmount) + ' on ' + Utils.formatDate(chequeDate, 'MMM dd, yyyy');    
    }}    
    @AuraEnabled
    public string title{get{
    	return opportunityName +' - ' + description;    
    }}     
}