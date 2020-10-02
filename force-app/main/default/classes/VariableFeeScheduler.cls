global class VariableFeeScheduler implements Schedulable{
	global void execute(SchedulableContext sc)    
    {
        createFees(Date.today());
    }
    public static void createFees(Date dt){        
        Map<Id, List<Drawdown__c>> oppIdToDrawdowns = getExistingDrawdowns(dt);        
        List<Variable_Fee__c> variableFeesToProcess = getVariableFeesToProcess(dt);
        List<Drawdown__c> drawdownsToInsert = new List<Drawdown__c>();
        for (Variable_Fee__c vf : variableFeesToProcess){ 
            if (!drawdownExists(vf, oppIdToDrawdowns)){                
                Decimal amount = vf.Fee_Type__c=='%' ? vf.Opportunity__r.Amount * vf.Rate__c / 100.0 : vf.Rate__c;
                Drawdown__c d = new Drawdown__c(Date__c=dt, Amount__c=amount, Payment_Method__c='Admin Fee', Opportunity__c = vf.Opportunity__c,
                                                Reference_Notes__c='Admin Fee', Variable_Fee_Effected_At__c=vf.Effective_At__c);
                drawdownsToInsert.add(d);
            }
        }
        if (!drawdownsToInsert.isEmpty())
            insert drawdownsToInsert;
    }
    public static Map<Id, List<Drawdown__c>> getExistingDrawdowns(Date dt){
        List<Drawdown__c> existingDrawdowns = [select Id, Opportunity__c, Variable_Fee_Effected_At__c from Drawdown__c where Variable_Fee_Effected_At__c != null and Payment_Method__c='Admin Fee' and Date__c=:dt order by Opportunity__c];
        Map<Id, List<Drawdown__c>> oppIdToDrawdowns = new Map<Id, List<Drawdown__c>>();
        for (Drawdown__c d : existingDrawdowns){
            if (oppIdToDrawdowns.containsKey(d.Opportunity__c))
                oppIdToDrawdowns.get(d.Opportunity__c).add(d);
            else
                oppIdToDrawdowns.put(d.Opportunity__c, new List<Drawdown__c>{d});
        }
        return oppIdToDrawdowns;
    }
    public static List<Variable_Fee__c> getVariableFeesToProcess(Date dt){
        List<Variable_Fee__c> variableFees = [select Fee_Type__c, Month__c, Effective_At__c, Rate__c, Opportunity__c, 
                                              Opportunity__r.Date_of_advance__c, Opportunity__r.Amount from Variable_Fee__c 
                                              where Opportunity__r.Amount != null and Opportunity__r.Date_of_advance__c != null order by Order__c];
        List<Variable_Fee__c> variableFeesToProcess = new List<Variable_Fee__c>();        
        for (Variable_Fee__c variableFee : variableFees){
            if (variableFee.Opportunity__r.Date_of_advance__c != null){
                if (variableFee.Effective_At__c == 'Loan Setup' && variableFee.Opportunity__r.Date_of_advance__c == dt){
                    variableFeesToProcess.add(variableFee);
                }
                if (variableFee.Effective_At__c == 'Annual' && variableFee.Opportunity__r.Date_of_advance__c.year() < dt.year()
                   && variableFee.Opportunity__r.Date_of_advance__c.month() == dt.month() && variableFee.Opportunity__r.Date_of_advance__c.day() == dt.day()){
                       variableFeesToProcess.add(variableFee);
                }
                if (variableFee.Effective_At__c == 'BOM' && variableFee.Month__c != null){
                    Date nextDate = variableFee.Opportunity__r.Date_of_advance__c.addMonths((Integer)variableFee.Month__c);
                    System.debug('Next date ' + nextDate);
                    if (nextDate == dt){
                        variableFeesToProcess.add(variableFee);
                    }
                }
                if (variableFee.Effective_At__c == 'One Time' && variableFee.Month__c != null){
                    Date nextDate = variableFee.Opportunity__r.Date_of_advance__c.addMonths((Integer)variableFee.Month__c);
                    if (nextDate == dt){
                        variableFeesToProcess.add(variableFee);
                    }
                }
            }
        }
        return variableFeesToProcess;
    }
    public static Boolean drawdownExists(Variable_Fee__c vf, Map<Id, List<Drawdown__c>> oppIdToDrawdowns){
        if (!oppIdToDrawdowns.containsKey(vf.Opportunity__c))
            return false;        
        for (Drawdown__c d : oppIdToDrawdowns.get(vf.Opportunity__c)){
            if (vf.Effective_At__c == d.Variable_Fee_Effected_At__c)
                return true;
        }
        return false;
    }
}