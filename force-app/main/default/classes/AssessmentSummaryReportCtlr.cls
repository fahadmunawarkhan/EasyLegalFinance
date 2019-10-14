public with sharing class AssessmentSummaryReportCtlr {
    
    public class AssessmentWrapper{
        @AuraEnabled
        public string lawyer {get; set;}
        @AuraEnabled
        public string lawyerId {get; set;}
        @AuraEnabled
        public string firm {get; set;}
        @AuraEnabled
        public string firmId {get; set;}
        @AuraEnabled
        public decimal approvedCredit {get; set;}
        @AuraEnabled
        public decimal utilizedCreditElfi {get; set;}
        @AuraEnabled
        public decimal utilizedCreditRhino {get; set;}
        @AuraEnabled
        public decimal availableCredit {get; set;}

        public AssessmentWrapper(){
            lawyer = '';
            lawyerId = '';
            firm = '';
            firmId = '';
            approvedCredit = 0;
            utilizedCreditElfi = 0;
            utilizedCreditRhino = 0;
            availableCredit = 0;

        }
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static Assessment_Summary_Report__c getCustomSetting(){
        Assessment_Summary_Report__c aSR = Assessment_Summary_Report__c.getOrgDefaults();
        return aSR;
    }

    @AuraEnabled 
    public static Drawdown__c getDrawdown(){
        List<Drawdown__c> congaUrlHolder = [Select Conga_Assessment_Summary_Report_View_All__c,
                                            Conga_Assessment_Summary_Report_Print__c
                                            from Drawdown__c limit 1];
        return congaUrlHolder[0];
    }

    @AuraEnabled
    public static void setCustomSetting(String BusinessUnit){
        Assessment_Summary_Report__c aSR = Assessment_Summary_Report__c.getOrgDefaults();
        aSR.Business_Unit__c = !String.isEmpty(BusinessUnit) && BusinessUnit != null? BusinessUnit : 'ELFI';
        upsert aSR;
    }
    
    @AuraEnabled 
    public static List<AssessmentWrapper> getAssessmentData(String searchByName, String BusinessUnit, String field, String direction){
        
        List<Opportunity> assessmentOpps = new List<Opportunity>();
        Map<String, AssessmentWrapper> lawyerAssessmentMap = new Map<String, AssessmentWrapper>();
        try{
            
            String filterByBusinessUnit = '';
            string Rhino = 'Rhino';
            string Elfi = 'ELFI';
            String assessment = 'Assessment';
            
            if(BusinessUnit == 'ELFI'){                
                filterByBusinessUnit = 'ELFI';
            }else if(BusinessUnit == 'Rhino'){                
                filterByBusinessUnit = 'Rhino';
            }else if(BusinessUnit == 'Consolidated'){                
                filterByBusinessUnit = 'Consolidated';
            }
            
            String strQuery = '';            
            strQuery = 'SELECT Id, Lawyer__c, Lawyer__r.Name, Law_Firm__c, Law_Firm__r.Name, Lawyer__r.Approved_Credit_Limit__c,';
            strQuery += ' Drawdown_Total_wo_Payment__c, Account.Business_Unit__c, Principal_Repaid_Roll_up__c, Admin_Fee_Roll_up__c';
            strQuery += ' FROM Opportunity';
            strQuery += ' WHERE Type_of_Loan__c =:assessment';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? 
                ' AND (Account.Business_Unit__c =:Elfi OR Account.Business_Unit__c =:Rhino)':
            ' AND Account.Business_Unit__c =:filterByBusinessUnit';            
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Lawyer__r.Name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Law_Firm__r.Name LIKE \'%' + searchByName + '%\')'  : '';
            strQuery += ' order by ' + field + ' ' + direction + ' NULLS LAST';
            
            system.debug('Query');
            system.debug(strQuery);
            
            assessmentOpps = Database.query(strQuery);
                        
            

            if(!assessmentOpps.isEmpty()){
                String key = '';
                
                for(Opportunity opp : assessmentOpps){
                    key = opp.Lawyer__c + '-' + opp.Law_Firm__c;
                    AssessmentWrapper wrapper = null;
                    if(!lawyerAssessmentMap.containsKey(key))
                        lawyerAssessmentMap.put(key, new AssessmentWrapper());
                    
                    wrapper = lawyerAssessmentMap.get(key);
                    wrapper.lawyerId =  opp.Lawyer__c;
                    wrapper.lawyer = opp.Lawyer__r.Name;
                    wrapper.firm = opp.Law_Firm__r.Name;
                    wrapper.firmId = opp.Law_Firm__c;
                    wrapper.approvedCredit = opp.Lawyer__r.Approved_Credit_Limit__c != null? opp.Lawyer__r.Approved_Credit_Limit__c : 0;
                    
                    Decimal principalRepaidAmnt = opp.Principal_Repaid_Roll_up__c;
                    Decimal drawdownTotalAmntWoPymnt = opp.Drawdown_Total_wo_Payment__c;
                    //Drawdown_Total_wo_Payment__c
                    
                    wrapper.utilizedCreditElfi += opp.Account.Business_Unit__c == 'ELFI'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0  : 0;
                    wrapper.utilizedCreditElfi += opp.Account.Business_Unit__c == 'ELFI'? opp.Admin_Fee_Roll_up__c !=null? opp.Admin_Fee_Roll_up__c :0 : 0;
                    
                    wrapper.utilizedCreditElfi -= opp.Account.Business_Unit__c == 'ELFI'? principalRepaidAmnt != null? principalRepaidAmnt : 0  : 0;
                    
                    wrapper.utilizedCreditRhino += opp.Account.Business_Unit__c == 'Rhino'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0 : 0;
                    wrapper.utilizedCreditRhino += opp.Account.Business_Unit__c == 'Rhino'? opp.Admin_Fee_Roll_up__c !=null? opp.Admin_Fee_Roll_up__c :0 : 0;
                    
                    wrapper.utilizedCreditRhino -= opp.Account.Business_Unit__c == 'Rhino'? principalRepaidAmnt != null? principalRepaidAmnt : 0  : 0;
                    
                    lawyerAssessmentMap.put(key, wrapper);
                }
            }
            if(!lawyerAssessmentMap.isEmpty()){

                for(String key : lawyerAssessmentMap.keySet()){
                    AssessmentWrapper wrapper = lawyerAssessmentMap.get(key);
                    wrapper.availableCredit = wrapper.approvedCredit - (wrapper.utilizedCreditElfi + wrapper.utilizedCreditRhino);
                    lawyerAssessmentMap.put(key, wrapper);
                }
        
            }
            
        }catch(Exception e){
            system.System.debug(e.getMessage() + ' ' + e.getLineNumber());
            system.System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getLineNumber());
        }

        setCustomSetting(BusinessUnit);
        return lawyerAssessmentMap.values();
    }
}