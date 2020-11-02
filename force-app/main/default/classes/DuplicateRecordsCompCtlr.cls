/**
 * @description       : 
 * @author            : fahad.khan@toptal.com
 * @group             : 
 * @last modified on  : 10-27-2020
 * @last modified by  : fahad.khan@toptal.com
 * Modifications Log 
 * Ver   Date         Author                  Modification
 * 1.0   10-27-2020   fahad.khan@toptal.com   Initial Version
**/
public with sharing class DuplicateRecordsCompCtlr {
    @AuraEnabled
    public static List<Contact> getPotentialDuplicatesForAccount(String accountId){

        List<Account> PotentialDuplicates = new List<Account>();
        List<Contact> contactList = new List<Contact>();

        Set<String> mailingCities = new Set<String>();
        Set<String> mailingStates = new Set<String>();
        Set<String> mailingPostalCodes = new Set<String>();
        
        Contact conObj = [SELECT AccountId, Account.Formula_Name__c, Account.ProvinceResidency__c,
                          Id, Name, Name_Formula__c, MailingCity, MailingState, MailingPostalCode
                          FROM Contact
                          WHERE AccountId =:accountId 
                          ORDER BY CreatedDate DESC
                          LIMIT 1];

        String strQuery = 'SELECT Id, AccountId, Account.AccountNumber, Account.Name, Account.Business_Unit__c, Account.All_Payout_Balance__c,';
        strQuery += ' Name, Name_Formula__c, MailingCity, MailingState, MailingPostalCode,';
        strQuery += ' (Select Id, Lawyer__c, Law_Firm__c, Lawyer__r.Name, Law_Firm__r.Name from Opportunities1__r WHERE RecordTypeDev__c != \'Loan_Re_Assessment_Opportunity\''; 
        strQuery += ' ORDER BY Loan_Requests__c DESC LIMIT 1)';
        strQuery += ' FROM Contact WHERE (Account.Formula_Name__c LIKE \'%' + conObj.Account.Formula_Name__c + '%\'';
        strQuery += ' OR Name_Formula__c LIKE \'%' + conObj.Name + '%\')';
        strQuery += ' AND AccountId != \'' + accountId + '\'';
        strQuery += conObj.Account.ProvinceResidency__c != null? (' AND Account.ProvinceResidency__c = \'' + conObj.Account.ProvinceResidency__c + '\'') : '';
        strQuery += conObj.MailingCity != null? (' AND MailingCity = \'' + conObj.MailingCity +'\'') : '';
        strQuery += conObj.MailingState != null? (' AND MailingState = \'' + conObj.MailingState +'\'') : '';
        strQuery += conObj.MailingPostalCode != null? (' AND MailingPostalCode = \'' + conObj.MailingPostalCode +'\'') : '';
        strQuery += ' AND RecordType.Name LIKE \'%Client%\'';

        contactList = Database.query(strQuery);

        return contactList;

    }
}