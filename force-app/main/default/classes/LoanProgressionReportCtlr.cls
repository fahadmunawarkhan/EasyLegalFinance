public with sharing class LoanProgressionReportCtlr {
    public class FinancialYear {
        
        @AuraEnabled
        Public String Year; 
        
        @AuraEnabled
        public Decimal totalAdvanceLoanAmountElfi;
        @AuraEnabled
        public Decimal totalAdvanceLoanAmountRhino;
        @AuraEnabled
        Public Decimal totalLoanLosesAmountElfi;
        @AuraEnabled
        Public Decimal totalLoanLosesAmountRhino;
        
        @AuraEnabled
        Public Integer totalNumberOfLoansElfi;
        @AuraEnabled
        Public Integer totalNumberOfLoansRhino;
        
        @AuraEnabled
        Public Decimal lossesPercentageElfi;
        @AuraEnabled
        Public Decimal lossesPercentageRhino;
        
        @AuraEnabled        
        Public List<FinancialQuarter> quarters;
        
        public FinancialYear(){
            totalAdvanceLoanAmountElfi = 0;
            totalAdvanceLoanAmountRhino = 0;
            totalLoanLosesAmountElfi = 0;
            totalLoanLosesAmountRhino = 0;
            totalNumberOfLoansElfi = 0;
            totalNumberOfLoansRhino = 0;
            lossesPercentageElfi = 0;
            lossesPercentageRhino = 0;
            quarters = new List<FinancialQuarter>();
            
        }
        
        
    }
    
    Public class FinancialQuarter{
        @AuraEnabled
        Public String Quarter;
        
        @AuraEnabled
        Public Decimal elfiAdvanceLoanAmount;        
        @AuraEnabled
        Public Integer elfiNumberOfLoans;
        @AuraEnabled
        Public Decimal elfiLoanLosesAmount;
        @AuraEnabled
        Public Integer elfiNumberOfLoanLoses;
        
        @AuraEnabled
        Public Decimal rhinoAdvanceLoanAmount;        
        @AuraEnabled
        Public Integer rhinoNumberOfLoans;
        @AuraEnabled
        Public Decimal rhinoLoanLosesAmount;
        @AuraEnabled
        Public Integer rhinoNumberOfLoanLoses;
    }
    
    @AuraEnabled
    public static List <String> getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static FinanceLoanProgression__c getCustomSettings(){
        FinanceLoanProgression__c fLP = FinanceLoanProgression__c.getOrgDefaults();
        return fLP;        
    }
    
    @AuraEnabled
    public static void saveCustomSettings(String startDate, String endDate, String businessUnit){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            FinanceLoanProgression__c flp = FinanceLoanProgression__c.getOrgDefaults();
            
            flp.End_date__c = endDt;
            flp.Start_Date__c = startDt;
            flp.Business_Unit__c = businessUnit;
            
            upsert flp; 
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<FinancialYear> getProgressionReportData(String startDate, String endDate, string BusinessUnit)
    {
        List<FinancialYear> result = new List<FinancialYear>();
        try{
            
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = '';
            string eTransfer = 'e-Transfer';
            string Cheque = 'Cheque';
            string AdminFee = 'Admin Fee';
            String ClosedWithLoan = 'Closed With Loan';
            String active = 'Active'; 
            String activePartial = 'Active - Partial Payment';
            String closedPaid = 'Closed - Paid';
            String closedSurplus = 'Closed - Surplus';
            String closedShortfall = 'Closed - Shortfall';
            String closedBadDebt = 'Closed - Bad Debt';
            String badDebt = 'Bad Debt';
            
            
            strQuery += 'SELECT CALENDAR_YEAR(Date__c) year, CALENDAR_QUARTER(Date__c) quarter,';
            strQuery += ' COUNT_Distinct(Opportunity__c) loans, Sum(Amount__c) amt, Opportunity__r.Account.Business_Unit__c unit';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
            strQuery += ' OR (Payment_Method__c =:Cheque)';
            strQuery += ' OR (Payment_Method__c =:AdminFee))';
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:active OR Opportunity__r.Stage_Status__c =:activePartial';
            strQuery += ' OR Opportunity__r.Stage_Status__c =:closedPaid OR Opportunity__r.Stage_Status__c =:closedSurplus';
            strQuery += ' OR Opportunity__r.Stage_Status__c =:closedShortfall OR Opportunity__r.Stage_Status__c =:closedBadDebt)';
            strQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
            strQuery += ' Group by CALENDAR_YEAR(Date__c), CALENDAR_QUARTER(Date__c), Opportunity__r.Account.Business_Unit__c';
            strQuery += ' order by CALENDAR_YEAR(Date__c), CALENDAR_QUARTER(Date__c) NULLS LAST';
            
            List<AggregateResult> aggResultAdvances = Database.query(strQuery);
            
            
            //Loan losses
            //Stage status = bad debt
            strQuery = 'SELECT CALENDAR_YEAR(Date__c) year, CALENDAR_QUARTER(Date__c) quarter,';
            strQuery += ' COUNT_Distinct(Opportunity__c) loans, Sum(Amount__c) amt, Opportunity__r.Account.Business_Unit__c unit';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt';
            strQuery += ' AND Date__c <= :endDt'; 
            //strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
            //strQuery += ' OR (Payment_Method__c =:Cheque)';
            //strQuery += ' OR (Payment_Method__c =:AdminFee))';
            //strQuery += ' AND Opportunity__r.Stage_Status__c =:closedBadDebt';
            strQuery += ' AND Reference_Notes__c =:badDebt';
            strQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
            strQuery += ' Group by CALENDAR_YEAR(Date__c), CALENDAR_QUARTER(Date__c), Opportunity__r.Account.Business_Unit__c';
            strQuery += ' order by CALENDAR_YEAR(Date__c), CALENDAR_QUARTER(Date__c) NULLS LAST';
            
            List<AggregateResult> aggResultLosses = Database.query(strQuery);
            Set<String> years = new Set<String>();
            List<String> quarters = new List<String>();
           
            Map<String, AggregateResult> aggrMapAdvances = new Map<String,AggregateResult>();            
            if(!aggResultAdvances.isEmpty()){                
                for(AggregateResult res : aggResultAdvances){
                    String key = res.get('year') + '-' + res.get('quarter') + '-' + (String)res.get('unit');
                    aggrMapAdvances.put(key, res);
                    years.add('' + res.get('year'));
                    
                    if(!quarters.contains('' + res.get('quarter')))
                        quarters.add('' + res.get('quarter'));
                }
            }
            
            Map<String, AggregateResult> aggrMapLosses = new Map<String, AggregateResult>();
            if(!aggResultLosses.isEmpty()){                
                for(AggregateResult res : aggResultLosses){
                    String key = res.get('year') + '-' + res.get('quarter') + '-' + (String)res.get('unit');
                    aggrMapLosses.put(key, res);
                    years.add('' + res.get('year'));
                    
                    if(!quarters.contains('' + res.get('quarter')))
                        quarters.add('' + res.get('quarter'));
                }
            }
            
            quarters.sort();
            
            Map<String,List<FinancialQuarter>> financialQuarterList = new Map<String,List<FinancialQuarter>>();
            FinancialYear financialYear;
            if(!years.isEmpty()){
                List<FinancialQuarter> fQuarterList = new List<FinancialQuarter>();
                for(String year : years){
                    financialYear = new FinancialYear();
                    fQuarterList.clear();
                    financialYear.Year = year;
                    for(String quarter : quarters){
                        String key = year + '-' + quarter;
                        
                        FinancialQuarter fQuarter = new FinancialQuarter();
                        fQuarter.Quarter = 'Q' + quarter;
                        
                        // ELFI 
                        fQuarter.elfiAdvanceLoanAmount = aggrMapAdvances.containsKey(key + '-ELFI') ? Double.valueOf(aggrMapAdvances.get(key + '-ELFI').get('amt')) : 0;
                        fQuarter.elfiNumberOfLoans = aggrMapAdvances.containsKey(key + '-ELFI') ? Integer.valueOf(aggrMapAdvances.get(key + '-ELFI').get('loans')) : 0;
                        fQuarter.elfiLoanLosesAmount = aggrMapLosses.containsKey(key + '-ELFI') ? Double.valueOf(aggrMapLosses.get(key + '-ELFI').get('amt')) : 0;
                        fQuarter.elfiNumberOfLoanLoses = aggrMapLosses.containsKey(key + '-ELFI') ? Integer.valueOf(aggrMapLosses.get(key + '-ELFI').get('loans')) : 0;
                        
                        // Rhino 
                        fQuarter.rhinoAdvanceLoanAmount = aggrMapAdvances.containsKey(key + '-Rhino') ? Double.valueOf(aggrMapAdvances.get(key + '-Rhino').get('amt')) : 0;
                        fQuarter.rhinoNumberOfLoans = aggrMapAdvances.containsKey(key + '-Rhino') ? Integer.valueOf(aggrMapAdvances.get(key + '-Rhino').get('loans')) : 0;
                        fQuarter.rhinoLoanLosesAmount = aggrMapLosses.containsKey(key + '-Rhino') ? Double.valueOf(aggrMapLosses.get(key + '-Rhino').get('amt')) : 0;
                        fQuarter.rhinoNumberOfLoanLoses = aggrMapLosses.containsKey(key + '-Rhino') ? Integer.valueOf(aggrMapLosses.get(key + '-Rhino').get('loans')) : 0;
                        
                        fQuarterList.add(fQuarter);
                        
                        financialYear.totalAdvanceLoanAmountElfi += fQuarter.elfiAdvanceLoanAmount;
                        financialYear.totalAdvanceLoanAmountRhino += fQuarter.rhinoAdvanceLoanAmount;
                        financialYear.totalLoanLosesAmountElfi += fQuarter.elfiLoanLosesAmount;
                        financialYear.totalLoanLosesAmountRhino += fQuarter.rhinoLoanLosesAmount;
                        financialYear.totalNumberOfLoansElfi += fQuarter.elfiNumberOfLoans;
                        financialYear.totalNumberOfLoansRhino += fQuarter.rhinoNumberOfLoans;
                        
                    }  
                    
                    financialYear.lossesPercentageElfi = (financialYear.totalLoanLosesAmountElfi / (financialYear.totalAdvanceLoanAmountElfi > 0? financialYear.totalAdvanceLoanAmountElfi : 1 ));
                    financialYear.lossesPercentageRhino = (financialYear.totalLoanLosesAmountRhino / (financialYear.totalAdvanceLoanAmountRhino > 0? financialYear.totalAdvanceLoanAmountRhino : 1 ));
                    financialYear.quarters.addAll(fQuarterList);
                    result.add(financialYear);
                }
            }
            
            
        }catch(Exception e){
            system.debug('exception ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
        saveCustomSettings(startDate, endDate, BusinessUnit);
        return result;
        
    }
    @AuraEnabled
    public static list<Drawdown__c> getDrawdownCongaURLs(){
        
        list<Drawdown__c> drawdown_conga_url = [select id, Conga_Finance_Loan_Progression_View_All__c, Conga_Finance_Loan_Progression_Print_All__c
                                                from Drawdown__c limit 1];
        return drawdown_conga_url;
    }

}