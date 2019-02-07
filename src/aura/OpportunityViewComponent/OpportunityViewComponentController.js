({
	doInit : function(component, event, helper) {
		helper.getOpportunityInfo(component);
        helper.getDrawdownList(component);
        helper.getServiceProvidersList(component);
        helper.getReAssessmentOpportunitiesList(component);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component); 
        helper.getSingleContactHistory(component);
        helper.getPickListValues(component, 'Service_Provider_Drawdown__c','Reference_Notes__c','providerRefNotesOptions');
        helper.getPickListValues(component, 'Service_Provider_Drawdown__c','Payment_Method__c','providerPaymentMethod');
        helper.getPickListValues(component, 'Drawdown__c','Reference_Notes__c','refNotesOptions');
        helper.getPickListValues(component, 'Drawdown__c','Payment_Method__c','paymentMethod');
        helper.getPickListValues(component, 'Drawdown__c','Type__c','drawdownType');
        helper.getPickListValues(component, 'Opportunity','Loan_Status__c','LoanStatusOptions');
        helper.getPickListValues(component, 'Opportunity','Loan_Type__c','incidentTypeOptions');
        helper.getPickListValues(component, 'Opportunity','StageName','stageOptions');
        helper.getPickListValues(component, 'Opportunity','Stage_Status__c','statusOptions');
        helper.getPickListValues(component, 'Opportunity','Type_of_Loan__c','loanTypeOptions');
        helper.getPickListValues(component, 'Opportunity','Interest_Compounding_Period__c','interestCompoundingPeriod');
        helper.getPickListValues(component, 'Opportunity','Compounding_Interest__c','compoundingInterest');
        helper.getPickListValues(component, 'Opportunity','Fee_Calculation_Method__c','feeCalculationMethod');
        helper.getPickListValues(component, 'Opportunity','Minimum_Interest_Period__c','minimumInterestPeriod');
        helper.getPickListValues(component, 'Opportunity','Fixed_Amount__c','fixedAmount');
        helper.getPickListValues(component, 'Opportunity','Payment_Date__c','paymentDateOptions');
        helper.getPickListValues(component, 'Opportunity','Existing_Litigation_Loans__c','paymentScheduleOptions');
        helper.getPickListValues(component, 'Opportunity','Loan_Requests__c','loanRequestOptions');
        helper.getPickListValues(component, 'Opportunity','StageName','ReAssessmentStageOptions');        
        helper.getPickListValues(component, 'Opportunity_Service_Provider__c','Status__c','treatmentStatusOptions');
        helper.getPickListValues(component, 'Opportunity', 'Interest_Deferral_Period__c', 'interestDeferralOptions');
        
        // get the fields API name and pass it to helper function  
        var controllingFieldAPI = component.get("v.controllingFieldAPI");        
        var dependingFieldAPI = component.get("v.dependingFieldAPI");
        var objDetails = component.get("v.objDetail");        
        helper.fetchPicklistValues(component,objDetails,controllingFieldAPI, dependingFieldAPI);  
        //console.log('listControllingValues' + component.get("v.listControllingValues")); 
        helper.getRefNotesDependantPicklistMap(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
        helper.getRefNotesDependantPicklistMap(component, 'providerDrawDownObj', 'providerReferenceNotesDepPicklistMap'); 
        setTimeout(function(){
            //helper.fetchTreatmentRefNotesDepValues(component);
        },3000);
	},
    
    onControllerFieldChange: function(component, event, helper) { 
        
        var controllerValueKey = event.getSource().get("v.value"); // get selected controller field value
        var depnedentFieldMap = component.get("v.depnedentFieldMap");
        
        console.log(controllerValueKey);        
        if (controllerValueKey != '--- None ---') {
            var ListOfDependentFields = depnedentFieldMap[controllerValueKey];
            
            console.log(ListOfDependentFields);
            
            if(ListOfDependentFields.length > 0){
                component.set("v.bDisabledDependentFld" , false);                 
                helper.fetchDepValues(component, ListOfDependentFields, 'listDependingValues');    
            }else{
                component.set("v.bDisabledDependentFld" , true); 
                component.set("v.listDependingValues", ['--- None ---']);
            }  
            
        } else {
            component.set("v.listDependingValues", ['--- None ---']);
            component.set("v.bDisabledDependentFld" , true);
        }
    },    
    
    saveOpp : function(component, event, helper){
        var success;
        
        
        success = helper.validateRequired(component, "Name");
        if(!success)	return;
        
        success = helper.validateRequired(component, "selectedLookUpPrimaryContact");
        if(!success)	return;
        
        component.set("v.spinner", true);
        helper.saveOppty(component);
    } ,
    
    saveDrawdowns : function(component, event, helper){
        component.set("v.spinner", true);
        helper.saveDrawdowns(component);
    },
    
    addNewDrawdown : function(component, event, helper){
        try{
            component.set("v.spinner", true);
            
            helper.saveDrawdowns(component);
            helper.addNewDrawdown(component);  
        }catch(e){
            
        }
        //helper.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
    },
    
    onTypeOfLoanChange: function(component, event, helper){
        component.set("v.spinner", true);    
        //helper.getRefNotesDependantPicklistMap(component);
        helper.getRefNotesDependantPicklistMap(component, 'drawDownObj', 'referenceNotesDepPicklistMap'); 
        component.set("v.spinner", false);    
        document.getElementsByTagName('body')[0].focus();
    },
    
    deleteDrawdownItem : function(component, event, helper){
        component.set("v.spinner", true);
		var itemDescription = event.target.getElementsByClassName('drawdown-item-id')[0].value;           
        
		if(confirm('Are you sure?')) {
            try{
                helper.deleteDrawdownItem(component, itemDescription); 
            }catch(e){
                
            }
            //helper.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');            
            
            
        } else {
            component.set("v.spinner", false);
        	return false;
        }
    },
    
    deleteServiceProviderDrawdownItem : function(component, event, helper){
        component.set("v.spinner", true);
		var itemDescription = event.target.getElementsByClassName('drawdown-item-id')[0].value;           
        
		if(confirm('Are you sure?')) {            
            helper.deleteServiceProviderDrawdownItem(component, itemDescription); 
            helper.fetchTreatmentRefNotesDepValuesAsync(component);
        } else {
            component.set("v.spinner", false);
        	return false;
        }
    },    
    
    deleteReassessment : function(component, event, helper){
        component.set("v.spinner", true);
		var itemDescription = event.target.getElementsByClassName('reassess-item-id')[0].value;           
        
		if(confirm('Are you sure?')) {            
            helper.deleteReassessment(component, itemDescription);            
        } else {
            component.set("v.spinner", false);
        	return false;
        }
    },
    
    addNewServiceProvider : function(component, event, helper){
    	var firm = component.get("v.selectedLookUpServiceProvider");
        helper.addTreatment(component, firm);
    },
    
    addNewServiceProviderDrawdown : function(component, event, helper){
        component.set("v.spinner", true);
		var itemDescription = event.target.getElementsByClassName('treatment-insert-id')[0].value; 
        helper.saveDrawdowns(component);
        helper.addNewServiceProviderDrawdown(component, itemDescription);    
        helper.fetchTreatmentRefNotesDepValuesAsync(component);
    },
    
    deleteTreatment : function(component, event, helper){
        component.set("v.spinner", true);
		var itemDescription = event.target.getElementsByClassName('treatment-delete-id')[0].value;           
        
		if(confirm('Are you sure?')) {            
            helper.deleteTreatment(component, itemDescription);            
        } else {
            component.set("v.spinner", false);
        	return false;
        }
    },    
    
    saveReassessments : function(component, event, helper){
        component.set("v.spinner", true);
        helper.saveReassessments(component);
    },

	saveServiceProvidersList : function(component, event, helper){
        component.set("v.spinner", true);
        helper.saveServiceProvidersList(component); 
        //alert('refreshing');
        //helper.fetchTreatmentRefNotesDepValuesAsync(component);
    },
    
    redirectUserToStandardView : function (component, event, helper){
        // Redirect to the default Opportunity Lightning Page
        var recordId = component.get("v.recordId");        
        var url = "/lightning/r/Opportunity/" + recordId + "/view?nooverride=1";
        window.location.href = url;
    },
    
    doCancel : function(component, event, helper){
        var accountId = component.get("v.accountId");
        var url = "/lightning/r/Account/" + accountId + "/view";
        window.location.href = url;
    },
    
    doRefresh : function(component, event, helper){
        window.location.reload();
    },
    
    doDelete : function(component, event, helper){
		component.set("v.spinner", true);
        
        if(confirm('Are you sure?')) {            
        	helper.deleteOpportunity(component);
            //helper.getOpportunityInfo(component);
            // Redirect to Account Record
            //var a = component.get('c.doCancel');
        	//$A.enqueueAction(a);         
        } else {
            component.set("v.spinner", false); 
			return false;            
        }      
	},
    generateLoanDocuments: function(component, event, helper)
    {
        var currentOppSObj = component.get('v.oppObj');
        if (currentOppSObj.Generate_Loan_Doc_Check__c==true){
            
            window.open(currentOppSObj.Conga_URL_Doc_Generate__c, "_parent","width=650,height=250,menubar=0");
        }
        else{
            //alert(currentOppSObj.Conga_Doc_Error__c.replace('[ButtonName]', 'Generate Loan Documents').replace(/\\n/g, '\n'));
            helper.showToast('ERROR', currentOppSObj.Conga_Doc_Error__c.replace('[ButtonName]', 'Generate Loan Documents').replace(/\\n/g, '\n'));
        }
    },
    SendLoanDocuments: function(component, event, helper)
    {
        var currentOppSObj = component.get('v.oppObj');
        if (currentOppSObj.Send_Loan_Doc_Check__c==true){
            window.open(currentOppSObj.Conga_URL_Doc_Send__c, "_parent","width=650,height=250,menubar=0");
        }
        else{
            //alert(currentOppSObj.Conga_Doc_Error__c.replace('[ButtonName]', 'Send Loan Documents').replace(/\\n/g, '\n'));
            helper.showToast('ERROR', currentOppSObj.Conga_Doc_Error__c.replace('[ButtonName]', 'Send Loan Documents').replace(/\\n/g, '\n'));
        } 
    },
    onPaymentMethodChange: function(component, event, helper)
    {
        var index = event.target.nextElementSibling.dataset.index;
        var newPaymentMethod = event.getSource().get("v.value");
        console.log('index:'+index);
        console.log('newPaymentMethod:'+newPaymentMethod);
        helper.fetchRefNotesDepValues(component, newPaymentMethod, index);
    },
    onPaymentMethodChangeTreatment: function(component, event, helper)
    {
        helper.fetchTreatmentRefNotesDepValues(component);
    },
    inlineEditName : function(component,event,helper){       
        var clickSource = event.currentTarget.dataset.source;
        // show the name edit field popup 
        
        component.set("v.clickSource", clickSource); 
        var selectedRecVar = event.currentTarget.dataset.recvar;
        console.log('var:'+selectedRecVar)
        if(selectedRecVar){
            component.set("v."+selectedRecVar,{});
            console.log('nullfied');
        }
        
        // after the 100 millisecond set focus to input field   
        setTimeout(function(){ 
            try
            {
            	component.find(clickSource).focus();
                component.find(clickSource).click();
            }
            catch(e){ }
        }, 100);
    },
    hideLookupInput : function(component, event, helper) {	
        
        component.set("v.clickSource", "none");   
        var oppObjId = component.get("v.oppObj.Id");
        if(oppObjId){
            component.set("v.spinner", true);
            helper.saveOppty(component);
        }
    }
})