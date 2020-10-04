/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-28-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-17-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public  class AccountObjHandler {
    public static void UnderwriterEvaluationCheck(Boolean isUpdate, Map<Id, Account> OldMap, List<Account> NewAcc){
        /* ======= Get All Account Fields Labels ======= */
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get('Account');
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        /* ======= Get All Account Fields Labels ======= */

        List<Underwriter_Evaluation_History__c> UEHToAdd = new List<Underwriter_Evaluation_History__c>();
        Map<String,String> ApiToLabel = new Map<String,String>();
        List<Id> AccId = new List<Id>();

        for(Account accInfo : NewAcc){
            if(isUpdate && accInfo.Projected_Loan_Value__c != OldMap.get(accInfo.Id).Projected_Loan_Value__c){ 
                UEHToAdd.add(HistoryCreatorList('Estimated Case Value', String.valueOf(OldMap.get(accInfo.Id).Projected_Loan_Value__c), String.valueOf(accInfo.Projected_Loan_Value__c), accInfo.Id));
            }

            if(isUpdate && accInfo.Offers_to_Settle__c != OldMap.get(accInfo.Id).Offers_to_Settle__c){
                UEHToAdd.add(HistoryCreatorList('Offers to settle', String.valueOf(OldMap.get(accInfo.Id).Offers_to_Settle__c), String.valueOf(accInfo.Offers_to_Settle__c), accInfo.Id));
            }

            if(isUpdate && accInfo.Offer_to_Settle_Amount__c != OldMap.get(accInfo.Id).Offer_to_Settle_Amount__c){
                UEHToAdd.add(HistoryCreatorList('Offer to Settle Amount', String.valueOf(OldMap.get(accInfo.Id).Offer_to_Settle_Amount__c), String.valueOf(accInfo.Offer_to_Settle_Amount__c), accInfo.Id));
            }

            if(isUpdate && accInfo.Liability__c != OldMap.get(accInfo.Id).Liability__c){
                UEHToAdd.add(HistoryCreatorList('Liability', String.valueOf(OldMap.get(accInfo.Id).Liability__c), String.valueOf(accInfo.Liability__c), accInfo.Id));
            }

            if(isUpdate && accInfo.Underwriter_Notes__c != OldMap.get(accInfo.Id).Underwriter_Notes__c){
                UEHToAdd.add(HistoryCreatorList('Underwriter Notes', OldMap.get(accInfo.Id).Underwriter_Notes__c, accInfo.Underwriter_Notes__c, accInfo.Id));
            }

            if(isUpdate && accInfo.Reason_for_LTV__c != OldMap.get(accInfo.Id).Reason_for_LTV__c){
                UEHToAdd.add(HistoryCreatorList('Reason', String.valueOf(OldMap.get(accInfo.Id).Reason_for_LTV__c), String.valueOf(accInfo.Reason_for_LTV__c), accInfo.Id));
            }
            accInfo.Underwriter_Notes__c = '';
        }

        if(UEHToAdd.size() > 0){
            insert UEHToAdd;
        }
    }

    public static Underwriter_Evaluation_History__c HistoryCreatorList(String FieldName, String OldValue, String NewValue, String AccountId){
        Underwriter_Evaluation_History__c UEH = new Underwriter_Evaluation_History__c();
        UEH.Field_Name__c = FieldName;
        UEH.Old_Value__c = OldValue;
        UEH.New_Value__c = NewValue;
        UEH.Account__c = AccountId;
        return UEH;
    }

    public static void CreateHistoryOnAccountCreate(Boolean isInsert, List<Account> NewAcc){
        List<Underwriter_Evaluation_History__c> UEHToInsert = new List<Underwriter_Evaluation_History__c>();
        for(Account accInfo : NewAcc){
            if(isInsert){
                if(accInfo.Projected_Loan_Value__c != null){
                    UEHToInsert.add(HistoryCreatorList('Estimated Case Value', '', String.valueOf(accInfo.Projected_Loan_Value__c), accInfo.id));
                }

                if(!String.isEmpty(accInfo.Offers_to_Settle__c)){
                    UEHToInsert.add(HistoryCreatorList('Offers to settle', '', String.valueOf(accInfo.Offers_to_Settle__c), accInfo.id));
                }
                
                if(accInfo.Offer_to_Settle_Amount__c != null){
                    UEHToInsert.add(HistoryCreatorList('Offer to Settle Amount', '', String.valueOf(accInfo.Offer_to_Settle_Amount__c), accInfo.id));
                }

                if(accInfo.Liability__c != null){
                    UEHToInsert.add(HistoryCreatorList('Liability', '', String.valueOf(accInfo.Liability__c), accInfo.id));
                }

                if(!String.isEmpty(accInfo.Underwriter_Notes__c)){
                    UEHToInsert.add(HistoryCreatorList('Underwriter Notes', '', accInfo.Underwriter_Notes__c, accInfo.id));
                }

                if(!String.isEmpty(accInfo.Reason_for_LTV__c)){
                    UEHToInsert.add(HistoryCreatorList('Reason', '', String.valueOf(accInfo.Reason_for_LTV__c), accInfo.id));
                }
            }
        }
        if(UEHToInsert.size() > 0){
            Insert UEHToInsert;
        }
    }
}