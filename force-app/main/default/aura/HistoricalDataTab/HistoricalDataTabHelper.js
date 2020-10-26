({
    getHistoricalData : function(cmp, event, helper) {
 
        var action = cmp.get('c.searchHistoricalData');

        action.setParams({ recordId: cmp.get('v.recordId') })
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (state === 'SUCCESS') {
                console.log(response.getReturnValue());
                
                cmp.set('v.historicalData',response.getReturnValue());
                
                
                cmp.set('v.loadRecordForm',true) ;
                $A.get('e.force:refreshView').fire();                
            } else if (state === 'ERROR') {
                cmp.set('v.loadRecordForm',true) ;
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },
    errorsHandler: function(errors) {
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    unknownErrorsHandler: function() {
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error');
    },
})