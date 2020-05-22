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
            List<Opportunity> opps = [select Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Is_Reserve_Applied__c, Accrued_Interest_as_of_Reserve_Date__c,
                                      Reserve_Principal_Advanced__c, Stop_Interest__c from Opportunity where Id in :oppIds];
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
            updateOppsWithReserveApplied(oppWithReserveIds);
            opps = [select Is_Reserve_Applied__c, Payout_Date__c, Reserve_Date__c,Interest_Accrued_as_of_Payout_Date__c, Drawdown_Principal_Total__c,
                    Reserve_Principal_Advanced__c, Accrued_Interest_as_of_Reserve_Date__c, Reserve_Exposure__c, Reserve_Amount__c, Stop_Interest__c from Opportunity where Id=:oppIds];
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
            if (reserveInfoMap.get('Reserve_Date__c') == null)
                reserveInfoMap.put('Reserve_Date__c', Date.today());
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
            opp.Accrued_Interest_as_of_Reserve_Date__c = null;
            opp.Reserve_Principal_Advanced__c = null;
        }            
        else{
            Date reserveDate = reserveInfoMap.get('Reserve_Date__c') instanceOf Date ? Date.valueOf(reserveInfoMap.get('Reserve_Date__c')) : Date.valueOf((String)reserveInfoMap.get('Reserve_Date__c'));
            opp.Reserve_Date__c = reserveDate;
            opp.Payout_Date__c = reserveDate;                
            opp.Reserve_Amount__c = Double.valueOf(reserveInfoMap.get('Reserve_Amount__c'));
        }                                        
    }
    
    private static void updateOppsWithReserveApplied(List<Id> oppWithReserveIds){
        if (!oppWithReserveIds.isEmpty()){
            List<Opportunity> opps = [select Is_Reserve_Applied__c, Non_Repaid_Drawdown_Principal_Total__c, Payout_Date__c, Reserve_Date__c, Interest_Accrued_as_of_Payout_Date__c, Drawdown_Principal_Total__c,Principal_Non_Repaid_as_of_To_Date__c,
                    Reserve_Principal_Advanced__c, Accrued_Interest_as_of_Reserve_Date__c, Reserve_Exposure__c, Total_Payout__c, Principal_Repaid_Roll_up__c from Opportunity where Id  in :oppWithReserveIds];
            for (Opportunity opp : opps){
                Decimal principal = opp.Non_Repaid_Drawdown_Principal_Total__c;
                opp.Accrued_Interest_as_of_Reserve_Date__c = opp.Total_Payout__c - principal;
                opp.Reserve_Principal_Advanced__c = principal;
            }
            update opps;
        }
    }
}