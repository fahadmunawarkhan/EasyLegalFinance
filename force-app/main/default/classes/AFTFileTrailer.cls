public with sharing class AFTFileTrailer {
    private String aftFileTrailer;
    private String aftLogicalRecordCount = '000000003';
    public String cwbFileNumber = '0001';
    private Decimal totalAmountCredit;
    private Integer totalCreditTransactions;
    private Decimal totalAmountDebit;
    private Integer totalDebitTransactions;
    private AFTFile.CWBFileSetting cwbFileSetting;
    
    public AFTFileTrailer(String logicalRecordCount, Decimal totalAmountCredit, Integer totalCreditTransactions, Decimal totalAmountDebit, Integer totalDebitTransactions, AFTFile.CWBFileSetting cwbFileSetting){
        this.aftLogicalRecordCount = logicalRecordCount;
        this.totalAmountCredit = totalAmountCredit;
        this.totalCreditTransactions = totalCreditTransactions;
        this.totalAmountDebit = totalAmountDebit;
        this.totalDebitTransactions = totalDebitTransactions;
        this.cwbFileSetting = cwbFileSetting;
        this.cwbFileNumber = String.valueOf(cwbFileSetting.fileNumber);
    }
    
    private void setLogicalRecordCount(){
        this.aftFileTrailer += EFTHelper.formatString(this.aftLogicalRecordCount, '0', 9, 'left');
    }
    private void setOriginationControlData(){
        
        if (this.cwbFileSetting.OriginatorId == null || this.cwbFileSetting.OriginatorId.length() != 10) {
            throw new EFTFileException(null, '', 'User has an invalid AFT Originator Id. Please have an admin update your user with a 10 character originator Id from the bank.');
        }
        this.aftFileTrailer += this.cwbFileSetting.OriginatorId + EFTHelper.formatString(this.cwbFileNumber, '0', 4, 'left');        
    }
    
    private void setTotalCreditAmount(){
        if (this.totalAmountCredit >= 0) {
            String formattedAmount = String.valueOf(this.totalAmountCredit).replace('.','');
            this.aftFileTrailer += EFTHelper.formatString(formattedAmount, '0', 14, 'left');
        } else {
            throw new EFTFileException('', 'Amount__c', 'Amount must be >= 0');
        }
    }
    
    private void setTotalCreditTransactions(){
        this.aftFileTrailer += EFTHelper.formatString(String.valueOf(this.totalCreditTransactions), '0', 8, 'left');
    }
    
    private void setTotalDebitTransactions(){
        this.aftFileTrailer += EFTHelper.formatString(String.valueOf(this.totalDebitTransactions), '0', 8, 'left');
    }
    
    private void setTotalDebitAmount(){
        if (this.totalAmountDebit >= 0) {
            String formattedAmount = String.valueOf(this.totalAmountDebit).replace('.','');
            this.aftFileTrailer += EFTHelper.formatString(formattedAmount, '0', 14, 'left');
        } else {
            throw new EFTFileException('', 'Amount__c', 'Amount must be >= 0');
        }
    }
    
    private void setZeroFiller(Integer numTimes){
        this.aftFileTrailer += '0'.repeat(numTimes);
    }
    private void setFiller(){
        this.aftFileTrailer += ' '.repeat(1352);
    }
    
    public String getFileTrailerAsString(){
        this.aftFileTrailer = 'Z';
        this.setLogicalRecordCount();
        this.setOriginationControlData();
        this.setTotalDebitAmount();
        this.setTotalDebitTransactions();
        this.setTotalCreditAmount();
        this.setTotalCreditTransactions();
        this.setZeroFiller(14);        
        this.setZeroFiller(8);
        this.setZeroFiller(14);
        this.setZeroFiller(8);
        this.setFiller();
        
        if (this.aftFileTrailer.length() != 1464) {
            throw new EFTFileException(null, '', 'Invalid Detail Generated. Please have a developer look into this: "' + this.aftFileTrailer + '"' );
        }
        
        return this.aftFileTrailer;
    }
}