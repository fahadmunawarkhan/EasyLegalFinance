public with sharing class OpportunityTriggerHandler {
    
    
    public static void setDiscountschedule(List<Opportunity> newOpps, Map<Id,Opportunity> oldMap, Boolean isInsert){
        
        List<Opportunity> selOpportunities = new List<Opportunity>();
        List<Assessment_Provider_Schedule__c> assessmentScheduleToInsert = new List<Assessment_Provider_Schedule__c>();
        Set<Id> assessmentProviderIds = new Set<Id>();
        Set<Id> lawyerIds = new Set<Id>();
        
        for(Opportunity opp : newOpps){
            if(opp.Type_of_Loan__c == 'Assessment' &&
               (isInsert || (!isInsert && (opp.Assessment_Provider__c != oldMap.get(opp.Id).Assessment_Provider__c ||
                                           opp.Lawyer__c != oldMap.get(opp.Id).Lawyer__c)))){
                                               
                                               selOpportunities.add(opp);
                                               assessmentProviderIds.add(opp.Assessment_Provider__c);
                                               lawyerIds.add(opp.Lawyer__c);
                                           }
        }
        
        if(!selOpportunities.isEmpty()){
            Map<String,Assessment_Provider_Schedule__c> discountscheduleMap = new Map<String, Assessment_Provider_Schedule__c>();
            for(Assessment_Provider_Schedule__c aps : [Select Id, Lawyer__c, Assessment_Provider__c, Discount__c, Rebate_Discount__c, Rebate_Period__c
                                                       FROM Assessment_Provider_Schedule__c 
                                                       WHERE Assessment_Provider__c in :assessmentProviderIds
                                                       AND Lawyer__c in :lawyerIds order by CreatedDate asc]){
                                                           discountscheduleMap.put(aps.Assessment_Provider__c + '-' + aps.Lawyer__c, aps);
                                                       }
            
            
            for(Opportunity opp : selOpportunities){
                opp.Discount_Rate__c = 0;
                opp.Rebate_Discount__c = 0;
                opp.Rebate_Period__c = null;
                
                String key = opp.Assessment_Provider__c + '-' + opp.Lawyer__c;
                if(discountscheduleMap.containsKey(key)){
                    opp.Discount_Rate__c = discountscheduleMap.get(key).Discount__c;
                    opp.Rebate_Discount__c = discountscheduleMap.get(key).Rebate_Discount__c;
                    string periodStr = discountscheduleMap.get(key).Rebate_Period__c;
                    List<String> splited = periodStr.split(' ');
                    opp.Rebate_Period__c = !splited.isEmpty()? Integer.valueOf(splited[0]): null;
                    
                }else if(opp.Assessment_Provider__c != null && opp.Law_Firm__c != null && opp.Lawyer__c != null){
                    assessmentScheduleToInsert.add(
                        new Assessment_Provider_Schedule__c(
                            Assessment_Provider__c = opp.Assessment_Provider__c,
                            Lawyer__c = opp.Lawyer__c,
                            Discount__c = 0
                        )
                    );
                } 
            }
        }

        if(!assessmentScheduleToInsert.isEmpty())
            insert assessmentScheduleToInsert;
    }
}