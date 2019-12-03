({
	isRebateAllowed : function(component){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let action = component.get("c.rebateIsAllowed");
                action.setParams({
                    lookupId : component.get("v.recordIdParam"),
                    selectedLookup : "recordId"
                });

                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state == 'SUCCESS'){
                        resolve(response.getReturnValue());
                    }else if(state == 'ERROR'){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
	},
	errorsHandler : function(component, errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast(component, 'Error', errors[0].message);
        }
    },
    
    showToast : function(component, title, message, type) {
        component.find('notifLib').showToast({
            "variant": type,
            "title": title,
            "message": message
        });
    },
})