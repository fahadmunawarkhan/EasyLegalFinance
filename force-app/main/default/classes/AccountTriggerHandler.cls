/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-17-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-17-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class AccountTriggerHandler {
    public static void validateAccountCreation(List<Account> newAccounts){
        for (Account account : newAccounts){
            if (!account.Conversion_Flag__c && account.Account_Type__c == 'Client' && !Test.isRunningTest())
                account.addError('Please start with creating a Lead for adding new clients');
        }
    }
    
    public static void propagateFileNo(Boolean isInsert, Map<Id, Account> oldMap, List<Account> newAccounts){
        Map<Id, Account> selectedAccountsMap = new Map<Id, Account>();
        for (Account account : newAccounts){
            if (isInsert || account.AccountNumber != oldMap.get(account.Id).AccountNumber){
                System.debug('Propagate');
                selectedAccountsMap.put(account.Id, account);
            }
        }
        if (!selectedAccountsMap.isEmpty()){
            List<Contact> contacts = [select ELF_File_No__c, AccountId from Contact where AccountId in :selectedAccountsMap.keySet()];
            if (!contacts.isEmpty()){
                for (Contact contact : contacts){
                    System.debug('Propagate ' + selectedAccountsMap.get(contact.AccountId).AccountNumber);
                    contact.ELF_File_No__c = selectedAccountsMap.get(contact.AccountId).AccountNumber;
                }
                update contacts;
            }
        }
        
    }
    public static void fillFileNo(Boolean isInsert, Map<Id, Account> oldMap, List<Account> newAccounts){
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType Where SobjectType = 'Account'];
        String query = 'select RecordTypeId';
        
    }
}