({
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