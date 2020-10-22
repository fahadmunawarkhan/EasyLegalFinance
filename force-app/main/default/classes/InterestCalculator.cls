public class InterestCalculator {
    public static Decimal getCompoundInterestMultiplier(Decimal annualRate, Decimal compoundingFrequency, Date interestStartDate, Date interestEndDate){
        Integer accrualDays = interestStartDate.daysBetween(interestEndDate);
        if (interestEndDate <= interestStartDate)
            accrualDays = 0;
        System.debug('Accrual Days ' + accrualDays);
        Decimal accrualYears = accrualDays / 365.0;
        //accrualYears = accrualYears.setScale(5);
        System.debug('Accrual Years ' + accrualYears);
        System.debug('Annual rate ' + annualRate);
        System.debug('Compounding freq ' + compoundingFrequency);
        Decimal value = 1.0 + annualRate /( 100.0 * compoundingFrequency);
        Decimal exp = compoundingFrequency * accrualYears;
        System.debug(value);
        System.debug(exp);
        Decimal result = Math.exp(Math.log(value) * exp);
        System.debug('Result ' + result);
        return result;
    }
    public static Decimal getCompoundInterest(Decimal principal, Decimal annualRate, Decimal compoundingFrequency, Date interestStartDate, Date interestEndDate){
        Decimal multiplier = getCompoundInterestMultiplier(annualRate, compoundingFrequency, interestStartDate, interestEndDate);        
        Decimal result = multiplier * principal;
        //result = result.setScale(2);
        System.debug('Result ' + result);
        return result;
    }    
    public static void calculateVariableRates(Id oppId){
        List<Opportunity> opps = getOpps(new List<Id>{oppId});
        if (!opps.isEmpty()){
            Date payoutDate = opps[0].Payout_Date__c;
            if (payoutDate != null){
                opps[0].Payout_Date__c = null;
                update opps;
                opps[0].Payout_Date__c = payoutDate;
            }
            else 
                opps[0].Payout_Date__c = Date.today();
            update opps;
        }
        calculateVariableRates(opps);
    }    
    public static Date getInterestStartDate(Drawdown__c d, Opportunity opp){
        if (d.Interest_Start_Date__c != null)
            return d.Interest_Start_Date__c;
        Date interestStartDate = d.Date__c;
        if (opp.Interest_Deferral_Period__c != null && Integer.valueOf(opp.Interest_Deferral_Period__c) > 0)
            return interestStartDate.addMonths(Integer.valueOf(opp.Interest_Deferral_Period__c));
        if (d.Date_of_Last_Repayment__c != null)
            return d.Interest_End_Date_at_Last_Repayment__c.addDays(1);
        return d.Date__c;        
    }    
    public static Date getInterestEndDate(Date payoutDate, Date fundingDate, Drawdown__c d, Opportunity opp){
        if (payoutDate == d.Date__c)
            return payoutDate;
        Date minimumInterestPeriodDate = fundingDate.addDays((Integer)(30 * Integer.valueOf(opp.Minimum_Interest_Period_Number__c) -0));
        return payoutDate > minimumInterestPeriodDate ? payoutDate.addDays(0) : minimumInterestPeriodDate;
    }
    public static void calculateVariableRates(List<Drawdown__c> drds, List<Variable_Rate__c> vrs, Date payoutDate, Opportunity opp, Boolean isBOMGenerating){
        if (!isBOMGenerating)
        	payoutDate = payoutDate.addDays(1);
        for (Drawdown__c d : drds){
            Decimal amountAdjustedForRepayment = d.Amount_Adjusted_for_Repayments__c;
            if (amountAdjustedForRepayment == null)
                amountAdjustedForRepayment = d.Amount__c;

            if (d.No_Interest__c){
                d.Outstanding_Balance_VR__c = amountAdjustedForRepayment;
            }
            else{
                Date effectiveDate = opp.Date_Of_Advance__c;
                Decimal totalMultiplier = 1.0;
                Boolean isBOM = d.Reference_Notes__c == 'Admin Fee - BOM';
                Date drawdownInterestStartDate = getInterestStartDate(d, opp);                
                Date drawdownInterestEndDate = getInterestEndDate(payoutDate, effectiveDate, d, opp);
                System.debug(drawdownInterestEndDate);
                for (Variable_Rate__c vr : vrs){
                    Date vrStartDate = effectiveDate.addDays((Integer)(((vr.Month_Start__c - 1)/12.0) * 365.0));                    
                    //vrStartDate = vrStartDate.addDays(1);
                    Date vrEndDate = vr.Month_End__c == null ? null : effectiveDate.addDays((Integer)((vr.Month_End__c/12.0)*365.0)).addDays(0); 
                    System.debug('Dates ' + amountAdjustedForRepayment + ' ' + drawdownInterestStartDate + ' ' + drawdownInterestEndDate +' ' +vrStartDate + ' ' + vrEndDate);
                    if (drawdownInterestEndDate >= vrStartDate && (vrEndDate == null || drawdownInterestStartDate <= vrEndDate)){
                        Date interestStartDate = (drawdownInterestStartDate < vrStartDate) ? vrStartDate : drawdownInterestStartDate;
                        Date interestEndDate = (vrEndDate != null && drawdownInterestEndDate >= vrEndDate) ? vrEndDate : drawdownInterestEndDate;
                        /*if (interestEndDate == payoutDate)
                            interestEndDate = interestEndDate.addDays(1);*/
                        System.debug(interestStartDate);
                        System.debug(interestEndDate);
                        System.debug(vr.Rate__c);
                        Decimal multiplier = InterestCalculator.getCompoundInterestMultiplier(vr.Rate__c, Integer.valueOf(opp.Compounding_Frequency__c), interestStartDate, interestEndDate);                       
                        totalMultiplier *= multiplier;                        
                    }
                }
                d.Outstanding_Balance_VR__c = amountAdjustedForRepayment * totalMultiplier;
            }            
        }
    }
    public static List<Variable_Rate__c> getVariableRates(List<Id> vrOppIds){
        List<Variable_Rate__c> variableRates = [Select Month_Start__c, Month_End__c, Rate__c, Opportunity__c  from Variable_Rate__c where Opportunity__c in :vrOppIds order by Opportunity__c, Month_Start__c asc];
        return variableRates;
    }
    public static List<Variable_Rate__c> getVRListForSimpleInterestRateType(Opportunity opp){
        Variable_Rate__c vr = new Variable_Rate__c();
        vr.Month_Start__c = 1;
        vr.Rate__c = opp.Interest_Rate__c;
        vr.Opportunity__c = opp.Id;        
        List<Variable_Rate__c> vrs = new List<Variable_Rate__c>{vr};
        return vrs;
    }
    public static List<Opportunity> getOpps(List<Id> vrOppIds){
        List<Opportunity> opps = [select Id, Date_Of_Advance__c, Payout_Date__c, Minimum_Interest_Period_Number__c, Interest_Rate_Type__c, Interest_Rate__c,  
                                  Interest_Deferral_Period__c, Compounding_Frequency__c from Opportunity where Id in :vrOppIds];
        return opps;
    }
    public static List<Drawdown__c> getDrawdowns(List<Id> vrOppIds){
        List<Drawdown__c> drawdowns = [select Id, Date_of_Last_Repayment__c, Interest_End_Date_at_Last_Repayment__c, No_Interest__c, Amount__c, Opportunity__c, Date__c, Interest_up_to_Last_Repayment__c, Amount_Adjusted_for_Repayments__c,
                                       Compounding_Interest__c, Compounding_Frequency__c, Interest_Start_Date__c, Interest_End_Date__c, Reference_Notes__c, Outstanding_Balance_VR__c 
                                       from Drawdown__c where Opportunity__c in :vrOppIds and Has_Interest__c = true];
        return drawdowns;
    }
    public static void calculateVariableRates(List<Opportunity> vrOpps){
        System.debug('calculateVariableRates');
        List<Id> vrOppIds = new List<Id>();
        for (Opportunity opp : vrOpps){
            vrOppIds.add(opp.Id);            
        }
        List<Variable_Rate__c> variableRates = getVariableRates(vrOppIds);
        List<Drawdown__c> drawdowns = getDrawdowns(vrOppIds);
        Map<Id, List<Variable_Rate__c>> oppIdToVRs = new Map<Id, List<Variable_Rate__c>>();
        for (Variable_Rate__c vr : variableRates){            
            if (oppIdToVRs.containsKey(vr.Opportunity__c)){
                oppIdToVRs.get(vr.Opportunity__c).add(vr);
            }
            else
                oppIdToVRs.put(vr.Opportunity__c, new List<Variable_Rate__c>{vr});
        }
        List<Drawdown__c> drawdownsToUpdate = new List<Drawdown__c>();
        for (Opportunity opp : vrOpps){
            List<Drawdown__c> drawdownsForOpp = new List<Drawdown__c>();
            for (Drawdown__c d : drawdowns){   
                if (d.Opportunity__c == opp.Id)
                    drawdownsForOpp.add(d);
            }
            if (!drawdownsForOpp.isEmpty()){                
                List<Variable_Rate__c> vrs;
                if (opp.Interest_Rate_Type__c == 'Variable')
                	vrs = oppIdToVRs.get(opp.Id);
                else vrs = getVRListForSimpleInterestRateType(opp); 
                calculateVariableRates(drawdownsForOpp, vrs, opp.Payout_Date__c, opp, false);
                drawdownsToUpdate.addAll(drawdownsForOpp);
            }
        }
		if (!drawdownsToUpdate.isEmpty())
            update drawdownsToUpdate;
    }
}