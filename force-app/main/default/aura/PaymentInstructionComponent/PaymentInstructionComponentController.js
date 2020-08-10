({
	doInit : function(component, event, helper) {        
		console.log(component.get("v.paymentInfo"));
	},
    copyAsRichText : function(component, event, helper){
		helper.copyAsRichText(component, event);
    },
    sendEmail : function(component, event, helper){
		helper.sendEmail(component)
        .then(
            (result) => {
                helper.showToast('SUCCESS','Email sent!','SUCCESS');
            },
            (error) => {
                console.log(error);
            }                
        );
    }    
})