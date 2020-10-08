({
    retriveUnderwriterHistoryDefault : function(component, event, helper) {
        return new Promise($A.getCallback(function(resolve, reject){
            var Historygetter = component.get('c.UnderwriterEvaluationHistory');
            Historygetter.setParams({
                AccountId : component.get("v.recordId")
            });
            Historygetter.setCallback(this, function(response){
                if(response.getState() == 'SUCCESS')
                {
                    var HistoryResponse = response.getReturnValue();
                    console.log(HistoryResponse);
                    var result = response.getReturnValue();
                    component.set("v.HistoryList", result);
                    resolve(response.getReturnValue());
                } else {
                    reject(Historygetter.getError());
                }
            });
            $A.enqueueAction(Historygetter);
        }));
    },

    showToast : function(component, event, helper, title, msg, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type" : type,
            "message": msg
        });
        toastEvent.fire();
    }
})