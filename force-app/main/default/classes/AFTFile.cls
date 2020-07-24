/**
 * @File Name          : AFTFile.cls
 * @Description        : 
 * @Author             : fahad.khan@toptal.com
 * @Group              : 
 * @Last Modified By   : fahad.khan@toptal.com
 * @Last Modified On   : 6/18/2020, 3:02:20 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/18/2020   fahad.khan@toptal.com     Initial Version
**/
public with sharing class AFTFile {
    
    private Id[] spIds;
    private Scheduled_Payment__c[] spList;
    private Map<Id, Bank_Account__c> bankAccountList;
    private Decimal amountCreditTotal = 0;
    private Integer creditTransactionCount = 0;
    private Decimal amountDebitTotal = 0;
    private Integer debitTransactionCount = 0;
    private Date dueDate;
    private String businessUnitFilter = 'ELFI';
    
    public AFTFile(Id[] spIds, String businessUnitFilter) {
        this.dueDate = DateUtil.today();
        this.spIds = spIds;
        this.businessUnitFilter = businessUnitFilter;
    }

    public AFTFile(Id[] spIds, Date dueDate) {
        this.dueDate = dueDate;
        this.spIds = spIds;
    }
    
    public class GroupedPayments {
        public Decimal total {public get; private set;}
        public Scheduled_Payment__c[] spList;
        public String referenceNumber;
        public Bank_Account__c bankAccount;
        
        public GroupedPayments(Bank_Account__c bankAccount) {
            this.total = 0;
            this.spList = new Scheduled_Payment__c[]{};
                this.bankAccount = bankAccount;
            Blob blobKey = crypto.generateAesKey(128);
            String key = EncodingUtil.base64encode(blobKey).remove('/');
            this.referenceNumber = DateUtil.now().format('ddMMyy') + '-' + key.substring(0, 11);
        }
        
        public void addPayment(Scheduled_Payment__c sp) {
            spList.add(sp);
            total += sp.Amount__c;
            sp.Transaction_Reference_Number__c = referenceNumber;
        }
    }
    
    private void fetchData() {
       this.spList = [
            Select
                Id, Name, Amount__c, Status__c, Current_Bank_Account_Id__c, Can_Send_to_Bank__c, AFT_File_Number__c, CWB_Sheet_Number__c, // Scheduled Payment Fields
                Opportunity__r.AccountId // Opportunity Fields
            FROM Scheduled_Payment__c
            WHERE Id in :this.spIds
            ORDER BY Current_Bank_Account_Id__c
        ];

        // Collect Account Ids
        Set<Id> bankAccountIds = new Set<id>();
        for (Scheduled_Payment__c sp : this.spList) {
            bankAccountIds.add(sp.Current_Bank_Account_Id__c);
        }

        // Fetch Accounts with Bank Account and Contact information mapped by Id for ease of use
        this.bankAccountList = new Map<Id, Bank_Account__c>([
            SELECT Id, Name, Bank__c, Transit__c, Account__c, Client__r.Name, Client__r.AccountNumber
            FROM Bank_Account__c
            WHERE Id in :bankAccountIds
            ORDER BY Id
        ]);
    }
    
    private AFT_File__c getAFTFileObj() {
        AFT_File__c aftFileObj = new AFT_File__c();
        insert aftFileObj;
        aftFileObj = [Select Id, Name, File_Number__c From AFT_File__c Where Id = :aftFileObj.Id];
        if (aftFileObj.File_Number__c == '0000') {
            // If File Number is 0000 it is invalid, so we must delete that object and create another so the Auto-number increments
            delete aftFileObj;
            return getAFTFileObj();
        }
        return aftFileObj;
    }
    
    private void UpdateCWBFileSettings(String businessUnit, CWB_File_Setting__c cwbFileCustomSetting, Integer fileNumber){
        
        if(businessUnit == 'ELFI'){
            cwbFileCustomSetting.ELFI_File_Number__c = fileNumber;            
        }else if(businessUnit == 'Rhino'){
            cwbFileCustomSetting.Rhino_File_Number__c = fileNumber;
        }else if(businessUnit == 'Seahold'){
            cwbFileCustomSetting.Seahold_File_Number__c = fileNumber;
        }
        upsert cwbFileCustomSetting;
    }
        
    public String generateFileText() {
        
        // initilize Exception Collection
        EFTFileException[] errorList = new EFTFileException[]{};
            
        String aftFileData = '';
        this.fetchData();
        Integer logicalRecordCount = 1;
        String businessUnit = this.businessUnitFilter != null && !String.isEmpty(this.businessUnitFilter) && this.businessUnitFilter != 'All'? this.businessUnitFilter : 'ELFI';
        
        /****************************************************************
         * 						Validation
         * **************************************************************/
        Set<String> oldFileNumbers = new Set<String>();
        integer oldSpCount = 0;
        Boolean hasNewPayments = false;
        try{
            for(Scheduled_Payment__c sp : this.spList){
                if(sp.CWB_Sheet_Number__c != null && sp.CWB_Sheet_Number__c != ''){
                    oldFileNumbers.add(sp.CWB_Sheet_Number__c);
                    oldSpCount++;
                }else{
                    hasNewPayments = true;
                }
            }
            if(oldFileNumbers.size() > 1){
                throw new EFTFileException(null, '', 'Banking sheet can not include failed payments of two different files.' );
            }
        }catch(EFTFileException e){
            errorList.add(e);
            throw new EFTFileErrorListException(errorList);
        }
        system.debug('oldFileNumbers ' + oldFileNumbers.size());
        system.debug(oldFileNumbers);
        try{
            if(oldFileNumbers.size() == 1){
                List<Scheduled_Payment__c> schedulePayments = [
                    Select Id, AFT_File_Number__c, CWB_Sheet_Number__c
                    FROM Scheduled_Payment__c
                    WHERE (Status__c = 'Pre Send Validation' OR Status__c = 'Approved to Send')
                    AND Send_Cheque__c = false
                    AND CWB_Sheet_Number__c IN : oldFileNumbers
                    AND AFT_File_Number__c != null
                ];
                
                system.debug('schedulePayments ' + schedulePayments.size());
                system.debug(schedulePayments);
                
                system.debug('oldSpCount ' + oldSpCount);
                
                if(schedulePayments.size() != oldSpCount){
                    throw new EFTFileException(null, '', 'Please include all failed Scheduled payments for Banking Sheet # ' + new List<String>(oldFileNumbers)[0] + '.' );
                }
            }
        }
        catch(EFTFileException e){
            errorList.add(e);
            throw new EFTFileErrorListException(errorList);
        }
        /***********************************************************************/
        
        AFT_File__c aftFileObj = getAFTFileObj();        
        CWBFileSetting cwbFileSetting = new CWBFileSetting();
        CWB_File_Setting__c cwbFileCustomSetting = CWB_File_Setting__c.getOrgDefaults();
        
        cwbFileSetting.fileNumber = Integer.valueOf(cwbFileCustomSetting.get(businessUnit + '_File_Number__c'));
        cwbFileSetting.AccountNumberforReturns = String.valueOf(cwbFileCustomSetting.get(businessUnit + '_Account_Number_for_Returns__c'));
        cwbFileSetting.DestinationDataCentre = String.valueOf(cwbFileCustomSetting.get(businessUnit + '_Destination_Data_Centre__c'));
        cwbFileSetting.InstitutionalIDforReturns = String.valueOf(cwbFileCustomSetting.get(businessUnit + '_Institutional_ID_for_Returns__c'));
        cwbFileSetting.OriginatorId = String.valueOf(cwbFileCustomSetting.get(businessUnit + '_Originator_Id__c'));
        cwbFileSetting.OriginatorLongName = String.valueOf(cwbFileCustomSetting.get(businessUnit + '_Originator_Long_Name__c'));
        cwbFileSetting.OriginatorShortName = String.valueOf(cwbFileCustomSetting.get(businessUnit + '_Originator_Short_Name__c'));
        
        /*AFT_File__c aftFileObj = getAFTFileObj();
        AFT_File_Setting__mdt aftFileSetting = [SELECT Account_Number_for_Returns__c, Destination_Data_Centre__c, Institutional_ID_for_Returns__c,
                                                Originator_Id__c, Originator_Long_Name__c, Originator_Short_Name__c, MasterLabel, DeveloperName, File_Number__c
                                                FROM AFT_File_Setting__mdt WHERE DeveloperName = :businessUnit];*/
        if(cwbFileSetting.fileNumber == null || cwbFileSetting.fileNumber == 0){
            cwbFileSetting.fileNumber = 1;
        }else{
            cwbFileSetting.fileNumber++;
        }
        
        if(oldFileNumbers.size() == 1){
            string filenumStr = new List<String>(oldFileNumbers)[0];
        	
            cwbFileSetting.fileNumber = integer.valueof(filenumStr.split('-')[1].trim());
        }/*else{
        	MetaDataUtility.upsertMetadata(System.JSON.serialize(aftFileSetting));
        }*/
        
        String aftFileHeaderStr = '';
        
               
        // Generate file header
        AFTFileHeader aftFileHeader = new AFTFileHeader(String.valueOf(logicalRecordCount), cwbFileSetting);
        try {
            aftFileHeaderStr = aftFileHeader.getFileHeaderAsString() + '\r\n'; // Prepend header             
        } catch (EFTFileException e) {
            errorList.add(e);
            throw new EFTFileErrorListException(errorList);
        }
        
        
            
        Map<Id, GroupedPayments> groupedPayments = new Map<Id, GroupedPayments>();
        
        // Loop over Scheduled Payments and create detail lines        
        Datetime now = DateUtil.now();
        
        for (Scheduled_Payment__c sp : this.spList) {
            // Validate User is able to send current payment (has EFT_Permission or was not the validator)
            if (!sp.Can_Send_to_Bank__c) {
                errorList.add(new EFTFileException(sp.Id, 'Can_Send_to_Bank__c', 'You are not able to send payments that you verified.'));
            }
            
            try {
                if (sp.Current_Bank_Account_Id__c == null || String.isBlank(sp.Current_Bank_Account_Id__c)) {
                    throw new EFTFileException(sp.Id, 'Current_Bank_Account_URL__c', 'Scheduled Payment does not have a Bank Account set');
                }
                if (sp.Amount__c <= 0) {
                    throw new EFTFileException(sp.Id, 'Amount__c', 'Scheduled Payment amount must be greater than $0');
                }
                GroupedPayments gp;
                if (groupedPayments.containsKey(sp.Current_Bank_Account_Id__c)) {
                    gp = groupedPayments.get(sp.Current_Bank_Account_Id__c);
                } else {
                    Id baId = sp.Current_Bank_Account_Id__c;
                    Bank_Account__c ba = this.bankAccountList.get(baId);
                    gp = new GroupedPayments(ba);
                    groupedPayments.put(sp.Current_Bank_Account_Id__c, gp);
                }
                sp.Bank_Account__c = sp.Current_Bank_Account_Id__c;
                gp.addPayment(sp);
            } catch (EFTFileException e) {
                system.debug('exception: ' + e.message);
                // Catch exception and set Scheduled Payment Id
                e.id = sp.Id;
                errorList.add(e);
                //throw e;
            }
            
            sp.Status__c = 'Sent to Bank';
            sp.Sent_to_Bank_Account__c = sp.Current_Bank_Account_Id__c;
            sp.Sent_to_Bank_Date__c = now;
            sp.Sent_to_Bank_By__c = UserInfo.getUserId();
            sp.AFT_File_Number__c = cwbFileSetting.fileNumber;
            sp.CWB_Business_Unit__c = businessUnit;
        }
        
        logicalRecordCount++;
        String aftFileDetailStr = '';
        // Generate Debit Transaction Lines from Grouped Payments
        List<List<GroupedPayments>> listOfGroupedPayments = new List<List<GroupedPayments>>();
        listOfGroupedPayments.add(new List<GroupedPayments>());// 0 index
        Integer transCount = 0, index = 0, count = 0;
        for (GroupedPayments gp : groupedPayments.values()) {
            if(math.mod(count, 6)  == 0 && count != 0){
                index++;
                if(count < groupedPayments.size() + 1)
                	listOfGroupedPayments.add(new List<GroupedPayments>());
            }
            listOfGroupedPayments[index].add(gp); 
            count++;
        }
        
        system.debug('listOfGroupedPayments ' + listOfGroupedPayments.size());
        system.debug(listOfGroupedPayments);
        String detailRow = '';
        AFTFileDetail aftFileD;
        for(List<GroupedPayments> groupedPaymentsList : listOfGroupedPayments){
            transCount = 0;
            detailRow = '';
            for(GroupedPayments gp : groupedPaymentsList){
                try {
                    aftFileD = new AFTFileDetail('C', gp, this.dueDate, String.valueOf(logicalRecordCount), cwbFileSetting);
                    
                    if(transCount == 0){
                        detailRow += aftFileD.getSegmentZero();
                    }
                    detailRow += aftFileD.getSegmentOne();
                    
                    this.amountCreditTotal += gp.total;
                    this.creditTransactionCount += 1;
                    
                }catch (EFTFileException e) {
                    system.debug('exception: ' + e.message);
                    errorList.add(e);
                    //throw e;
                }
                transCount++;
            }
            aftFileDetailStr += AFTFileDetail.setRowFiller(detailRow);
            aftFileDetailStr += '\r\n';
            logicalRecordCount++;
            
        }
        
        String aftFileTrailerStr = '';
        // Generate file footer
        AFTFileTrailer aftFileTrailer = new AFTFileTrailer(String.valueOf(logicalRecordCount), this.amountCreditTotal, this.creditTransactionCount, this.amountDebitTotal, this.debitTransactionCount, cwbFileSetting);
        try {
            aftFileTrailerStr += aftFileTrailer.getFileTrailerAsString() + '\r\n';
        } catch (EFTFileException e) {
            errorList.add(e);
        }
        
        if (errorList.isEmpty() == false) {
            System.debug(errorList);
            throw new EFTFileErrorListException(errorList);
        } else {            
            try {                
                for (Scheduled_Payment__c sp : spList) {
                    sp.AFT_File__c = aftFileObj.Id;
                    sp.EFT_File__c = null;
                }
            } catch (EFTFileException e) {
                errorList.add(e);
                throw new EFTFileErrorListException(errorList);
            }
        }

        // update Scheduled Payments' status
        update spList;
        UpdateCWBFileSettings(businessUnit, cwbFileCustomSetting, cwbFileSetting.fileNumber);
        
        aftFileObj.Total_Credit_Amount__c = this.amountCreditTotal;
        aftFileObj.Total_Debit_Amount__c = this.amountDebitTotal;
        aftFileObj.Credit_Transaction_Count__c = this.creditTransactionCount;
        aftFileObj.Debit_Transaction_Count__c = this.debitTransactionCount;
        update aftFileObj;
        aftFileData = aftFileHeaderStr + aftFileDetailStr + aftFileTrailerStr;
        return aftFileData;
    }
    
    
    public class CWBFileSetting{
        public Integer fileNumber{get; set;}
        public String AccountNumberforReturns{get; set;}
        public String DestinationDataCentre{get; set;}
        public String InstitutionalIDforReturns{get; set;}
        public String OriginatorId{get; set;}
        public String OriginatorLongName{get; set;}
        public String OriginatorShortName{get; set;}
    }
}