({
    getDuplicateAccounts : function(component) {
        console.log('getDuplicateAccounts');
        return new Promise($A.getCallback(
            function(resolve, reject){
                let action = component.get("c.getPotentialDuplicatesForAccount");

                action.setParams({
                    accountId : component.get('v.accountId')
                });

                action.setCallback(this, function(response){
                    let state = response.getState();
                    if (state === 'SUCCESS') {   
                        console.log('SUCCESS');
                        resolve(response.getReturnValue()); 
                    } else if (state === 'ERROR') {  
                        console.log('ERROR');
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    }
})