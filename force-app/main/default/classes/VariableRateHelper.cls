public class VariableRateHelper {
    public static Map<Id, List<Variable_Rate__c>> getVariableRatesByOppIdMap(Set<Id> oppIds){
        Map<Id, List<Variable_Rate__c>> oppIdToVariableRates = new Map<Id, List<Variable_Rate__c>>();
        List<Variable_Rate__c> vrs = [select Id, Opportunity__c, Month_Start__c, Month_End__c, Rate__c from Variable_Rate__c where Opportunity__c in :oppIds order by Opportunity__c, Month_Start__c asc];
        for (Variable_Rate__c vr : vrs){
        	if (oppIdToVariableRates.containsKey(vr.Opportunity__c))
                oppIdToVariableRates.get(vr.Opportunity__c).add(vr);
            else
                oppIdToVariableRates.put(vr.Opportunity__c,new List<Variable_Rate__c>{vr});
        }        
        return oppIdToVariableRates;
    }
    
    public static Integer getAffectedVariableRatesCount(List<Variable_Rate__c> variableRates, Date loanStartDate, Date payoutDate){
        if (payoutDate == null || loanStartDate == null)
            return variableRates.size();
        if (variableRates.size() == 0)
            return 0;
        Date dt = loanStartDate;
        Integer index = 0;
        while ( dt <= payoutDate && index < variableRates.size()){            
            if (variableRates[index].Month_Start__c == null || variableRates[index].Month_End__c == null)
                return variableRates.size();
            dt = dt.addMonths((Integer)variableRates[index].Month_Start__c);
            index += 1;
        }
        
        return index;
    }
    
    public static VariableRateDescription getVariableRateDescription(List<Variable_Rate__c> variableRates, Date loanStartDate, Date payoutDate){
        VariableRateDescription vrd = new VariableRateDescription();
        Integer affectedVariableRatesCount = getAffectedVariableRatesCount(variableRates, loanStartDate, payoutDate);
        for (Integer i = 0; i < affectedVariableRatesCount; i++){
            Variable_Rate__c vr = variableRates[i];
            if (i <= 1)
            	vrd.variableRateText += 'Months ' + vr.Month_Start__c + (vr.Month_End__c == null ? '+' : ('-' + vr.Month_End__c)) + ': ' +vr.Rate__c + '%, ';            
            else if (i == 2)
                vrd.variableRateText += '...';
            vrd.variableRateHelpText += 'Months ' + vr.Month_Start__c + (vr.Month_End__c == null ? '+' : ('-' + vr.Month_End__c)) + ': ' +vr.Rate__c + '%\r\n';            
        }
        if (vrd.variableRateText.endsWith(', '))
            vrd.variableRateText = vrd.variableRateText.substring(0, vrd.variableRateText.length()-2);
        if (affectedVariableRatesCount <= 2)
            vrd.variableRateHelpText = null;
        
        return vrd;
	}
    
    public class VariableRateDescription{
        public VariableRateDescription(){
            variableRateText = '';
            variableRateHelpText = '';
        }
        public String variableRateText{get;set;}
        public String variableRateHelpText{get;set;}
	}
}