({
	doinit : function(component, event, helper) {
        component.set('v.OpportunityAssessmentColumns', [
            {label: 'Opportunity Name', fieldName: 'Name', type: 'text', sortable: true},
            {label: 'Principal Repaid', fieldName: 'Principal_Repaid_Roll_up__c', type: 'currency', sortable: true},
            {label: 'Assessment Fee', fieldName: 'Admin_Fee_Roll_up__c', type: 'currency', sortable: true},
            {label: 'Total', fieldName: 'Total', type: 'currency', sortable: true}
        ]);
        helper.OppoAssessHelper(component).then($A.getCallback(
            function(result){
                
                for (var i = 0; i < result.length; i++) {
                    var row = result[i];
                    row.Total = row.Principal_Repaid_Roll_up__c + row.Admin_Fee_Roll_up__c;
                }
                console.log(result);
                component.set("v.OpportunityAssessmentdata", result);
                component.set("v.spinner", false);
                component.set("v.setdatatable", true);
            }
        )).catch(
            function(errors){
                console.log(errors);
            }
        );
	},
    handleAssessmentSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortAssessmentData(component,sortBy,sortDirection);
    }
})