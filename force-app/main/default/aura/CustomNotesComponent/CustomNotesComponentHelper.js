({
    getEnhancedNotes: function(component) {

        // ********************* GET ACCOUNT RECORD DETAILS ********************* //
        var recordId = component.get("v.recordId");
        var action = component.get('c.getEnhancedNotes');
        action.setParams({ accountId: recordId })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set("v.notes", response.getReturnValue());
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
    getObjectName : function(component){
        var recordId = component.get("v.recordId");
        var action = component.get('c.getObjectName');
        action.setParams({ ObjId: recordId })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set("v.ObjName", response.getReturnValue());
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
    getCurrentUser: function(component) {
        var action = component.get('c.getCurrentUserInfo');

        action.setCallback(this, function(response) {
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
    updateNote: function(component, event) {
        let selectedId = component.get("v.selectedNoteId");

        return new Promise($A.getCallback(function(resolve, reject){
            var updatenotes = component.get('c.updateContentNotes');
            updatenotes.setParams({
                cnoteId: selectedId, 
                body: component.get("v.noteContent")
            });
            updatenotes.setCallback(this, function(response){
                if(response.getState() == 'SUCCESS')
                {
                    component.set("v.selectedNoteId", "");
                    component.set('v.showNotePopup', false);
                    component.set("v.spinner", false);
                    resolve(true);
                } else if (state === 'ERROR') {
                    reject(true);
                }
            });
            $A.enqueueAction(updatenotes);
        }));
    },
    deleteNote: function(component, event) {
        let selectedId = event.target.id;
        let action = component.get('c.delContentNote');
        action.setParams({ cnoteId: selectedId })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                this.showToast('SUCCESS', 'Note is deleted successfully!', 'SUCCESS');
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
        component.set("v.spinner", false);
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
    errorsHandler: function(errors) {
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    unknownErrorsHandler: function() {
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error');
    }
})