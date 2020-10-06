/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-28-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-18-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public with sharing class UnderwriterEvaluationHistoryCtrl {
    @AuraEnabled
    public static List<Underwriter_Evaluation_History__c> UnderwriterEvaluationHistory(String AccountId){
        String query = 'SELECT Field_Name__c,New_Value__c, Old_Value__c, CreatedBy.Name, HistoryCreateDate__c FROM Underwriter_Evaluation_History__c WHERE Account__c =: AccountId';
        query += ' ORDER BY Createddate DESC';
        List<Underwriter_Evaluation_History__c> History = Database.query(query);
        return History;
    }
}