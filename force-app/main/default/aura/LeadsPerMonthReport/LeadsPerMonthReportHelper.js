({
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 5;
        //var min = year+'-01-01';
        var min = '1980-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 10;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    setDefaultBussinessUnit: function(component){
        let selectedBusinessUnitFilter = [];
        selectedBusinessUnitFilter.push({Id:"ELFI",Name:"ELFI"});
        component.set("v.selectedBusinessUnitFilter", selectedBusinessUnitFilter); 
    },
	getLeadsByMonth : function(component) {
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "");
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getLeadsByMonth');
                action.setParams({
                    startDate : component.get('v.startDate'),
                    endDate : component.get('v.endDate'),
                    businessUnit : businessunitArr
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
    
    getSampleLead : function(component) {
        let action = component.get('c.getSampleLead');
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){    
                component.set('v.sampleLead', response.getReturnValue());
            }else if(state === 'ERROR'){
                helper.errorsHandler(response.getError());
            }
        });
        $A.enqueueAction(action);
        
    },
    
    calculateTotal : function(component){
        let leads = component.get('v.LeadsByMonth');
        let totalAmount = 0.00;
        let totalRecordCount = 0;
        let totalConvertedLeads = 0;
        
        for(let i=0; i<leads.length; i++){
            totalAmount += leads[i].SumofAmountPaidtoClient;
            totalRecordCount += leads[i].RecordCount;
            totalConvertedLeads += leads[i].SumofConvertedLeads;
        }
        component.set('v.totalAmountPaidtoClient',totalAmount);
        component.set('v.totalRecords',totalRecordCount);
        component.set('v.totalConverted',totalConvertedLeads);
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
            console.log('test===>>');
        console.log(opts);
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
                component.set("v.selectedBusinessUnit", customSetting.Business_Unit__c == null ? '' : customSetting.Business_Unit__c); 
                resolve(true);
            }catch(e){
                reject(new Error('Not defined.'));                
            }  
        });
    },
    setCustomSettings : function(component){
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "'");
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveCustomSettings');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit: businessunitArr
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('The start date and end date in custom settings have been updated.');
                    console.log(response.getReturnValue());
                    resolve(true);
                }else if(state === 'ERROR'){
                    console.log('The start date and end date in custom settings could not be updated.');
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    getSelectedBusinessUnitArr : function(component, quote){
        let selectedBusinessUnitOptions = component.find("businessunitMS").get("v.selectedOptions");
        let businessUnitArr = [];
        for(let i=0; i<selectedBusinessUnitOptions.length; i++){
            businessUnitArr.push(quote + selectedBusinessUnitOptions[i].Name + quote);
        }
        return businessUnitArr;
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