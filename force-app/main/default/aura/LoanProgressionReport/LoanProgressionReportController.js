({
	doInit : function(component, event, helper) {
		component.set("v.spinner", true);
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        
        component.set("v.spinner", false);
	},
    filterButton : function(component, event, helper){
        
    }
})