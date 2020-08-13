({
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 10;
        //var min = year+'-01-01';
        var min = '2010-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    setDefaultTypeOfLoanAndBusinessUnit : function(component){
        let selectedTypeOfLoanFilter = [];
        selectedTypeOfLoanFilter.push({Id:"Facility Loan",Name:"Facility Loan"});
        component.set("v.selectedTypeOfLoanFilter", selectedTypeOfLoanFilter); 
        
        component.set("v.selectedBusinessUnitFilter", {Id:"ELFI",Name:"ELFI"});
    },
    setDefaultDates : function(component){
        return new Promise(function(resolve,reject){
            let dt = new Date();
            let customSetting = component.get('v.customSetting');  
            let defaultEndDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
            let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth()) +'-01';
            try{
                component.set("v.endDate", customSetting.End_Date__c == null ? defaultEndDate : customSetting.End_Date__c);
                component.set("v.startDate", customSetting.Start_Date__c == null ? defaultStartDate : customSetting.Start_Date__c); 
                
                resolve(true);
            }catch(e){
                reject(new Error('Not defined.'));                
            }  
        });
    },
    
    getPaymentsGroupByProvince : function(component){
        let typeofloanArr = this.getSelectedPickListValue(component, "", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let businessUnitArr = this.getSelectedPickListValue(component, "", component.find("businessUnitMS").get("v.selectedOptions"));
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getPaymentsGroupByProvince');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                BusinessUnit : businessUnitArr,
                typeOfLoan : typeofloanArr
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('The Records are:');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    
    getMultiSelectPickList : function(component, object, field, attributeId, selectedFilter){
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
                            Id: allValues[i].split('===SEPERATOR===')[0],
                            Name: allValues[i].split('===SEPERATOR===')[1],
                            selected : false
                        });
                    }
                    else
                    {
                        opts.push({
                            Id: allValues[i],
                            Name: allValues[i],
                            selected : false
                        });
                    }
                }
                for(let i=0; i<opts.length; i++){
                    for(let j=0; j< selectedFilter.length; j++){
                        if(opts[i].Name == selectedFilter[j].Name){
                            opts[i].selected = true;
                        }
                    }
                }                
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },
    getDrawdown : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getDrawdown');
            
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
    
    setCustomSettings : function(component){
        let typeofloanArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let businessUnitArr = this.getSelectedPickListValue(component, "'", component.find("businessUnitMS").get("v.selectedOptions"));
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveCustomSettings');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit : businessUnitArr,
                typeOfLoan : typeofloanArr
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('The start date and end date in custom settings have been updated.');
                    resolve(true);
                }else if(state === 'ERROR'){
                    console.log('The start date and end date in custom settings could not be updated.');
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    getCustomSettings : function(component){
        //get report dates from custom setting
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getCustomSetting');                
                action.setCallback(this,function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        console.log('1');
                        console.log(response.getReturnValue());
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
        var paymentData = component.get('v.paymentsByProvince');
        console.log('paymentData');
        console.log(paymentData);
        // calculate financial summary total for file and amount
        var fileTotal = 0;
        var opptyTotal = 0;
        var amountTotal = 0;
        
        for(var i = 0; i < paymentData.length; i++){
            fileTotal += paymentData[i].fileCount;
            opptyTotal += paymentData[i].opptyCount;
            amountTotal += paymentData[i].amount;
        }
        component.set("v.fileTotal", fileTotal); 
        component.set("v.opptyTotal", opptyTotal); 
        component.set("v.amountTotal", amountTotal);
    },
    
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    
    showToast : function(title, message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    getTypeofLoanPickList : function(component, object, field, attributeId){
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });
        picklistgetter.setCallback(this, function(response){
            var opts = [];
            let selectedTypeOfLoanFilter = component.get("v.selectedTypeOfLoanFilter");
            if(response.getState() == 'SUCCESS')
            {
                var allValues = response.getReturnValue();
                for (var i = 0; i < allValues.length; i++) {
                    if(allValues[i].includes('===SEPERATOR==='))
                    {
                        opts.push({
                            Id: allValues[i].split('===SEPERATOR===')[0],
                            Name: allValues[i].split('===SEPERATOR===')[1],
                            selected : false
                        });
                    }
                    else
                    {
                        opts.push({
                            Id: allValues[i],
                            Name: allValues[i],
                            selected : false
                        });
                    }
                }
                for(let i=0; i<opts.length; i++){
                    for(let j=0; j< selectedTypeOfLoanFilter.length; j++){
                        if(opts[i].Name == selectedTypeOfLoanFilter[j].Name){
                            opts[i].selected = true;
                        }
                    }
                }                
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },
    getSelectedPickListValue : function(component, quote, selectedOptions){
        let arr = [];
        for(let i=0; i<selectedOptions.length; i++){
            arr.push(quote + selectedOptions[i].Name + quote);
        }
        return arr;
    }
})