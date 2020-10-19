public class VariableFeeHelper {
    public class VariableFeeException extends Exception {} 
    
    public static void createFeesForOpp(Id oppId, Boolean onlyBOM){        
        List<Variable_Fee__c> variableFees = getVariableFees(oppId, onlyBOM);
        String referenceNotes = onlyBOM ? 'Admin Fee - BOM' : 'Admin Fee';
        List<Drawdown__c> existingFees = [select Id from Drawdown__c where Opportunity__c=:oppId and Reference_Notes__c=:referenceNotes];
        System.debug(existingFees.size());
        if (!existingFees.isEmpty()){
            Database.delete(existingFees, false);            
        }
        List<Drawdown__c> drawdownsToInsert = new List<Drawdown__c>();
        System.debug(variableFees.size());
        Decimal loanSetup = null;        
        for (Variable_Fee__c vf : variableFees){
            drawdownsToInsert.addAll(createDrawdowns(vf));
            if (vf.Effective_At__c == 'Loan Setup'){
                if (loanSetup == null)
                    loanSetup = 0.0;
                loanSetup += vf.Fee_Type__c=='%' ? vf.Opportunity__r.Amount * vf.Rate__c / 100.0 : vf.Rate__c;                    
            }
        }        
        System.debug(drawdownsToInsert.size());
        if (!drawdownsToInsert.isEmpty())
            insert drawdownsToInsert;
        if (loanSetup != null){
            Opportunity opp = [select Admin_Fee__c from Opportunity where Id=:oppId];
            opp.Admin_Fee__c = loanSetup;
            update opp;
        }
        List<Drawdown__c> advances = [select Id, Date__c, Variable_Fees_Generated__c, BOM_Fee_Advance__c, Payment_Method__c, Reference_Notes__c, No_Interest__c, Minimum_Interest_Period__c, Interest_Start_Date__c, Amount_Adjusted_for_Repayments__c, Compounding_Frequency__c, Opportunity__r.Date_Of_Advance__c from Drawdown__c where Opportunity__c=:oppId and Payment_Method__c != 'Payment' and Variable_Fees_Generated__c != true];
        for (Integer i = 0; i < advances.size(); i++){
            Drawdown__c advance = advances[i];
            advance.Variable_Fees_Generated__c = true;
        }
        if (!advances.isEmpty())
        	update advances;
        
    }
    
    public static void createBOMFeesForOpp(Id oppId){        
        List<Variable_Fee__c> variableFees = getVariableFees(oppId, true);
        String referenceNotes = 'Admin Fee - BOM';        
        List<Drawdown__c> existingFees = [select Id from Drawdown__c where Opportunity__c=:oppId and Reference_Notes__c=:referenceNotes];
        System.debug(existingFees.size());
        if (!existingFees.isEmpty()){
            Database.delete(existingFees, false);            
        }
        System.debug(variableFees.size());
        Opportunity opp = [select Id, Minimum_Interest_Period_Number__c, Interest_Rate_Type__c, Interest_Rate__c, Date_Of_Advance__c, Compounding_Frequency__c, Interest_Deferral_Period__c from Opportunity where Id=:oppId];
        List<Drawdown__c> advances = [select Id, Date__c, BOM_Fees_Generated__c, BOM_Fee_Advance__c, Payment_Method__c, Reference_Notes__c, No_Interest__c, Minimum_Interest_Period__c, Interest_Start_Date__c, Amount_Adjusted_for_Repayments__c, Compounding_Frequency__c, Opportunity__r.Date_Of_Advance__c from Drawdown__c where Opportunity__c=:oppId and Payment_Method__c != 'Payment'];
        Integer advancesCount = advances.size();
        List<Drawdown__c> drawdownsToInsert = new List<Drawdown__c>();
        List<Drawdown__c> newDrawdowns = createBOMDrawdowns(advances, advancesCount, variableFees, opp);
        drawdownsToInsert.addAll(newDrawdowns);
        insert drawdownsToInsert;
        List<Drawdown__c> drawdownsToUpdate = new List<Drawdown__c>();
        for (Integer i = 0; i < advancesCount; i++){
            Drawdown__c advance = advances[i];
            advance.BOM_Fees_Generated__c = true;
            drawdownsToUpdate.add(advance);
        }
        if (!drawdownsToUpdate.isEmpty())
        	update drawdownsToUpdate;
    }
    
    public static List<Variable_Fee__c> produceVariableFeesForAdvance(Drawdown__c advance, List<Variable_Fee__c> variableFees){
        List<Variable_Fee__c> result = new List<Variable_Fee__c>();
        for (Variable_Fee__c vf : variableFees){
            List<Variable_Fee__c> vfList = generateVariableFees(vf, advance.Date__c, Date.today());
            System.debug('vfsize ' + vfList.size());
            System.debug('vfsize1 ' + result.size());
            if (result.isEmpty())
                result.addAll(vfList);
            else
                mergeVariableFeesList(result, vfList);
        }
        return result;
    }
    
    public static void mergeVariableFeesList(List<Variable_Fee__c> result, List<Variable_Fee__c> listToMerge){
        for (Variable_Fee__c vf : listToMerge){
            Integer index = 0;
            while(index < result.size()){
                Variable_Fee__c vfi = result[index];
                if (vf.Month__c < vfi.Month__c)
                    break;
                index += 1;
            }
            if (index == result.size())
                result.add(vf);
            else
                result.add(index, vf);
        }
    }
    
    public static List<Variable_Fee__c> generateVariableFees(Variable_Fee__c vf, Date advanceDate, Date payoutDate){
        List<Variable_Fee__c> result = new List<Variable_Fee__c>();
        if (vf.Effective_At__c == 'One Time')
            result.add(vf);
        else if (vf.Effective_At__c == 'Annual'){                        
            Integer month = (Integer)vf.Month__c;
            Date dt = advanceDate.addMonths(month);
            while(dt <= payoutDate){
                Variable_Fee__c newVF = new Variable_Fee__c();
                newVF.Effective_At__c = vf.Effective_At__c;
                newVF.Fee_Type__c = vf.Fee_Type__c;
                newVF.Is_BOM__c = vf.Is_BOM__c;
                newVF.Month__c = month;
                newVF.Opportunity__c = vf.Opportunity__c;
                newVF.Rate__c = vf.Rate__c;
                System.debug('VFDate ' + dt + ' ' + month + ' '  + payoutDate);
                result.add(newVF);
                dt = dt.addYears(1);                
                month += 12;
            }            
        }
        return result;
    }
    
    public static List<Drawdown__c> addLinkedDrawdowns(Drawdown__c advance, List<Drawdown__c> advances, Boolean isFirstAdvance, Set<Id> processedDrawdownIds, Date toDate){
        List<Drawdown__c> result = new List<Drawdown__c>();
        for (Drawdown__c d : advances){
            Boolean needAdd = false;
            if (d.Id != advance.Id){
                if (isFirstAdvance && d.Payment_Method__c == 'Admin Fee' && d.Reference_Notes__c != 'Other fee - no interest'
                    && d.Date__c < toDate && (d.Reference_Notes__c != 'Admin Fee - BOM' || d.BOM_Fee_Advance__c == advance.Id))
                    needAdd = true;                    
                else if (!isFirstAdvance && d.Date__c < toDate && d.BOM_Fee_Advance__c == advance.Id)
                    needAdd = true;
                else if (d.Payment_Method__c != 'Admin Fee' && advance.Date__c == d.Date__c)
                    needAdd = true;                                        
                if (needAdd){
                	result.add(d);                
                    processedDrawdownIds.add(d.Id);
                }
            }
            
        }
        
        return result;
	}        
    
    public static List<Drawdown__c> createBOMDrawdowns(List<Drawdown__c> advances, Integer advancesCount, List<Variable_Fee__c> variableFees, Opportunity opp){     
        System.debug('createBOMDrawdowns');
        Id oppId = opp.Id;        
        List<Variable_Rate__c> variableRates;
        if (opp.Interest_Rate_Type__c == 'Variable')
        	variableRates = [Select Month_Start__c, Month_End__c, Rate__c, Opportunity__c  from Variable_Rate__c where Opportunity__c = :oppId order by Opportunity__c, Month_Start__c asc];        
        else{
            Variable_Rate__c vr = new Variable_Rate__c();
            vr.Month_Start__c = 1;
            vr.Rate__c = opp.Interest_Rate__c;
            vr.Opportunity__c = opp.Id;
            variableRates = new List<Variable_Rate__c>{vr};
        }
        if (variableRates == null || variableRates.isEmpty())
            throw new VariableFeeException('Variable Rates are not set');
        List<Drawdown__c> bomDrawdowns = new List<Drawdown__c>();
        String referenceNotes = 'Admin Fee - BOM';
        Boolean isFirstAdvance = true;
        Set<Id> processedDrawdownIds = new Set<Id>();
        for (Integer i = 0; i < advances.size(); i++){
            if ( i == advancesCount )
                break;
            Drawdown__c advance = advances[i];
            if (processedDrawdownIds.contains(advance.Id))
                continue;
            if (advance.Payment_Method__c != 'Admin Fee'){
                List<Variable_Fee__c> vfList = produceVariableFeesForAdvance(advance, variableFees);
                for (Variable_Fee__c vf : vfList){
                    System.debug('vfs ' + vf.Effective_At__c + ' ' + vf.Month__c);
                    Date dt = advance.Date__c;
                    System.debug(dt);
                    //dt = dt.addMonths((Integer)vf.Month__c);               
                    Integer daysOffset = (Integer)((vf.Month__c / 12.0) * 365.0);
                    dt = dt.addDays(daysOffset);
                    System.debug('dt ' + daysOffset  + ' '  + dt + ' '  + dt.addDays(daysOffset));
                    {
                        List<Drawdown__c> advanceWithFees = new List<Drawdown__c>{advance};
                        advanceWithFees.addAll(addLinkedDrawdowns(advance, advances, isFirstAdvance, processedDrawdownIds, dt));                        
                        advanceWithFees.addAll(addLinkedDrawdowns(advance, bomDrawdowns, isFirstAdvance, processedDrawdownIds, dt));
                        Decimal amount = getBOMAmount(advanceWithFees, vf, variableRates, dt, opp);                
                        Drawdown__c d = createDrawdown(vf, referenceNotes, dt, amount);
                        d.BOM_Fee_Advance__c = advance.Id;
                        d.Variable_Fees_Generated__c = true;   
						d.BOM_Fees_Generated__c = true;                        
                        bomDrawdowns.add(d);                        
                    }
                }
                isFirstAdvance = false;
            }            
        }
        
        return bomDrawdowns;        
    }
    
    public static Decimal getBOMAmount(List<Drawdown__c> drds, Variable_Fee__c vf, List<Variable_Rate__c> variableRates, Date dt, Opportunity opp){
        if (vf.Fee_Type__c=='$')
            return vf.Rate__c;
        InterestCalculator.calculateVariableRates(drds, variableRates, dt, opp, true);
        Decimal totalAmount = 0.0;        
        for (Drawdown__c d : drds){            
            Decimal advanceBalance = d.Outstanding_Balance_VR__c;
            System.debug(advanceBalance);
            System.debug(vf.Rate__c);
            Decimal amount = advanceBalance * vf.Rate__c / 100.0;
            System.debug(amount);
            totalAmount += amount;
        }        
        System.debug(totalAmount);
        return totalAmount;
    }
    
    public static List<Drawdown__c> createDrawdowns(Variable_Fee__c vf){
        List<Drawdown__c> drawdowns = new List<Drawdown__c>();
        String referenceNotes = vf.Is_BOM__c ? 'Admin Fee - BOM' : 'Admin Fee';
        Date dt = vf.Opportunity__r.Date_of_advance__c;
        if (dt == null)
            throw new VariableFeeException('Drawdowns are not generated. Funding Date is empty. Advance is not found');
        Decimal amount = vf.Fee_Type__c=='%' ? vf.Opportunity__r.Amount * vf.Rate__c / 100.0 : vf.Rate__c;
        if (vf.Effective_At__c == 'One Time' || vf.Effective_At__c == 'Loan Setup'){
            if (vf.Effective_At__c == 'One Time')
            	dt = dt.addMonths((Integer)vf.Month__c);                        
            if (dt <= Date.today()){
                Drawdown__c d = createDrawdown(vf, referenceNotes, dt, amount);
                drawdowns.add(d);
            }
        }
        else if (vf.Effective_At__c == 'Annual'){
            dt = dt.addMonths((Integer)vf.Month__c);      
            while(dt <= Date.today()){
                Drawdown__c d = createDrawdown(vf, referenceNotes, dt, amount);
                drawdowns.add(d);
                dt = dt.addYears(1);
            }
        }
        return drawdowns;        
    }
    
    public static Drawdown__c createDrawdown(Variable_Fee__c vf, String referenceNotes, Date dt, Decimal amount){
        System.debug(dt + ' '  + Date.today());                    
        return new Drawdown__c(Date__c=dt, Amount__c=amount, Payment_Method__c='Admin Fee', Opportunity__c = vf.Opportunity__c,
                                        Reference_Notes__c=referenceNotes, Variable_Fee_Effected_At__c=vf.Effective_At__c);                
        
    }
    
    public static List<Variable_Fee__c> getVariableFees(Id oppId, Boolean onlyBOM){
        List<Variable_Fee__c> variableFees;
        List<String> effectiveAtList = new List<String>();
        if (onlyBOM){
            effectiveAtList.add('Annual');
            effectiveAtList.add('One Time');
        }
        else{
            effectiveAtList.add('Loan Setup');
            effectiveAtList.add('Annual');
            effectiveAtList.add('One Time');
        }        
        variableFees = [select Fee_Type__c, Month__c, Effective_At__c, Rate__c, Opportunity__c, Is_BOM__c, 
                                              Opportunity__r.Date_of_advance__c, Opportunity__r.Amount from Variable_Fee__c 
                                              where Opportunity__c=:oppId and Effective_At__c in :effectiveAtList and Is_BOM__c=:onlyBOM];
        return variableFees;
    }
}