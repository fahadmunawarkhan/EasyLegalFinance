({
	getCurrentUser : function(component) {
		var action = component.get('c.getCurrentUserInfo');         
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
				component.set("v.currentUser", response.getReturnValue());                
            } else if (state === 'ERROR') {
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
    parseNavigationHash : function(component) {
        if (window.location.hash) {
            var hash = window.location.hash.split('/');
            if (hash.length > 1) {
                component.set("v._selectedTabId", hash[1]);
                if (hash.length > 2) {
                    component.set("v._selectedSecondaryTabId", hash[2]);
                }
            }
        }
    }
})