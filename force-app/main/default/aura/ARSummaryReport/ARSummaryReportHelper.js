({
	getCalendarMin : function(component){
        let min = '2010-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        let year = new Date().getFullYear() + 5;
        let max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    
    getPickListValues : function(component, object, field, attributeId){
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });

        picklistgetter.setCallback(this, function(response){
            var opts = [];
            if(response.getState() == 'SUCCESS')
            {
                var allValues = response.getReturnValue();
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
            }
        });
        $A.enqueueAction(picklistgetter);
    },
    
    getCustomSettings : function(component){
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getCustomSetting');                
                action.setCallback(this,function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        console.log('Custom settings');
                        console.log(JSON.stringify(response.getReturnValue()));
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    
    setDefaultDates : function(component){
        return new Promise(function(resolve,reject){
            let dt = new Date();
            let customSetting = component.get('v.customSetting');            
            let defaultEndDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
            let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-01';
            try{
                component.set("v.endDate", customSetting.End_Date__c == null ? defaultEndDate : customSetting.End_Date__c);
                component.set("v.startDate", customSetting.Start_Date__c == null ? defaultStartDate : customSetting.Start_Date__c); 
                resolve(true);
            }catch(e){
                reject([{message:'Failed to set default filter dates from custom settings.'}]);                
            }            
        });      
    },
    
    getReportByProvinceHelper : function (component){       
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getReportDataByProvince');  
                console.log('BU = ' + component.get('v.selectedBusinessUnitFilter'));
                action.setParams({
                    startDate:component.get('v.startDate'),
                    endDate:component.get('v.endDate'),
                    businessUnit: component.get('v.selectedBusinessUnitFilter'),
                    typeOfLoan : component.get('v.selectedTypeOfLoanFilter')
                });
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){						
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));        
    },
    
    calculateReportByProvinceData : function(component){
        var dataByProvince = component.get('v.dataByProvince');
        
        var fileTotal = 0;
        var opptyTotal = 0;
        var amountTotal = 0;
        for(var i = 0; i < dataByProvince.length; i++){
            fileTotal += dataByProvince[i].fileCount;
            opptyTotal += dataByProvince[i].opptyCount;
            amountTotal += dataByProvince[i].amount;
        }
        component.set("v.fileTotal", fileTotal); 
        component.set("v.opptyTotal", opptyTotal); 
        component.set("v.amountTotal", amountTotal);
    },
    
    getSummarizeReportData : function (component){
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getSummarizeData');
                action.setParams({
                    startDate:component.get('v.startDate'),
                    endDate:component.get('v.endDate'),
                    businessUnit: component.get('v.selectedBusinessUnitFilter'),
                    typeOfLoan: component.get('v.selectedTypeOfLoanFilter')
                });
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        console.log('#####RESULT#####');  
                        console.log(JSON.stringify(response.getReturnValue()));
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){                        
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));        
    },
    
    setCustomSettings : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveCustomSettings');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit : component.get('v.selectedBusinessUnitFilter'),
                typeOfLoan : component.get('v.selectedTypeOfLoanFilter')
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    resolve(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    
    showToast : function(title, message,type) {
        console.log("showToast");
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})