({
    getCalendarMin : function(component){
        
        var min = '2010-01-01';
        component.set("v.calendarMin", min);                
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    setDefaultTypeOfLoan : function(component){
        let selectedTypeOfLoanFilter = [];
        selectedTypeOfLoanFilter.push({Id:"Facility Loan",Name:"Facility Loan"});
        component.set("v.selectedTypeOfLoanFilter", selectedTypeOfLoanFilter);  
    },
    setDefaultBussinessUnit: function(component){
        let selectedBusinessUnitFilter = [];
        selectedBusinessUnitFilter.push({Id:"ELFI",Name:"ELFI"});
        component.set("v.selectedBusinessUnitFilter", selectedBusinessUnitFilter); 
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
                // component.set("v.selectedBusinessUnitFilter", customSetting.Business_Unit__c == null ? '' : customSetting.Business_Unit__c); 
                // component.set("v.selectedBusinessUnit", customSetting.Business_Unit__c == null ? '' : customSetting.Business_Unit__c); 
            	resolve(true);
            }catch(e){
                reject(new Error('Not defined.'));                
            }  
        });
    },
    
    getPaymentsGroupByProvince : function(component){
        let typeofloanArr = this.getSelectedPickListValue(component, "", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let businessunitArr = this.getSelectedPickListValue(component, "", component.find("businessunitMS").get("v.selectedOptions"));
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getPaymentsGroupByProvince');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit : businessunitArr,
                typeOfLoan : typeofloanArr
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
    
    getPartialPaymentsData : function(component){
        let typeofloanArr = this.getSelectedPickListValue(component, "", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let businessunitArr = this.getSelectedPickListValue(component, "", component.find("businessunitMS").get("v.selectedOptions"));
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getPartialPayments');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit : businessunitArr,
                typeOfLoan : typeofloanArr
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('Partial Payments.');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    setDateCustomSettings : function(component){
        console.log('+++++');
        let typeofloanArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let businessunitArr = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveDateCustomSettings');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit: businessunitArr,
                typeOfLoan : typeofloanArr
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('The start date and end date in custom settings have been updated.');
                    console.log(response.getReturnValue());
                }else if(state === 'ERROR'){
                    console.log('The start date and end date in custom settings could not be updated.');
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    getPickListValues : function(component, object, field, attributeId, selectedFilterValue){
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });
        picklistgetter.setCallback(this, function(response){
            var opts = [];
            let selectedFilter = component.get("v."+selectedFilterValue);
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
        // calculate financial summary total for file and amount
        var opptyTotal = 0;
        var fileTotal = 0;
        var amountTotal = 0;
        
        if(paymentData != undefined && paymentData != null) {   
            for(var i = 0; i < paymentData.length; i++){
                fileTotal += (paymentData[i].fileCount == null) ? 0 : paymentData[i].fileCount;
                opptyTotal += (paymentData[i].opptyCount == null) ? 0 : paymentData[i].opptyCount;
                amountTotal += (paymentData[i].amount == null) ? 0 : paymentData[i].amount;
            }
        }
        component.set("v.opptyTotal", opptyTotal); 
        component.set("v.fileTotal", fileTotal); 
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
    resetTotals : function(component, event, helper){
        component.set("v.accountTotalRhino", 0); 
        component.set("v.opptyTotalRhino", 0); 
        component.set("v.amountTotalRhino", 0.0); 
        component.set("v.accountTotalELFI", 0); 
        component.set("v.opptyTotalELFI", 0); 
        component.set("v.amountTotalELFI", 0.0);
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
    },
    validation : function(component, multiListId){
        const selectedTypeOfLoanOptions = component.find(multiListId).get("v.selectedOptions");
        let msgidentifier = '';
        return new Promise($A.getCallback(
            function(resolve, reject){
                if(selectedTypeOfLoanOptions.length >= 1){
                    resolve(true);
                }else{
                    msgidentifier = (multiListId == 'typeOfLoanMS')? 'type of loan' : 'business unit';
                    reject([{message: 'Please select at least one '+msgidentifier+' filter from dropdown.'}]);
                }
            })
        );
    }
})