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
            List<Opportunity> opps = [select Payout_Date__c, Reserve_Date__c, Reserve_Amount__c, Reserve_Amount_Without_Clearing__c, Is_Reserve_Applied__c, Interest_Accrued_as_of_Reserve_Date__c,
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
                     Interest_Accrued_as_of_Reserve_Date__c, Reserve_Non_Repaid_Interest__c, Reserve_Exposure__c, Reserve_Amount__c, Reserve_Amount_Without_Clearing__c, Stop_Interest__c, Payments_after_Reserve_Date__c,
                    Advances_after_Reserve_Date__c, Principal_Advanced_To_Reserve_Date__c, FV_at_Freeze_Date__c, Value_At_Reserve_Date__c from Opportunity where Id=:oppIds];
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
            opp.Reserve_Amount_Without_Clearing__c = null;
        }            
        else{
            if (reserveInfoMap.get('Reserve_Date__c') != null){
                Date reserveDate = reserveInfoMap.get('Reserve_Date__c') instanceOf Date ? Date.valueOf(reserveInfoMap.get('Reserve_Date__c')) : Date.valueOf((String)reserveInfoMap.get('Reserve_Date__c'));
                opp.Reserve_Date__c = reserveDate;
            }
            else 
                opp.Reserve_Date__c = null;
            //opp.Payout_Date__c = reserveDate;                
            opp.Reserve_Amount__c = Double.valueOf(reserveInfoMap.get('Reserve_Amount__c'));
            opp.Reserve_Amount_Without_Clearing__c = Double.valueOf(reserveInfoMap.get('Reserve_Amount__c'));
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
        List<Drawdown__c> advances = [select Id, Opportunity__c, Reserve_Date__c, Is_Reserve_Applied__c, Stop_Interest__c from Drawdown__c where Opportunity__c in :oppIds];
        List<Drawdown__c> advancesToUpdate = new List<Drawdown__c>();
        for (Drawdown__c advance : advances){
            Opportunity opp = idToOppMap.get(advance.Opportunity__c);
            if ((advance.Reserve_Date__c != opp.Reserve_Date__c) || (advance.Is_Reserve_Applied__c != opp.Is_Reserve_Applied__c) || (advance.Stop_Interest__c != opp.Stop_Interest__c)){
                advance.Reserve_Date__c = opp.Reserve_Date__c;
                advance.Is_Reserve_Applied__c = opp.Is_Reserve_Applied__c;
                advance.Stop_Interest__c = opp.Stop_Interest__c;
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
    
    public static void notifyUponPayment(String accountId){          
        Account account = [select Id, Name, Is_Reserve_Applied__c from Account where Id=:accountId];            
        if (account.Is_Reserve_Applied__c){            
            String accountLink = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Account/' + accountId + '/view';  
            List<String> emailRecipients = getEmailRecipients();
            if (!emailRecipients.isEmpty())
            	MailHelper.sendSingleMessage('info@easylegal.ca', emailRecipients, 'Payment received on account marked "Reserve"', 'Payment has been received on account marked "Reserve". Follow the link below to access the account: ' + accountLink, true);
        }
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
    
    public static List<String> getEMailRecipients(){
        List<ELFI_Accounting_Email_Address__mdt> emailAddresses = [select Email__c from ELFI_Accounting_Email_Address__mdt where DeveloperName='ELFI_Accounting_Email_Address'];
        if (!emailAddresses.isEmpty()){
            if (!String.isBlank(emailAddresses[0].Email__c)){
                List<String> addresses = emailAddresses[0].Email__c.split(',');            
                return addresses;
            }
        }
        return new List<String>();
    }
    
    public static String getReserveEMailSubject(Boolean isNew, Opportunity oldOpp, Opportunity opp){
        String subject = '';
        if ((isNew && opp.Is_Reserve_Applied__c) || opp.Is_Reserve_Applied__c != oldOpp.Is_Reserve_Applied__c){
            if (opp.Is_Reserve_Applied__c){
                subject = 'Reserve Enabled on ' + opp.Name + ' account';                
            }
            else
                subject = 'Reserve Disabled on ' + opp.Name + ' account';
        }
        else if (opp.Is_Reserve_Applied__c && (opp.Reserve_Date__c != oldOpp.Reserve_Date__c || opp.Stop_Interest__c != oldOpp.Stop_Interest__c || opp.Reserve_Amount__c != oldOpp.Reserve_Amount__c)){
            subject = 'Reserve Details Updated on ' + opp.Name + ' account';
        }
        
        return subject;
    }
    
    public static String getReserveEMailMessage(Boolean isNew, Opportunity oldOpp, Opportunity opp){
        String message = '';
        if ((isNew && opp.Is_Reserve_Applied__c) || opp.Is_Reserve_Applied__c != oldOpp.Is_Reserve_Applied__c){
            if (opp.Is_Reserve_Applied__c){                
                message = 'Reserve date of ' + Utils.formatDate(opp.Reserve_Date__c, 'MMM dd, yyyy') + ' was set for this account.';
            }
        }
        else{
            Integer updatesCount = 0;
            if (opp.Stop_Interest__c != oldOpp.Stop_Interest__c){
                //message = 'Interest was frozen';
                updatesCount += 1;
            }
            if (opp.Reserve_Amount__c != oldOpp.Reserve_Amount__c){
                if (opp.Reserve_Amount__c == 0.0 && oldOpp.Reserve_Amount__c != null && oldOpp.Reserve_Amount__c > 0.0)
                    message = 'Reserve amount was cleared for this account';
                else
                	message = 'Reserve of ' + Utils.formatCurrency(opp.Reserve_Amount__c) + '$ was added to account ' + opp.Name;
                updatesCount += 1;
            }
            if (opp.Reserve_Date__c != oldOpp.Reserve_Date__c){
                message = 'Reserve date of ' + Utils.formatDate(opp.Reserve_Date__c, 'MMM dd, yyyy') + ' was set for this account.';
                updatesCount += 1;
            }                
            if (updatesCount > 1)
                message = 'Multiple fields updated';
        }
        
        return message;
    }
    
}