({
	doInit : function(component, event, helper) {        
		helper.getOpportunityActions(component);
        var oppId = component.get('v.oppId');
        helper.handleChange(component, '');
		helper.selectSingleOption(component);
		helper.getPickListValues(component, 'Opportunity', 'Bad_Debt_Reason__c', 'BadDebtReasons');
	},
    handleChange : function(component, event, helper){
    	helper.handleChange(component, event.getParam('value'));
	},
    
})