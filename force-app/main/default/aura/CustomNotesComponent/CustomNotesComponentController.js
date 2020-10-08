({
    doInit : function(component, event, helper) {
        component.set("v.spinner", true);
        helper.getEnhancedNotes(component);
        helper.getCurrentUser(component);
        helper.getObjectName(component);
        component.set("v.spinner", false);
    },
    newNote: function(component, event, helper) {
        component.set('v.noteContent', '');
        component.set('v.showNotePopup', true);
    },
    closeNoteModal: function(component, event, helper) {
        component.set("v.selectedNoteId", '');
        component.set('v.showNotePopup', false);
    },
    editNote: function(component, event, helper) {
        component.set("v.spinner", true);
        let notes = component.get("v.notes");
        let selectedId = event.target.id;


        for (let i = 0; i < notes.length; i++) {
            if (notes[i].note.Id == selectedId) {
                component.set("v.noteContent", notes[i].body);
                component.set("v.selectedNoteId", notes[i].note.Id);
                component.set('v.showNotePopup', true);
                component.set("v.spinner", false);
                break;
            }
        }
        component.set("v.spinner", false);
    },
    createNote: function(component, event, helper) {
        component.set("v.createButtonDisabled", true);
        //getting the candidate information
        //var candidate = component.get("v.note");
        var candidate = component.get("v.noteContent");
        //Calling the Apex Function
        var action = component.get("c.createRecord");
        //Setting the Apex Parameter
        action.setParams({
            nt: candidate,
            PrentId: component.get("v.recordId")
        });
        //Setting the Callback
        action.setCallback(this, function(a) {
            //get the response state
            var state = a.getState();
            //check if result is successfull
            if (state == "SUCCESS") {
                //Reset Form
                var newCandidate = {'sobjectType': 'ContentNote',
                    'Title': 'N/A',
                    'Content': ''
                };
                //resetting the Values in the form
                component.set("v.note", newCandidate);
                //$A.get('e.force:refreshView').fire();
                component.set('v.showNotePopup', false);
                helper.getEnhancedNotes(component);
                component.set("v.spinner", false);
                component.set("v.createButtonDisabled", false);
            } else if (state == "ERROR") {
                var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.errorsHandler(errors)
                    }
                } else {
                    helper.unknownErrorsHandler();
                }
                component.set("v.spinner", false);
                component.set("v.createButtonDisabled", false);
            }
        });

        //adds the server-side action to the queue        
        $A.enqueueAction(action);
        component.set("v.spinner", true);
    },
    updateNote: function(component, event, helper) {
        component.set("v.spinner", true);

        helper.updateNote(component, event).then($A.getCallback(
            function(result){
                helper.getEnhancedNotes(component);
                helper.showToast('SUCCESS', 'Note is updated successfully!', 'SUCCESS');
                component.set("v.spinner", false);
        })).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.showToast('ERROR', errors, 'ERROR');
            }
        );
    },
    deleteNote: function(component, event, helper) {
        if (confirm('Are you sure?')) {
            try {
                component.set("v.spinner", true);
                helper.deleteNote(component, event);
                helper.getEnhancedNotes(component);
                component.set('v.showNotePopup', false);
                component.set("v.spinner", false);
            } catch (e) {

            }
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    NotesPrintView: function(component, event, helper) {
        window.open("/apex/AccountNotesPrintable?Id="+component.get("v.recordId"));
    }
})