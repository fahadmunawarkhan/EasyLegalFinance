@isTest
public class AccountTriggerHandlerTest {    
    public static testmethod void testPropagateFileNo(){
        Account acc = new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId());
        insert acc;
        Id accountId = acc.Id;
        Contact contact = new Contact(LastName = 'Test Client Contact', AccountId = accountId,
                                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId());
        insert contact;
        acc = [select AccountNumber from Account where Id = :accountId];
        acc.AccountNumber = 'Test2';
        update acc;
        contact = [select Elf_File_No__c from Contact where AccountId=:accountId];
        System.assertEquals('Test2', contact.ELF_File_No__c);
	}
}