({
	getCalendarMin : function(component){
        var year = new Date().getFullYear() - 5;
        //var min = year+'-01-01';
        var min = '2010-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    
    getPickListValues : function(component, object, field, attributeId){
        return new Promise($A.getCallback(function(resolve, reject){
            
            var picklistgetter = component.get('c.getPickListValues');
            picklistgetter.setParams({
                objectType: object,
                field: field
            });
            
            
            picklistgetter.setCallback(this, function(response){
                var opts = [];
                console.log('picklist recieved with status: '+response.getState());
                if(response.getState() == 'SUCCESS')
                {
                    var allValues = response.getReturnValue();
                    console.log('picklist recieved with values: '+JSON.stringify(response.getReturnValue()));
                    /*if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "All",
                        value: "All"
                    });
                }*/
                for (var i = 0; i < allValues.length; i++) {
                    if(allValues[i].includes('===SEPERATOR==='))
                    {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i].split('===SEPERATOR===')[0],
                            value: allValues[i].split('===SEPERATOR===')[1]
                        });
                    }
                    else
                    {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i],
                            value: allValues[i]
                        });
                    }
                }
                opts.push({
                    class: "optionClass",
                    label: 'Consolidated',
                    value: 'Consolidated'
                });                
                component.set('v.'+attributeId, opts);
                resolve(opts);
            }
        });
            $A.enqueueAction(picklistgetter);
            
        }));
        
    }
})