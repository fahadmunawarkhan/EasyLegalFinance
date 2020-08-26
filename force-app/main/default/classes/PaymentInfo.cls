public Class PaymentInfo{        
    @AuraEnabled
    public String accountId{get; set;}       
    @AuraEnabled
    public String payoutDate{get; set;}
    @AuraEnabled
    public String searchType{get; set;}
    @AuraEnabled
    public String eft{get; set;}
    @AuraEnabled
    public String chq{get; set;}
    @AuraEnabled
    public String oppId{get; set;}
    @AuraEnabled
    public String action{get; set;}     
    @AuraEnabled
    public String OppBadDebts{get; set;}
    @AuraEnabled
    public Decimal wireFee{get; set;}
}