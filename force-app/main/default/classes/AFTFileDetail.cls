public with sharing class AFTFileDetail {
    
    private String aftFileDetail;
    private Bank_Account__c bankAccount;
    Private String aftlogicalRecordTypeId = 'D';
    private String aftLogicalRecordCount = '000000002';
    public String cwbFileNumber = '0001';
    private String aftTransactionType = '351';//'200';
    private Decimal amount;
    private Date dueDate;
    private AFTFile.CWBFileSetting cwbFileSetting; 
    private String referenceNumber;
    
    public AFTFileDetail(String logicalRecordTypeId, AFTFile.GroupedPayments gp, Date dueDate, String logicalRecordCount, AFTFile.CWBFileSetting cwbFileSetting){
        this.aftlogicalRecordTypeId = logicalRecordTypeId;
        this.aftLogicalRecordCount = logicalRecordCount;        
        this.dueDate = dueDate;
        this.bankAccount = gp.bankAccount;
        this.amount = gp.total;
        this.referenceNumber = gp.referenceNumber; 
        this.cwbFileSetting = cwbFileSetting;        
        this.cwbFileNumber = String.valueOf(cwbFileSetting.fileNumber);
    }
    
    /*public void setTransactionParams(AFTFile.GroupedPayments gp, String logicalRecordCount){
        this.bankAccount = gp.bankAccount;
        this.amount = gp.total;
        this.aftLogicalRecordCount = logicalRecordCount;
        this.referenceNumber = gp.referenceNumber;
    }*/
    
    private String getLogicalRecordType(){
        return this.aftlogicalRecordTypeId;
    }
    
    private String getLogicalRecordCount(){
        return EFTHelper.formatString(this.aftLogicalRecordCount, '0', 9, 'left');
    }
    
    private String getOriginationControlData(){
        
        if (this.cwbFileSetting.OriginatorId == null || this.cwbFileSetting.OriginatorId.length() != 10) {
            throw new EFTFileException(null, '', 'User has an invalid AFT Originator Id. Please have an admin update your user with a 10 character originator Id from the bank.');
        }
        return this.cwbFileSetting.OriginatorId + EFTHelper.formatString(this.cwbFileNumber, '0', 4, 'left');        
    }
    
    private String getTransactionType(){
        return this.aftTransactionType;
    }
    
    private String getAmount(){
        if (amount >= 0) {
            String formattedAmount = String.valueOf(amount).replace('.','');
            return EFTHelper.formatString(formattedAmount, '0', 10, 'left');
        } else {
            throw new EFTFileException('', 'Amount__c', 'Amount must be >= 0');
        }
    }
    private String getDueDate(){
        return DateTime.newInstance(this.dueDate,Time.newInstance(0,0,0,0)).format('0YYDDD');
    }
    
    private String getTransitNumber(){
        
        if (this.bankAccount.Bank__c == null || this.bankAccount.Bank__c.length() != 4) {
            throw new EFTFileException(null, '', 'Invalid Bank #. Please update the payment bank account. Bank # must be 4 digits long.');
        }
        if (this.bankAccount.Transit__c == null || this.bankAccount.Transit__c.length() != 5) {
            throw new EFTFileException(null, '', 'Invalid Bank Account Transit #. Please update the payment bank account. Transit #\'s must be 5 digits long.');
        }
        return this.bankAccount.Bank__c + this.bankAccount.Transit__c;
    }
    private String getAccountNumber(){
        
        return EFTHelper.formatString(String.valueOf(this.bankAccount.Account__c), ' ', 12, 'right');
    }
    
    private String getItemTraceNumber(){
        return '0'.repeat(22);
    }
    
    private String getStoredTransactionType(){
        return '0'.repeat(3);
    }
    
    private String getOriginatorShortName(){
        if (this.cwbFileSetting.OriginatorShortName == null) {
            throw new EFTFileException(null, '', 'Originator Short Name can not be null. Please have an admin update your user with a 10 character originator Id from the bank.');
        }
        return EFTHelper.formatString(this.cwbFileSetting.OriginatorShortName, ' ', 15, 'right');
    }
    
    private String getPayeeName(){
        if (this.bankAccount.Bank_Name__c == null || this.bankAccount.Bank_Name__c == '') {
            throw new EFTFileException(null, '', 'Bank Name can not be null. Please update the Bank Name.');
        }
        return EFTHelper.formatString(this.bankAccount.Bank_Name__c, ' ', 30, 'right');
    }
    
    private String getOriginatorLongName(){
        if (this.cwbFileSetting.OriginatorLongName == null) {
            throw new EFTFileException(null, '', 'Originator Long Name can not be null. Please have an admin update your user with a 10 character originator Id from the bank.');
        }
        return EFTHelper.formatString(this.cwbFileSetting.OriginatorLongName, ' ', 30, 'right');
    }
    
    private String getOriginatorIdNumber(){
        if (this.cwbFileSetting.OriginatorId == null || this.cwbFileSetting.OriginatorId.length() != 10) {
            throw new EFTFileException(null, '', 'User has an invalid AFT Originator Id. Please have an admin update your user with a 10 character originator Id from the bank.');
        }
        return this.cwbFileSetting.OriginatorId;        
    }
    
    private String getOriginatorReferenceNumber(){
        return EFTHelper.formatString(referenceNumber, ' ', 19, 'right');
    }
    
    private String getInstitutionalIDNumberforReturns(){
        if (this.cwbFileSetting.InstitutionalIDforReturns == null || this.cwbFileSetting.InstitutionalIDforReturns.length() != 8) {
            throw new EFTFileException(null, '', 'Invalid Institutional ID Number for Returns. Please have an admin update your aftFileSettings.');
        }
        return EFTHelper.formatString(this.cwbFileSetting.InstitutionalIDforReturns, '0', 9, 'left');
    }
    
    private String getAccountNumberForReturns(){
        if (this.cwbFileSetting.AccountNumberforReturns == null || this.cwbFileSetting.AccountNumberforReturns.length() != 12) {
            throw new EFTFileException(null, '', 'Invalid Account Number for Returns. Please have an admin update your aftFileSettings.');
        }
        return this.cwbFileSetting.AccountNumberForReturns;
    }
    
    private String getOriginatorSundryInformation(){
        
        system.debug('bankAccount ' + bankAccount);
        system.debug('bankAccount.Client__c ' + bankAccount.Client__c);
        system.debug('bankAccount.Client__r.AccountNumber ' + bankAccount.Client__r.AccountNumber);
        
        return EFTHelper.formatString(bankAccount.Client__c == null || bankAccount.Client__r.AccountNumber == null? '0' : bankAccount.Client__r.AccountNumber , ' ', 15, 'right');
    }
    
    private String getFiller(){
        return ' '.repeat(22);
    }
    private String getOriginatorDirectClearerSettlementCode(){
        return ' '.repeat(2);
    }
    
    private String getInvalidDataElementID(){
        return '0'.repeat(11);
    }
    
    public String getSegmentZero(){
        String segmentZero = '';
        segmentZero += this.getLogicalRecordType();
        segmentZero += this.getLogicalRecordCount();
        segmentZero += this.getOriginationControlData();
        system.debug('AFT D segmentZero = ' + segmentZero);
        return segmentZero;
    }
    
    public static String setRowFiller(String row){
        return EFTHelper.formatString(row, ' ', 1464, 'right');
    }
    
    public String getSegmentOne(){
        String segmentOne = '';
        segmentOne += this.getTransactionType();
        segmentOne += this.getAmount();        
        segmentOne += this.getDueDate();
        segmentOne += this.getTransitNumber();
        segmentOne += this.getAccountNumber();
        segmentOne += this.getItemTraceNumber();
        segmentOne += this.getStoredTransactionType();
        segmentOne += this.getOriginatorShortName();
        segmentOne += this.getPayeeName();
        segmentOne += this.getOriginatorLongName();
        segmentOne += this.getOriginatorIdNumber();
        segmentOne += this.getOriginatorReferenceNumber();
        segmentOne += this.getInstitutionalIDNumberforReturns();
        segmentOne += this.getAccountNumberForReturns();
        segmentOne += this.getOriginatorSundryInformation();
        segmentOne += this.getFiller();
        segmentOne += this.getOriginatorDirectClearerSettlementCode();
        segmentOne += this.getInvalidDataElementID();
        
        system.debug('AFT D segmentOne = ' + segmentOne);
        return segmentOne;
    }
    
    public String getFileDetailAsString(){
        this.aftFileDetail = '';
        String segmentZero = this.getSegmentZero();
                
        String segmentOne = this.getSegmentOne();
        this.aftFileDetail = segmentZero + segmentOne.repeat(6);
        
        system.debug('aftFileDetail Size = ' + this.aftFileDetail.length());
        /*if (this.aftFileDetail.length() != 1464) {
            throw new EFTFileException(null, '', 'Invalid Detail Generated. Please have a developer look into this: "' + this.aftFileDetail + '"' );
        }*/
        return this.aftFileDetail;
    }    
}