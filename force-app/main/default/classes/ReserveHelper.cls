public class ReserveHelper {
	public static List<Opportunity> applyReserveOpps(List<Map<String, Object>> reserveInfos){        
        List<Id> oppIds = new List<Id>();
        List<Id> oppWithReserveIds = new List<Id>();
        for (Map<String, Object> reserveInfoMap : reserveInfos){    
            prepareReserveMap(reserveInfoMap);
            oppIds.add((Id)reserveInfoMap.get('Id'));
            Boolean isReserveApplied = Boolean.valueOf(reserveInfoMap.get('Is_Reserve_Applied__c'));
            if (isReserveApplied)
                oppWithReserveIds.add((Id)reserveInfoMap.get('Id'));
        }
        if (!oppIds.isEmpty()){
            List<Opportunity> opps = [select Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c, Interest_Accrued_as_of_Reserve_Date__c,
                                      Stop_Interest__c from Opportunity where Id in :oppIds];
            Map<Id, Opportunity> idToOppMap = new Map<Id, Opportunity>();
            for (Opportunity opp : opps){
                idToOppMap.put(opp.Id, opp);
            }
            for (Map<String, Object> reserveInfoMap : reserveInfos){
                Id oppId = (Id)reserveInfoMap.get('Id');                    
                Opportunity opp = idToOppMap.get(oppId);
                updateOppReserveFields(opp, reserveInfoMap);
            }
            update opps;
            updateAdvances(oppIds, idToOppMap);
            updatePaymentAllocations(oppIds, idToOppMap);
            //updateOppsWithReserveApplied(oppWithReserveIds);
            opps = [select Is_Reserve_Applied__c, Payout_Date__c, Reserve_Date__c,Interest_Accrued_as_of_Payout_Date__c, Drawdown_Principal_Total__c,Non_Repaid_Drawdown_Principal_Total__c,
                     Interest_Accrued_as_of_Reserve_Date__c, Reserve_Exposure__c, Reserve_Amount__c, Stop_Interest__c from Opportunity where Id=:oppIds];
            return opps;
        }
        return new List<Opportunity>();
    }
    @TestVisible
    private static void prepareReserveMap(Map<String, Object> reserveInfoMap){
        if (reserveInfoMap.get('Is_Reserve_Applied__c') == null)
            reserveInfoMap.put('Is_Reserve_Applied__c', false);
        if (reserveInfoMap.get('Stop_Interest__c') == null)
            reserveInfoMap.put('Stop_Interest__c', false);        
        if (Boolean.valueOf(reserveInfoMap.get('Is_Reserve_Applied__c')) == true){
            if (reserveInfoMap.get('Reserve_Amount__c') == null)
                reserveInfoMap.put('Reserve_Amount__c', 0.0);
            /*if (reserveInfoMap.get('Reserve_Date__c') == null)
                reserveInfoMap.put('Reserve_Date__c', Date.today());*/
        }
    }
    @TestVisible
    private static void updateOppReserveFields(Opportunity opp, Map<String, Object> reserveInfoMap){
        Boolean isReserveApplied = Boolean.valueOf(reserveInfoMap.get('Is_Reserve_Applied__c'));         
        opp.Is_Reserve_Applied__c = isReserveApplied;
        opp.Stop_Interest__c = Boolean.valueOf(reserveInfoMap.get('Stop_Interest__c')); 
        if (!isReserveApplied){
            opp.Reserve_Date__c = null;            
            opp.Reserve_Amount__c = null;           
        }            
        else{
            Date reserveDate = reserveInfoMap.get('Reserve_Date__c') instanceOf Date ? Date.valueOf(reserveInfoMap.get('Reserve_Date__c')) : Date.valueOf((String)reserveInfoMap.get('Reserve_Date__c'));
            opp.Reserve_Date__c = reserveDate;
            //opp.Payout_Date__c = reserveDate;                
            opp.Reserve_Amount__c = Double.valueOf(reserveInfoMap.get('Reserve_Amount__c'));
        }                                        
    }
    
    /*private static void updateOppsWithReserveApplied(List<Id> oppWithReserveIds){
        if (!oppWithReserveIds.isEmpty()){
            List<Opportunity> opps = [select Is_Reserve_Applied__c, Non_Repaid_Drawdown_Principal_Total__c, Payout_Date__c, Reserve_Date__c, Interest_Accrued_as_of_Payout_Date__c, Drawdown_Principal_Total__c,Principal_Non_Repaid_as_of_To_Date__c,
                     Accrued_Interest_as_of_Reserve_Date__c, Reserve_Exposure__c, Total_Payout__c, Principal_Repaid_Roll_up__c from Opportunity where Id  in :oppWithReserveIds];
            Map<Id, Decimal> oppIdToInterestMap = calculateInterestAsOfReserveDate(oppWithReserveIds);
            for (Opportunity opp : opps){
                Decimal principal = opp.Non_Repaid_Drawdown_Principal_Total__c;
                if (oppIdToInterestMap.containsKey(opp.Id))
                	opp.Accrued_Interest_as_of_Reserve_Date__c = oppIdToInterestMap.get(opp.Id);
            }
            update opps;
        }
    }
    
    private static Map<Id, Decimal> calculateInterestAsOfReserveDate(List<Id> oppWithReserveIds){
        AggregateResult[] groupedResults = [select Opportunity__c, SUM(Accrued_Interest_as_of_Reserve_Date__c) from Drawdown__c where Opportunity__c in :oppWithReserveIds
                                           group by Opportunity__c];
        Map<Id, Decimal> oppIdToInterestMap = new Map<Id, Decimal>();
        for (AggregateResult ar : groupedResults){
            if (ar != null && ar.get('Opportunity__c') != null && ar.get('expr0') != null){
                oppIdToInterestMap.put(Id.valueOf(String.valueOf(ar.get('Opportunity__c'))), Decimal.valueOf(String.valueOf(ar.get('expr0'))));
            }
        }
        
        return oppIdToInterestMap;
	}*/
    
    private static void updateAdvances(List<Id> oppIds, Map<Id, Opportunity> idToOppMap){
        List<Drawdown__c> advances = [select Id, Opportunity__c, Reserve_Date__c from Drawdown__c where Opportunity__c in :oppIds];
        List<Drawdown__c> advancesToUpdate = new List<Drawdown__c>();
        for (Drawdown__c advance : advances){
            Opportunity opp = idToOppMap.get(advance.Opportunity__c);
            if (advance.Reserve_Date__c !=opp.Reserve_Date__c){
                advance.Reserve_Date__c = opp.Reserve_Date__c;
                advancesToUpdate.add(advance);
            }
        }
        if (!advancesToUpdate.isEmpty())
        	update advancesToUpdate;
	}
    
    private static void updatePaymentAllocations(List<Id> oppIds, Map<Id, Opportunity> idToOppMap){
        List<Drawdown_Payment_Allocation__c> allocations = [select Id, Opportunity__c, Reserve_Date__c from Drawdown_Payment_Allocation__c where Opportunity__c in :oppIds];
        List<Drawdown_Payment_Allocation__c> allocationsToUpdate = new List<Drawdown_Payment_Allocation__c>();
        for (Drawdown_Payment_Allocation__c allocation : allocations){
            Opportunity opp = idToOppMap.get(allocation.Opportunity__c);
            if (allocation.Reserve_Date__c !=opp.Reserve_Date__c){
                allocation.Reserve_Date__c = opp.Reserve_Date__c;
                allocationsToUpdate.add(allocation);
            }
        }
        if (!allocationsToUpdate.isEmpty())
        	update allocationsToUpdate;
	}
    
    public static void createTaskUponPayment(String accountId){          
        Account account = [select Id, Name, Is_Reserve_Applied__c from Account where Id=:accountId];            
        if (account.Is_Reserve_Applied__c){            
            List<User> users = [select Id, Name from User where Reserve__c=True];
            List<Task> tasks = new List<Task>();
            for (User user : users){
                Task task = new Task();        
                task.Priority = 'Normal';
                task.Status = 'Open';                
                task.WhatId = accountId;
                task.OwnerId = user.Id;                
                task.Subject = 'Payment received on account marked "Reserve"';                
                String accountLink = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Account/' + accountId + '/view';
                task.Description = 'Payment has been received on account marked "Reserve". Follow the link below to access the account: ' + accountLink;            
                tasks.add(task);                                
            }
            if (!tasks.isEmpty())
            	insert tasks;
        }
    }
}
