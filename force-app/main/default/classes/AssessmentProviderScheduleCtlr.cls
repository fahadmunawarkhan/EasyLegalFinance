public with sharing class AssessmentProviderScheduleCtlr {
    
    @AuraEnabled
    public static void createAssessmentSchedulesbyLawFirm(Id recordId, Id lookupId, Decimal discount){
        
        try{
            Id lawyerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Lawyers').getRecordTypeId();
            
            List<Assessment_Provider_Schedule__c> assessmentSchedules = new List<Assessment_Provider_Schedule__c>();
            for(Contact lawyer : [SELECT Id, Name FROM Contact WHERE AccountId = :lookupId 
                                  AND RecordTypeId =:lawyerRecordTypeId]){
                                      assessmentSchedules.add(
                                          new Assessment_Provider_Schedule__c(
                                              Assessment_Provider__c = recordId,
                                              Lawyer__c = lawyer.Id,
                                              Discount__c = discount
                                          )
                                      );
                                  }
            if(!assessmentSchedules.isEmpty())
                insert assessmentSchedules;
            
            List<Opportunity> oppList = [SELECT Id, Discount_Rate__c FROM Opportunity 
                                        WHERE Law_Firm__c =: lookupId AND StageName != 'Closed With Loan'
                                        AND StageName != 'Closed No Loan' AND StageName != 'TESTING'
                                        AND Type_of_Loan__c = 'Assessment'];
                                        
            for(Opportunity opp : oppList){
                opp.Discount_Rate__c = discount;
            }
            if(!oppList.isEmpty()){
                update oppList;
            }
        }catch (Exception e){
            system.debug('Error : ' + e.getMessage() + ' ' + e.getLineNumber());
            system.debug(e.getStackTraceString());
            throw new AuraHandledException('Error:'+e.getMessage());
        }        
    }
    
    @AuraEnabled
    public static void createAssessmentSchedules(Id recordId, Id lookupId, Decimal discount){
        
        try{
            insert new Assessment_Provider_Schedule__c(
                Assessment_Provider__c = recordId,
                Lawyer__c = lookupId,
                Discount__c = discount
            );

            List<Opportunity> oppList = [SELECT Id, Discount_Rate__c FROM Opportunity 
                                        WHERE Lawyer__c =: lookupId AND StageName != 'Closed With Loan'
                                        AND StageName != 'Closed No Loan' AND StageName != 'TESTING'
                                        AND Type_of_Loan__c = 'Assessment'];
                                        
            for(Opportunity opp : oppList){
                opp.Discount_Rate__c = discount;
            }
            if(!oppList.isEmpty()){
                update oppList;
            }
        }catch (Exception e){
            system.debug('Error : ' + e.getMessage() );
            throw new AuraHandledException('Error:'+e.getMessage());
        }        
    }
    
    @AuraEnabled
    public static Account getAssessmentProviderInfo(Id recordId){
        return [SELECT Id, Name FROM Account WHERE Id =:recordId];
    }
    
    @AuraEnabled
    public static User getCurrentUserInfo(){
        return [SELECT Id, Can_Edit_Assessment_Schedule__c FROM User 
                WHERE Id = :UserInfo.getUserId()];
    }
    
    @AuraEnabled
    public static List<Assessment_Provider_Schedule__c> getAssessmentSchedules(Id assessmentProviderId){
        
        return [SELECT Id, Name, Assessment_Provider__c, Assessment_Provider__r.Name, Lawyer__c, 
                Lawyer__r.Name, Discount__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name
                FROM Assessment_Provider_Schedule__c
                WHERE Assessment_Provider__c = :assessmentProviderId];
    }
    
    @AuraEnabled
    public static List<Assessment_Provider_Schedule__c> getAssessmentSchedulesByLawyer(Id lawyerId){
        
        return [SELECT Id, Name, Assessment_Provider__c, Assessment_Provider__r.Name, Lawyer__c, 
                Lawyer__r.Name, Discount__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name 
                FROM Assessment_Provider_Schedule__c
                WHERE Lawyer__c = :lawyerId];
    }
}