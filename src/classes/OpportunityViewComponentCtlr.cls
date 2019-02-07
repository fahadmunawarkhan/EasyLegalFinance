public class OpportunityViewComponentCtlr {

    public static Opportunity oppInfo {get;set;}
    public static List<Drawdown__c> drawDownList {get;set;}   
    
    /******************* Method to return all details from the opportunity *********************/
    @AuraEnabled
    public static Opportunity getOpportunityDetails(String oppId, String accId) {
       system.debug(oppid + '  '  + accId);
        oppInfo = new Opportunity();
        if(String.isEmpty(oppId))
        {
            List<Opportunity> lastOppty = [select id, Lawyer__c, Law_Firm__c, Date_Financing_Statement_Done__c ,
                                           Date_Financing_Statement_Expires__c
                                           from Opportunity
                                           where AccountId = :accId
                                           order by Opportunity_Long_Name__c limit 1];
            oppInfo.Name = ''; 
            oppInfo.StageName='Prospecting';
            oppInfo.closeDate = Date.today(); 
            oppInfo.AccountId=accId;
            oppInfo.Minimum_Interest_Period__c = '6 months';
            oppInfo.Fee_Calculation_Method__c = 'Fixed Amount';
            
            User currentUser = [Select Id, Name from User where id=:userinfo.getUserId()];
            oppInfo.Owner = currentUser;
            oppInfo.OwnerId = currentUser.Id;
            oppInfo.Lawyer__c = (lastOppty.isEmpty() ? null : lastOppty[0].Lawyer__c);
            oppInfo.Law_Firm__c = (lastOppty.isEmpty() ? null : lastOppty[0].Law_Firm__c);
            oppInfo.Date_Financing_Statement_Done__c = (lastOppty.isEmpty() ? null : lastOppty[0].Date_Financing_Statement_Done__c);
            oppInfo.Date_Financing_Statement_Expires__c = (lastOppty.isEmpty() ? null : lastOppty[0].Date_Financing_Statement_Expires__c);
        }
        else
        {
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            
            // Adding some extra related field information
            lstFields.add('Assigned_To__r.Name');
            lstFields.add('Primary_Contact__r.Name');
            lstFields.add('Owner.Name');
            lstFields.add('Law_Firm__r.Name');
            lstFields.add('Lawyer__r.Name');
            lstFields.add('Scenario__r.Name');
            
            // Building the query
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ' FROM Opportunity WHERE Id =: oppId';
            
            // Still need to handle exceptions
            oppInfo = Database.query(strQuery);   
        }
        system.debug('## oppInfo: ' + oppInfo);        
        return oppInfo;
    }
    
    /******************* Method to get dependent picklist values *********************/
    @AuraEnabled
    public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
    	return DependentPicklistCtrl.getDependentMap(objDetail, contrfieldApiName, depfieldApiName);   
    }     
    
    /******************* Method to get contact history of the account *********************/
	@AuraEnabled
    public static Contact_History__c getContactHistory(String accountId) {
        Contact contact = CustomerViewComponentCtlr.getLastContact(accountId);        
        Contact_History__c contactHistory = new Contact_History__c();
        if(contact != null){
            contactHistory = CustomerViewComponentCtlr.getContactHistorySingle(contact.Id);
        }
        return contactHistory;
    }
    
    /******************* Method to get the drawdowns list *********************/
    @AuraEnabled
    public static List<Drawdown__c> getDrawdownList(String oppId) {
        drawDownList = new List<Drawdown__c>();
        
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Drawdown__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }

        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Drawdown__c WHERE Opportunity__c =: oppId order by Name';
        
        // Still need to handle exceptions
        drawDownList = Database.query(strQuery);        
        system.debug('## drawDownList: ' + drawDownList);        
        return drawDownList;        
    }
    
    /******************* Method to save opportunity *********************/
    @AuraEnabled
    public static Opportunity saveOpportunity(Opportunity opportunity){
        try {
            system.debug('opportunity Compounding_Interest__c: ' + opportunity.Compounding_Interest__c);
            upsert opportunity;  
            
            List<OpportunityContactRole> roles = [Select id, OpportunityId, ContactId , isPrimary
                                                  FROM OpportunityContactRole
                                                  WHERE OpportunityId = :opportunity.Id AND
                                                  ContactId = :opportunity.Primary_Contact__c];
            OpportunityContactRole upsertable;
            if(!roles.isEmpty())		upsertable = roles[0];
            if(upsertable != null)
            {
                if(upsertable.IsPrimary == false)
                {
                    upsertable.IsPrimary = true;
                    upsert upsertable;
                }
            }
            else
            {
                upsertable = new OpportunityContactRole(OpportunityId = opportunity.Id, 
                                                        ContactId = opportunity.Primary_Contact__c,
                                                        isPrimary = true);
                upsert upsertable;
            }
            
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
            
        return opportunity;
    }    
    
    /******************* Method to save drawdowns list *********************/
    @AuraEnabled
    public static void saveNewDrawdownList(List<Drawdown__c> drawDownNewList){
        try{
            update drawDownNewList;
        }catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }
    
    /******************* Method to insert a new drawdown *********************/
    @AuraEnabled
    public static List<Drawdown__c> insertNewDrawdown(List<Drawdown__c> currentDrawdownList, String oppId){
        try{
            Drawdown__c drawdown = new Drawdown__c(Opportunity__c=oppId);            
            insert drawdown;
            DrawdownTriggerHandler.mergeAdminFeeWithFirstDrawdown(new Set<Id>{oppId});
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }

        List<Drawdown__c> tempList = getDrawdownList(oppId);
        currentDrawdownList.add(tempList[tempList.size()-1]);
        return currentDrawdownList; 
    }
    
    /******************* Method to insert a new service provider drawdown *********************/
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> insertNewServiceProviderDrawdown(String oppId, String serviceId) {

        Drawdown__c newDrawdown = new Drawdown__c(
            Opportunity_Service_Provider__c = serviceId,
            Type__c = 'Treatment Loan',
            Amount__c = 0,
            Opportunity__c = oppId,
            Date__c= Date.today()
        );
        try{
            insert newDrawdown;
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }

        return getServiceProviders(oppId);
    }    
    
    /******************* Method to delete a drawdown item *********************/
    @AuraEnabled
    public static List<Drawdown__c> deleteDrawdownRecord(String drawdownId, String oppId){
        try{
            Drawdown__c dd = new Drawdown__c(Id=drawdownId);
            delete dd; 
        }
        catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        return getDrawdownList(oppId);
    }
    
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> deleteServiceProviderDrawdownRecord(String drawdownId, String oppId){
        Drawdown__c dd = new Drawdown__c(Id=drawdownId);
        try{
            delete dd;        
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        return getServiceProviders(oppId);
    }    
    
    @AuraEnabled
    public static List<Opportunity> deleteReassessments(String reassessmentsId, String oppId){
        try{
            deleteOpp(reassessmentsId);   
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        return getReAssessmentOpportunities(oppId);
    }  
    
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> deleteTreatmentItem(String treatmentId, String oppId){
		Opportunity_Service_Provider__c svc = new Opportunity_Service_Provider__c(Id=treatmentId);  
        try{
            delete svc;
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        return getServiceProviders(oppId);
    } 

    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> addTreatmentItem(String oppId, Account firm){
        if(firm != null){
            system.debug('Opp Id ' + oppId + ' Firm Id ' + firm.Id);
            Opportunity_Service_Provider__c svc = new Opportunity_Service_Provider__c(Opportunity__c=oppId, Service_Provider_Facility__c=firm.Id);   
            try{
                insert svc;
            } catch (DMLException e){
                throw new AuraHandledException('Error:'+e.getDmlMessage(0));
            } catch (Exception e){
                throw new AuraHandledException('Error:'+e.getMessage());
            }            
        } else {
        	throw new AuraHandledException('Please select the firm before adding a new service provider.'); 
        }
		
        return getServiceProviders(oppId);
    }    
    
    @AuraEnabled
    public static void saveReassessmentsList(List<Opportunity> reAssessmentList){
        try{
            update reAssessmentList;
        }
        catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }    
    
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> getServiceProviders(String oppId){                             
        List<Opportunity_Service_Provider__c> spList = new List<Opportunity_Service_Provider__c>();
        
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity_Service_Provider__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Adding some extra related field information
        lstFields.add('Service_Provider_Facility__r.Name');
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        
        strQuery += ', (SELECT Id, Name, Amount__c, Date__c, CreatedDate, Payment_Method__c, Reference_Notes__c, CHQ__c, EFT__c'+
                     ' FROM Drawdowns__r' +
                     ' ORDER BY Date__c DESC)';
        strQuery += ' FROM Opportunity_Service_Provider__c WHERE Opportunity__c =: oppId ORDER BY CreatedDate DESC';
        system.debug('strQuery' + strQuery);
        // Still need to handle exceptions
        spList = Database.query(strQuery);        
        system.debug('## spList: ' + spList);        
        return spList;
                             
    }
    
    @AuraEnabled
    public static List<Opportunity> getReAssessmentOpportunities(String oppId){
        List<Opportunity> rOppList = new List<Opportunity>();      
        
        // Building the query
        String strQuery = 'SELECT Id, Name, Amount, CloseDate, StageName,Funding_Requested__c, NextStep';
        strQuery += ' FROM Opportunity WHERE Re_Assessed_Loan__c =: oppId ORDER BY CloseDate DESC';
        
        // Still need to handle exceptions
        rOppList = String.isEmpty(oppId) ? null : Database.query(strQuery);        
        system.debug('## rOppList: ' + rOppList);        
        return rOppList;                                     
    }
    
    @AuraEnabled
    public static void deleteOpp(String oppId){
        try{
            if(oppId != null){
                Opportunity opp = new Opportunity(Id=oppId);
                delete opp;
            }
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> saveProvidersList(String jsonStr, String oppId){
        try {
            List<Opportunity_Service_Provider__c> providers = (List<Opportunity_Service_Provider__c>)JSON.deserialize(jsonStr, List<Opportunity_Service_Provider__c>.class);
            update providers;            
            system.debug('providers: ' + providers);
            
            // collect drawdowns
            List<Drawdown__c> updateDrawdowns = new List<Drawdown__c>();
            for(Opportunity_Service_Provider__c sp: providers){
                system.debug('sp.Drawdowns__r ' + sp.Drawdowns__r);
                if (sp.Drawdowns__r.size() > 0) {
                    updateDrawdowns.addAll(sp.Drawdowns__r);
                }
            }
            system.debug('@@ updateDrawdowns' + updateDrawdowns);
            
            if (updateDrawdowns.size() > 0) {
                update updateDrawdowns;
            }
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        
        return getServiceProviders(oppId);
    }  
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        List < String > allOpts = new List < String > ();
        // Get the object type of the SObject.
        Schema.sObjectType objType = Schema.getGlobalDescribe().get(objectType);
        
        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Get a map of fields for the SObject
        map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
        
        // Get the list of picklist values for this field.
        list < Schema.PicklistEntry > values =
            fieldMap.get(field).getDescribe().getPickListValues();
        
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a: values) {
            allOpts.add( a.getLabel() +'===SEPERATOR==='+ a.getValue());
            //allOpts.add( a.getValue());
        }
        system.debug('allOpts ---->' + allOpts);
        //allOpts.sort();
        return allOpts;
    }
}