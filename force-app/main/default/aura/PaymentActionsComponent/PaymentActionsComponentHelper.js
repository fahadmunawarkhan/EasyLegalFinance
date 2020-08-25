({
	handleChange : function(component, value) {
        component.set('v.BadDebtCheck', (value == 'Bad Debt') ? true : false);
		var oppId = component.get('v.oppId');
        var paymentActionSelected = component.getEvent("paymentActionSelected");
        paymentActionSelected.setParams({
            action: value,
            oppId: oppId
        }).fire();        
        this.validate(component);
	},
    getOpportunityActions: function(component)
    {
        var oppId = component.get('v.oppId');
        var totalPayout = component.get('v.totalPayout');
        var tempPaymentReceived= component.get('v.tempPaymentReceived');
        var surplus = component.get('v.surplus');
        var stageStatus = component.get('v.stageStatus');
		var isStageStatusActive = (stageStatus == 'Active - Partial Payment' || stageStatus == 'Active' || stageStatus == 'Active - Collections');
        var stageName = component.get('v.stageName');
        var actions = new Array();
        var searchType = component.get('v.searchType');
        if (searchType == 'Payout' || searchType == 'Payout - Interest First'){
            if ( tempPaymentReceived != null && totalPayout != null && tempPaymentReceived != 0 && surplus != 0 && (tempPaymentReceived != totalPayout || surplus > 0) && isStageStatusActive){
                actions.push({label:'Partial Payment', value:'Partial Payment'});
            }
            else{
                if ((tempPaymentReceived == null ||  tempPaymentReceived == 0) && totalPayout != 0  && isStageStatusActive){
                    actions.push({label:'No Action', value:'No Action'});
                }
                if ( totalPayout != 0 && tempPaymentReceived != totalPayout && surplus < 0 && isStageStatusActive){
                    actions.push({label:'Bad Debt', value:'Bad Debt'});
                }
                if ( surplus == 0 && isStageStatusActive){
                    actions.push({label:'Closed Paid', value:'Closed Paid'});
                }
                if ( surplus > 0 && isStageStatusActive){
                    actions.push({label:'Surplus', value:'Surplus'});
                }
                if ( surplus < 0 && isStageStatusActive){
                    actions.push({label:'Shortfall', value:'Shortfall'});
                }
            }
        }
        else if (searchType == 'Bad Debt Recovery'){
            if (stageName == 'Closed With Loan' && (stageStatus == 'Closed - Paid' || stageStatus == 'Closed - Surplus' || stageStatus == 'Closed - Shortfall' || stageStatus == 'Closed - Bad Debt')){
                if (tempPaymentReceived != null && tempPaymentReceived > 0){                    
                    actions.push({label:'Bad Debt Recovery', value:'Bad Debt Recovery'});
                }
                else{                    
                    actions.push({label:'No Action', value:'No Action'});
            }
            }            
            
        }
        else if (searchType == 'Refund'){
            {
                if (tempPaymentReceived != null && tempPaymentReceived < 0){                    
                    actions.push({label:'Refund', value:'Refund'});
                }
                else{                    
                    actions.push({label:'No Action', value:'No Action'});
	            }
            }                        
        }        
        component.set('v.actions', actions);                        
    },
    selectSingleOption : function(component){
    	var actions = component.get('v.actions');
        console.log('Actions: ' + actions);
        if (actions != null && actions.length == 1){ 
            console.log('single ' +actions[0].value);
            component.set("v.value", '');
            component.set("v.value", actions[0].value);
            this.handleChange(component, actions[0].value);
        }
	},
    validate: function(component){
        var actions = component.get('v.actions');
        var valid = true;
        if (actions != null && actions.length > 0){
            var value = component.get('v.value');
            console.log('validation: ' + value);
            if (value == null || value == '')
                valid = false;
        }
        component.set('v.valid', valid);        
        var paymentActionValidated = component.getEvent("paymentActionValidated");
        var oppId = component.get('v.oppId');
        paymentActionValidated.setParams({            
            result: valid, 
            oppId: oppId
        }).fire();        
    },
    getPickListValues: function(component, object, field, attributeId)
    {
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });
        
        picklistgetter.setCallback(this, function(response){
            var opts = [];
            if(response.getState() == 'SUCCESS')
            {
                var allValues = response.getReturnValue();
                
                if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "--- None ---",
                        value: ""
                    });
                }
                for (var i = 0; i < allValues.length; i++) {
                    if(allValues[i].includes('===SEPERATOR==='))
                    {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i].split('===SEPERATOR===')[0],
                            value: allValues[i].split('===SEPERATOR===')[1]
                        });
                    }
                    else
                    {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i],
                            value: allValues[i]
                        });
                    }
                }
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    }
})