({
    doInit : function(component, event, helper) {
        helper.retriveUnderwriterHistoryDefault(component, event, helper).then($A.getCallback(
            function(result){
                component.set("v.spinner", false);
        })).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.showToast(component, event, helper, 'ERROR!', errors['message'], 'ERROR');
            }
        );
    }
})