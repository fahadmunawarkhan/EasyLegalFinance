({
    doInit : function(component, event, helper) {
        
        var section = 'duplicateRecordsSection';
        var expandedSections = component.get('v.expandedSections') || {};
        expandedSections[section] = true;
        component.set('v.expandedSections', expandedSections);
        
        helper.getDuplicateAccounts(component).then(
            function(result){
                console.log('result');
                console.log(result);
                component.set("v.duplicateRecords", result);
                component.set("v.recordsFound", (result != null && result.length > 0) ? true : false);
            }
        ).catch(
            function(errors){
                console.log('ERRORS');
                console.log(errors);
            }
        );
    },
    toggleSection: function(component, event, helper){
        var section = event.currentTarget.getAttribute('data-section');
        var expandedSections = component.get('v.expandedSections') || {};
        expandedSections[section] = !expandedSections[section];
        component.set('v.expandedSections', expandedSections);
    },
})