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
        @AuraEnabled
        public Boolean checked {get; set;}
        @AuraEnabled
        public String attachmentId{get; set;}

        public AssessmentWrapper(){
            lawyer = '';
            lawyerId = '';
            firm = '';
            firmId = '';
            approvedCredit = 0;
            utilizedCreditElfi = 0;
            utilizedCreditRhino = 0;
            availableCredit = 0;
            checked = false;
            attachmentId = '';

        }
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static Assessment_Summary_Report__c getCustomSetting(){
        Assessment_Summary_Report__c aSR = Assessment_Summary_Report__c.getInstance(UserInfo.getUserId());
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
    public static void setCustomSetting(String BusinessUnit, String searchByName){
        Assessment_Summary_Report__c aSR = Assessment_Summary_Report__c.getInstance(UserInfo.getUserId());
        aSR.Business_Unit__c = !String.isEmpty(BusinessUnit) && BusinessUnit != null? BusinessUnit : 'ELFI';
        aSR.Search_by_Name__c = !String.isEmpty(searchByName) && searchByName != null? searchByName : '';        
        upsert aSR;
    }
    
    @AuraEnabled 
    public static List<AssessmentWrapper> getAssessmentData(String searchByName, String BusinessUnit, String field, String direction){
        
        List<Opportunity> assessmentOpps = new List<Opportunity>();
        Set<Id> lawyersIdSet = new Set<Id>();
        Map<String, AssessmentWrapper> lawyerAssessmentMap = new Map<String, AssessmentWrapper>();
        Map<String,String> lawyersAttachmentsMap = new Map<String,String>();

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

            for(Opportunity opp : assessmentOpps){
                lawyersIdSet.add(opp.lawyer__c);
            }

            //query to retrive attached payout attachements
            if(!lawyersIdSet.isEmpty()){
                for(Attachment attach : [SELECT Id, ParentId FROM Attachment Where ParentId In :lawyersIdSet
                                        AND name like '%List of Clients%' 
                                        AND createddate = today order by createddate desc]){
                    if(!lawyersAttachmentsMap.containsKey(attach.ParentId))
                        lawyersAttachmentsMap.put(attach.ParentId, attach.Id);
                }
            }            
            

            if(!assessmentOpps.isEmpty()){
                String key = '';
                
                for(Opportunity opp : assessmentOpps){
                    key = opp.Lawyer__c + '-' + opp.Law_Firm__c;
                    AssessmentWrapper wrapper = null;
                    if(!lawyerAssessmentMap.containsKey(key))
                        lawyerAssessmentMap.put(key, new AssessmentWrapper());

                    
                    
                    wrapper = lawyerAssessmentMap.get(key);

                    wrapper.attachmentId = '';

                    if(lawyersAttachmentsMap.containsKey(opp.Lawyer__c))
                        wrapper.attachmentId = '' + lawyersAttachmentsMap.get(opp.Lawyer__c);
                    
                    wrapper.lawyerId =  opp.Lawyer__c;
                    wrapper.lawyer = opp.Lawyer__r.Name;
                    wrapper.firm = opp.Law_Firm__r.Name;
                    wrapper.firmId = opp.Law_Firm__c;
                    wrapper.approvedCredit = opp.Lawyer__r.Approved_Credit_Limit__c != null? opp.Lawyer__r.Approved_Credit_Limit__c : 0;
                    
                    Decimal principalRepaidAmnt = opp.Principal_Repaid_Roll_up__c;
                    Decimal drawdownTotalAmntWoPymnt = opp.Drawdown_Total_wo_Payment__c;
                    //Drawdown_Total_wo_Payment__c
                    
                    wrapper.utilizedCreditElfi += opp.Account.Business_Unit__c == 'ELFI'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0  : 0;
                    //wrapper.utilizedCreditElfi += opp.Account.Business_Unit__c == 'ELFI'? opp.Admin_Fee_Roll_up__c !=null? opp.Admin_Fee_Roll_up__c :0 : 0;
                    
                    wrapper.utilizedCreditElfi -= opp.Account.Business_Unit__c == 'ELFI'? principalRepaidAmnt != null? principalRepaidAmnt : 0  : 0;
                    
                    wrapper.utilizedCreditRhino += opp.Account.Business_Unit__c == 'Rhino'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0 : 0;
                    //wrapper.utilizedCreditRhino += opp.Account.Business_Unit__c == 'Rhino'? opp.Admin_Fee_Roll_up__c !=null? opp.Admin_Fee_Roll_up__c :0 : 0;
                    
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

        setCustomSetting(BusinessUnit, searchByName);
        return lawyerAssessmentMap.values();
    }

     /******************* Method to generate the payout balance *********************/
    public static void generatePayoutBalance(Date payoutDate, String businessUnitFilter, String ids){
        try{

            String assessment = 'Assessment';
            String paidOff = 'Paid Off';

            String strQueryOpportunity = '';
            strQueryOpportunity = 'SELECT Id, Name, Payout_Date__c, Lawyer__c';
            strQueryOpportunity += ' FROM Opportunity';
            strQueryOpportunity += ' WHERE Type_of_Loan__c =:assessment';
            strQueryOpportunity += ' AND isClosed = true AND isWon = true';
            strQueryOpportunity += ' AND Stage_Status__c !=:paidOff';            
            strQueryOpportunity += (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? 
                ' AND Account.Business_Unit__c =:businessUnitFilter': '';
            if(!String.isEmpty(ids))
                strQueryOpportunity += ' AND Lawyer__c in (' + ids +')';

            List<Opportunity> opportunities = Database.query(strQueryOpportunity);

            for(Opportunity opp : opportunities){
                opp.Payout_Date__c = payoutDate;
            }
            
            if(!opportunities.isEmpty())
                update opportunities;

        }catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static Id generate(List<String> selectedIds, String payoutDate, String reportDate, String businessUnitFilter){
        try{
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;        
            String ids = '';
            String query = '';
            String assessment = 'Assessment';            

            if(!selectedIds.isEmpty()) {
                ids = String.Join(selectedIds,',');
                query = 'select id from contact WHERE Id in ('+ ids +')';
            }else{
                query = 'SELECT Id FROM contact where id in (SELECT lawyer__c from opportunity WHERE Type_of_Loan__c = :assessment)';
            }
            
            Assessment_Summary_Report__c customSettings = Assessment_Summary_Report__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
            customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
            customSettings.Business_Unit__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';

            generatePayoutBalance(customSettings.Payout_Date__c, customSettings.Business_Unit__c, ids);
            
            if(String.isEmpty(customSettings.Conga_Conductor_Id__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Assessment Lawyer query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of assessment loan summary for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Assessment Lawyer - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Loans_Lawyer__c');
                insert conductor;            
                customSettings.Conga_Conductor_Id__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conga_Conductor_Id__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Loans_Lawyer__c';
                update conductor;
                congaQuery.APXTConga4__Query__c = query;
                update congaQuery;
            }
            upsert customSettings;
            return conductor.id;	
        }
        catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }
}