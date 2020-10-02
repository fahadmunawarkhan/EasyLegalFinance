/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-01-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   10-01-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class CustomNotesComponentCtrl {
    @AuraEnabled
    public static List<CustomerViewComponentCtlr.NoteWrapper> getEnhancedNotes(String accountId){
        return CustomerViewComponentCtlr.getEnhancedNotes(accountId);
    }
    @AuraEnabled
    public static User getCurrentUserInfo(){
        return CustomerViewComponentCtlr.getCurrentUserInfo();
    }
    @AuraEnabled
    public static void createRecord(String nt, id PrentId){
        CustomerViewComponentCtlr.createRecord(nt, PrentId);
    }
    @AuraEnabled
    public static void updateContentNotes(String cnoteId, String body){
        CustomerViewComponentCtlr.updateContentNote(cnoteId, body);
    }
    @AuraEnabled
    public static void delContentNote(String cnoteId){
        CustomerViewComponentCtlr.delContentNote(cnoteId);
    }
    @AuraEnabled
    public static String getObjectName(String ObjId){
        String objectName = '';
        String myIdPrefix = String.valueOf(ObjId).substring(0,3);
        Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
        for(Schema.SObjectType stype : gd.values()){
            Schema.DescribeSObjectResult r = stype.getDescribe();
            String prefix = r.getKeyPrefix();
            if(prefix!=null && prefix.equals(myIdPrefix)){
                objectName = r.getName();
                break;
            }
        }
        return objectName;
    }
}