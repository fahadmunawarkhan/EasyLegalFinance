({
    doInit : function(component, event, helper) {
        component.set("v.spinner", true);
        
        component.set('v.columns', [
            {label: 'Assessment Provider', fieldName: 'linkProvider', type: 'url', typeAttributes: {label: { fieldName: 'Assessment_ProviderName' }, target: '_blank'}, sortable: true},
            {label: 'Discount', fieldName: 'discount', type: 'percent', typeAttributes:{minimumFractionDigits : '2'}, sortable: true},
            {label: 'Last Modified Date', fieldName: 'LastModifiedDate', type: 'date', cellAttributes: { alignment: 'right' }, typeAttributes:{ year : "numeric", month: "long", day:"2-digit"} ,sortable: true},
            {label: 'Last Modified By', fieldName: 'LastModifiedByName', type: 'text', sortable: true}
        ]);
        
        helper.getAssessmentSchedules(component).then(
            function(result){
                component.set("v.spinner", false);
                component.set("v.data", result);
                component.set("v.datatableIsSet", true);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(component, errors);
            }
        );
    },
    handleSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortData(component,sortBy,sortDirection);
    }
})