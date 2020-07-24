public with sharing class AFTFileHeader {
    private String aftFileHeader;
    public String cwbFileNumber = '0001';
    public String aftLogicalRecordCount = '000000001';
    public Date creationDate{get; set;}
    public String destinationDataCenter = '86920';
    private String aftCurrencyCode = 'CAD';
    private AFTFile.CWBFileSetting cwbFileSetting; 
    
    public AFTFileHeader(){
        this.creationDate = Date.today();
    }
    
    public AFTFileHeader(String logicalRecordCount, AFTFile.CWBFileSetting cwbFileSetting){
        this.creationDate = Date.today();
        this.aftLogicalRecordCount = logicalRecordCount;        
        this.cwbFileSetting = cwbFileSetting;
        
        this.cwbFileNumber = String.valueOf(cwbFileSetting.fileNumber);
    }
    
    private void setDestinationDataCenter(){
        if (this.cwbFileSetting.DestinationDataCentre == null || this.cwbFileSetting.DestinationDataCentre.length() != 5) {
            throw new EFTFileException(null, '', 'Invalid Destination Data Centre Code. Please have an admin update your user with a 5 character originator Id from the bank.');
        }
        this.aftFileHeader += this.cwbFileSetting.DestinationDataCentre;
    }
    
    private void setCreationDate(){
        this.aftFileHeader += DateTime.newInstance(this.creationDate,Time.newInstance(0,0,0,0)).format('0YYDDD');
    }
    
    private void setLogicalRecordCount(){
        this.aftFileHeader += EFTHelper.formatString(this.aftLogicalRecordCount, '0', 9, 'left'); //'000000001';
    }
    
    private void setFileCreationNumber(){
        system.debug('this.aftFileNumber ' + this.cwbFileNumber);
        system.debug('aftFileNumber formated ' + EFTHelper.formatString(this.cwbFileNumber, '0', 4, 'left'));
        this.aftFileHeader += EFTHelper.formatString(this.cwbFileNumber, '0', 4, 'left'); //'0001';
    }
    
    private void setOriginatorIdNumber(){
        
        if (this.cwbFileSetting.OriginatorId == null || this.cwbFileSetting.OriginatorId.length() != 10) {
            throw new EFTFileException(null, '', 'User has an invalid AFT Originator Id. Please have an admin update your user with a 10 character originator Id from the bank.');
        }
        this.aftFileHeader += this.cwbFileSetting.OriginatorId;
    }
    
    private void setBlanks(Integer numberOfTimes){
        this.aftFileHeader += ' '.repeat(numberOfTimes);
    }
    
    private void setCurrencyCode(){
        this.aftFileHeader += this.aftCurrencyCode;
    }
    
    public String getFileHeaderAsString(){
        this.aftFileHeader = 'A';
        this.setLogicalRecordCount();        
        this.setOriginatorIdNumber();
        this.setFileCreationNumber();
        this.setCreationDate();
        this.setDestinationDataCenter();
        this.setBlanks(20);
        this.setCurrencyCode();
        this.setBlanks(1406);
        
        if (this.aftFileHeader.length() != 1464) {
            throw new EFTFileException(null, '', 'Invalid Header Generated. Please have a developer look into this: "' + this.aftFileHeader + '"' );
        }
        
        return this.aftFileHeader;
    }
}