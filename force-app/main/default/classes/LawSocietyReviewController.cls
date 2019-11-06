/**
* @description Class used to fetch the lawyer details
**/
public with sharing class LawSocietyReviewController {
    
    /**
    * @description Method to fetch lawyer details
    **/
    @AuraEnabled
    public static Map<String,Object> getLawyersList(String startDate, String endDate, String businessUnit, String searchByName, String field, String direction, String upcomingHearings, String currentProceedings, String orders, String dateReviewed, String nextReviewDate){
       
        Map<String, Object> objectsMap = new Map<String, Object>();
        Set<Id> lawyerIds = new Set<Id>();
        Map<Id, Contact> contactsMap = new Map<Id, Contact>();
        List<Lawyer> lawyersList = new List<Lawyer>();
        
        Date sDate = Date.valueOf(startDate);
        Date eDate = Date.valueOf(endDate);
        String soqlQuery = 'SELECT Opportunity__r.Lawyer__c lawyerId, COUNT_DISTINCT(Opportunity__r.AccountId) file, SUM(Amount__c) amount FROM Drawdown__c WHERE Date__c >= :sDate AND Date__c <= :eDate';
       	soqlQuery += !String.isEmpty(searchByName) && searchByName != null? ' AND (Opportunity__r.Lawyer__r.Name LIKE \'%' + String.escapeSingleQuotes(searchByName) + '%\' OR Opportunity__r.Lawyer__r.Account.Name LIKE \'%' + String.escapeSingleQuotes(searchByName) + '%\')' : '';
        soqlQuery += businessUnit == 'Consolidated' ? ' AND (Opportunity__r.Account.Business_Unit__c = \'ELFI\' OR Opportunity__r.Account.Business_Unit__c = \'Rhino\')' : ' AND Opportunity__r.Account.Business_Unit__c = \''+businessUnit+'\'';
        soqlQuery += ' AND Opportunity__r.StageName = \'Closed With Loan\' AND (Payment_Method__c = \'e-Transfer\' OR Payment_Method__c = \'Cheque\' OR Payment_Method__c = \'Admin Fee\') GROUP BY Opportunity__r.Lawyer__c';
        soqlQuery += ' ORDER BY ' + field + ' ' + direction + ' NULLS LAST';
        
        List<AggregateResult> aggrQueryResult = Database.query(soqlQuery);
        for(AggregateResult aggregateResult : aggrQueryResult){
            if(aggregateResult.get('lawyerId') != null){
                lawyerIds.add((Id)aggregateResult.get('lawyerId'));
            }
        }
        
        If(!lawyerIds.isEmpty()){
            Date dtReviewed = !String.isEmpty(dateReviewed) && dateReviewed != null? Date.valueOf(dateReviewed) : null;
            Date nxtReviewDate = !String.isEmpty(nextReviewDate) && nextReviewDate != null? Date.valueOf(nextReviewDate) : null;
            
            String soqlContact = 'SELECT Id, Name, AccountId, Account.Name, Upcoming_Hearings__c, Current_Proceedings__c,';
            soqlContact += 'Orders__c, Date_Reviewed__c, Next_Review_Date__c';
            soqlContact += ' FROM Contact';
            soqlContact += ' WHERE RecordType.DeveloperName = \'Lawyers\'';
            soqlContact += !String.isEmpty(upcomingHearings)? ' AND Upcoming_Hearings__c =:upcomingHearings' : '';
            soqlContact += !String.isEmpty(currentProceedings)? ' AND Current_Proceedings__c =:currentProceedings' : '';
            soqlContact += !String.isEmpty(orders)? ' AND Orders__c =:orders' : '';
            soqlContact += dtReviewed != null? ' AND Date_Reviewed__c =:dtReviewed' : '';
            soqlContact += nxtReviewDate != null? ' AND Next_Review_Date__c =:nxtReviewDate' : '';
            soqlContact += ' AND Id in:lawyerIds';
            
            contactsMap = new Map<Id, Contact>(
                (List<Contact>)Database.query(soqlContact)
            );
        }
        
        if(!aggrQueryResult.isEmpty()){
            for(AggregateResult aggregateResult : aggrQueryResult){
                if(aggregateResult.get('lawyerId') != null && contactsMap.containsKey((Id)aggregateResult.get('lawyerId'))){
                    lawyersList.add(
                        new Lawyer(
                            contactsMap.get((Id)aggregateResult.get('lawyerId')),
                            Integer.valueof(aggregateResult.get('file')), 
                            Double.valueof(aggregateResult.get('amount'))                            
                        )
                    );
                }
            }
        }
        
        objectsMap.put('lawyers',lawyersList);
        objectsMap.put('isCurrentUserSeeLawSocietyReviewReport',[SELECT Id, Law_Society_Review__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1].Law_Society_Review__c);
        return objectsMap;
    }
    
    /**
    * @description Method to fetch lawyer details
    **/
    @AuraEnabled
    public static void saveContacts(String contactsListJSON){
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Lawyer> lawyersList = (List<Lawyer>)JSON.deserialize(contactsListJSON,List<Lawyer>.class);
        for(Lawyer lawyer : lawyersList){
            contactsToUpdate.add(lawyer.contact);
        }
        
        update contactsToUpdate;
    }
    
    /**
    * @description Method to save new note
    **/
    @AuraEnabled
    public static void saveNewNote(String contentNote, String contactId){
        contentNote = contentNote.escapeJava().escapeHtml3().escapeHtml4();
        try{
            if(!String.isBlank(contentNote)){
                ContentNote contentNoteRecord = new ContentNote(Title='N/A',Content=Blob.valueOf(contentNote)); 
                insert contentNoteRecord;
                ContentDocument contentDocument = [SELECT Id from ContentDocument where Id =: contentNoteRecord.Id];
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink(ContentDocumentId=contentDocument.Id,LinkedEntityId=contactId,ShareType='V',Visibility='AllUsers');
                insert contentDocumentLink;
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description Method to fetch saved notes
    **/
    @AuraEnabled
    public static List<Map<String,Object>> getContentNotes(Id contactId){
        List<Map<String,Object>> recordsList = new List<Map<String,Object>>();
        Set<Id> noteIds = new Set<Id>();
        List<Contact> contactList = [SELECT Id,(SELECT Id from AttachedContentNotes) FROM Contact WHERE Id = :contactId];
        for(AttachedContentNote attachedContentNote : contactList[0].AttachedContentNotes){
            noteIds.add(attachedContentNote.Id);
        }
        for(ContentNote contentNote : [SELECT Id, Title, Content, CreatedDate, CreatedBy.Name,TextPreview FROM ContentNote WHERE Id IN: noteIds ORDER BY CreatedDate DESC]){
            recordsList.add(new Map<String,Object>{'CreatedDate' => contentNote.CreatedDate, 'CreatedBy' => contentNote.CreatedBy.Name, 'Content' => contentNote.Content.toString().unescapeHtml4().unescapeHtml3().unescapeJava()});
        }
        return recordsList;
    }    
    /**
    * @description Lawyer Wrapper
    **/
    public class Lawyer {
        @AuraEnabled
        public Contact contact;
        @AuraEnabled
        public Decimal outstandingBalance;
        @AuraEnabled
        public Integer noOfAccountFiles;

        /**
        * @description Constructor
        **/
        public Lawyer(Contact contact, Integer noOfAccountFiles, Decimal outstandingBalance){
            this.contact = contact;
            this.outstandingBalance = outstandingBalance;
            this.noOfAccountFiles = noOfAccountFiles;
        }
    }
}