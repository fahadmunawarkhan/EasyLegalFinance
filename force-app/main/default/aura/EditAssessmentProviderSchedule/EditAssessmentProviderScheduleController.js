({
    doInit : function(component, event, helper){
        component.set("v.spinner", true);
        helper.isRebateAllowed(component).then(
            $A.getCallback(function(result) {
                console.log('-------');
                component.set("v.rebateAllowed", result);
                component.set("v.showForm", true);
                component.set("v.spinner", false);
            }),
            $A.getCallback(function(errors) {
                component.set("v.spinner", false);
                if (errors[0] && errors[0].message) {
                    helper.errorsHandler(errors)
                }else {
                    helper.unknownErrorsHandler();
                }
                
            }));

    },
    handleSubmit : function(component, event, helper){
        component.find('editform').submit();
    },
	handleSuccess : function(component, event, helper) {
        component.find('notifLib').showToast({
            "variant": "success",
            "title": "SUCCESS",
            "message": "Record Updated Successfully!!"
        });
        component.find("overlayLib").notifyClose();
	}
})