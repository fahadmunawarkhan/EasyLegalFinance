public class VariableRateCtlr {
    @AuraEnabled
    public static List<VariableRateInfo> getVariableRateInfo(Id oppId, Id accountId){
        List<VariableRateInfo> result = new List<VariableRateInfo>();
        List<Variable_Rate__c> variableRates = [select Month_Start__c, Month_End__c, Rate__c from Variable_Rate__c where Opportunity__c=:oppId order by Month_Start__c];
        if (!variableRates.isEmpty()){
            for (Variable_Rate__c vr : variableRates){
                VariableRateInfo vri = new VariableRateInfo();
                vri.Id = vr.id;
                vri.periodStart = (Integer)vr.Month_Start__c;
                vri.periodEnd = (Integer)vr.Month_End__c;
                vri.rate = vr.Rate__c;
                result.add(vri);
            }            
        }
        else{
            Account acc = [select Business_Unit__c from Account where Id=:accountId];
            String businessUnit = acc.Business_Unit__c;
            List<Variable_Rate_Profile__mdt> profiles = [select Month_Start__c, Month_End__c, Rate__c from Variable_Rate_Profile__mdt where Business_Unit__c=:businessUnit order by Month_Start__c];
            if (!profiles.isEmpty()){
                for (Variable_Rate_Profile__mdt vrp : profiles){
                    VariableRateInfo vri = new VariableRateInfo();
                    vri.periodStart = (Integer)vrp.Month_Start__c;
                    vri.periodEnd = (Integer)vrp.Month_End__c;
                    vri.rate = vrp.Rate__c;
                    result.add(vri);
                }            
            }
        }
        return result;
    }        
    
    @AuraEnabled
    public static List<VariableFeeInfo> getVariableFeeInfo(Id oppId, Id accountId, Boolean onlyBOM){
        List<VariableFeeInfo> result = new List<VariableFeeInfo>();
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
        List<Variable_Fee__c> variableFees = [select Effective_At__c, Fee_Type__c, Month__c, Rate__c, Order__c from Variable_Fee__c where Opportunity__c=:oppId and Effective_At__c in :effectiveAtList and Is_BOM__c=:onlyBOM order by Month__c, Order__c];
        if (!variableFees.isEmpty()){
            for (Variable_Fee__c vf : variableFees){
                VariableFeeInfo vfi = new VariableFeeInfo();
                vfi.Id = vf.id;
                vfi.feeType = vf.Fee_Type__c;
                vfi.effectiveAt = vf.Effective_At__c;
                vfi.month = (Integer)vf.Month__c;                
                vfi.rate = vf.Rate__c;                
                result.add(vfi);
            }            
        }
        else{            
            Opportunity opp = [select Account.Business_Unit__c, Type_Of_Loan__c from Opportunity where Id=:oppId];
            String businessUnit = opp.Account.Business_Unit__c;
            String typeOfLoan = opp.Type_of_Loan__c;
            List<Variable_Fee_Profile__mdt> profiles = [select Effective_At__c, Fee_Type__c, Month__c, Rate__c, Order__c from Variable_Fee_Profile__mdt where Business_Unit__c=:businessUnit and Type_of_Loan__c=:typeOfLoan and Effective_At__c in :effectiveAtList and Is_BOM__c=:onlyBOM order by Month__c, Order__c];
            if (!profiles.isEmpty()){
                for (Variable_Fee_Profile__mdt vfp : profiles){
                    VariableFeeInfo vfi = new VariableFeeInfo();
                    vfi.Id = vfp.id;
                    vfi.feeType = vfp.Fee_Type__c;
                    vfi.effectiveAt = vfp.Effective_At__c;
                    vfi.month = (Integer)vfp.Month__c;                
                    vfi.rate = vfp.Rate__c;
                    result.add(vfi);                
                }            
            }
        }
        return result;
    }
    public static void validateVariableRates(List<VariableRateInfo> vrInfos){
        if (!vrInfos.isEmpty()){
            Boolean isSequential = true;
            Boolean isValidMonth = true;
            Boolean isValidRate = true;
            for (Integer i=0; i < vrInfos.size(); i++){
                VariableRateInfo info1 = vrInfos[i];     
                if (info1.rate == null){
                    isValidRate = false;
                    break;
                }
                if (info1.periodStart == null && info1.periodEnd == null){
                    isValidMonth = false;
                    break;
                }                    
                if (info1.periodEnd == null && i < vrInfos.size()-1){
                    isValidMonth = false;
                    break;
                }                                    
                if (info1.periodStart != null && info1.periodEnd != null && info1.periodStart > info1.periodEnd){
                    isSequential = false;
                    break;
                }
                if (i > 0 && vrInfos[i].periodStart != (vrInfos[i-1].periodEnd+1)){                    
                    isSequential = false;
                    break;
                }
            }
            if (!isValidMonth){
                throw new AuraHandledException('Invalid month number');
            }
            if (!isValidRate){
                throw new AuraHandledException('Invalid rate value');
            }            
            if (!isSequential){
                throw new AuraHandledException('Invalid month number');
            }
        }
    }
    @AuraEnabled
    public static void saveVariableRates(String oppId, List<VariableRateInfo> vrInfos){
        System.debug(oppId);
        System.debug(vrInfos);
        validateVariableRates(vrInfos);
        if (!vrInfos.isEmpty() && vrInfos[vrInfos.size()-1].periodEnd != null){
            VariableRateInfo vrInfo = new VariableRateInfo();
            vrInfo.periodStart = vrInfos[vrInfos.size()-1].periodEnd + 1;
            vrInfo.rate = vrInfos[vrInfos.size()-1].rate; 
            vrInfos.add(vrInfo);
        }
        List<Variable_Rate__c> variableRates = [select Id from Variable_Rate__c where Opportunity__c=:oppId];
        delete variableRates;
        variableRates = new List<Variable_Rate__c>();
        for (Integer i = 0; i < vrInfos.size(); i++){
            VariableRateInfo vrInfo = vrInfos[i];
            Variable_Rate__c variableRate = new Variable_Rate__c();
            variableRate.Month_Start__c = vrInfo.periodStart;
            variableRate.Month_End__c = vrInfo.periodEnd;
            variableRate.Rate__c = vrInfo.rate;
            variableRate.Opportunity__c = oppId;            
            variableRates.add(variableRate);
        }        
        insert variableRates;
        InterestCalculator.calculateVariableRates(oppId);
    }
    
    @AuraEnabled
    public static void saveVariableFees(String oppId, List<VariableFeeInfo> vfInfos, Boolean onlyBOM){
        System.debug(oppId);
        System.debug(vfInfos);

        List<Variable_Fee__c> variableFees;
        variableFees = [select Id from Variable_Fee__c where Opportunity__c=:oppId and Is_BOM__c=:onlyBOM];
        delete variableFees;
        variableFees = new List<Variable_Fee__c>();
        for (Integer i = 0; i < vfInfos.size(); i++){
            VariableFeeInfo vfInfo = vfInfos[i];
            if (vfInfo.rate == null)
            	throw new AuraHandledException('Invalid rate value');
            if (vfInfo.effectiveAt == null)
            	throw new AuraHandledException('Invalid Effective At value');                        
            if (vfInfo.month == null && vfInfo.effectiveAt != 'Loan Setup')
            	throw new AuraHandledException('Invalid month number');
            if (vfInfo.feeType == null)                
            	throw new AuraHandledException('Invalid Fee Type value');            
            Variable_Fee__c variableFee = new Variable_Fee__c();
            variableFee.Month__c = vfInfo.month;
            variableFee.Effective_At__c = vfInfo.effectiveAt;
            variableFee.Rate__c = vfInfo.rate;
            variableFee.Fee_Type__c = vfInfo.feeType;
            variableFee.Opportunity__c = oppId;            
            variableFee.Is_Bom__c = onlyBOM;
            variableFees.add(variableFee);
        }        
        System.debug('saveVariableFees1');
        insert variableFees;
        System.debug('saveVariableFees2');
    }
    
    @AuraEnabled
    public static void createFees(String oppId, Boolean onlyBOM){
        SYstem.debug('createFees');
        if (!onlyBOM)
        	VariableFeeHelper.createFeesForOpp(oppId, onlyBOM);        
        else
            VariableFeeHelper.createBOMFeesForOpp(oppId);        
        InterestCalculator.calculateVariableRates(oppId);
    }
    

    public class VariableRateInfo{        
        @AuraEnabled
        public String id{get;set;}
        @AuraEnabled
        public Integer periodStart{get;set;}
        @AuraEnabled
        public Integer periodEnd{get;set;}
        @AuraEnabled
        public Decimal rate{get;set;}                
    }
    
    public class VariableFeeInfo{        
        @AuraEnabled
        public String id{get;set;}
        @AuraEnabled
        public Integer month{get;set;}
        @AuraEnabled
        public String effectiveAt{get;set;}
        @AuraEnabled
        public String feeType{get;set;}
        @AuraEnabled
        public Decimal rate{get;set;}                
    }        
}