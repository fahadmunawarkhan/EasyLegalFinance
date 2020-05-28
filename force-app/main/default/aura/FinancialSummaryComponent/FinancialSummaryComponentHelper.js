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
    setDateCustomSettings : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveDateCustomSettings');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                typeOfLoan : component.get('v.selectedTypeOfLoanFilter')
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
    setDefaultDates : function(component){
        return new Promise(function(resolve,reject){
            let dt = new Date();
            let customSetting = component.get('v.customSetting');            
            let defaultEndDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
            let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-01';
            try{
                component.set("v.sinceInception", customSetting.Since_Inception__c);
                component.set("v.endDate", customSetting.End_Date__c == null ? defaultEndDate : customSetting.End_Date__c);
                component.set("v.startDate", customSetting.Start_Date__c == null ? defaultStartDate : customSetting.Start_Date__c); 
                component.set("v.adhocAsOfDate", customSetting.Adhoc_as_of_Date__c == null ? '' : customSetting.Adhoc_as_of_Date__c);
            	resolve(true);
            }catch(e){
                reject([{message:'Failed to set default filter dates from custom settings.'}]);                
            }            
        });      
    },
    
    getCustomSettings : function(component){
        //get report dates from custom setting
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getCustomSetting');                
                action.setCallback(this,function(response){
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
            }
        });
        $A.enqueueAction(picklistgetter);
    },
    
    setBUCustomSettings : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveBusinessUnitCustomSettings');
            action.setParams({
                BusinessUnit : component.get('v.selectedBusinessUnitFilter'),
                typeOfLoan : component.get('v.selectedTypeOfLoanFilter')
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    
    executeBatchJob : function (component){
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.executeBatchJob');
                action.setParams({
                    sinceInception : component.get('v.sinceInception'),
                    startDate: component.get('v.startDate'),
                    endDate: component.get('v.endDate'),
                    typeOfLoan: component.get('v.selectedTypeOfLoanFilter'),
                    adhocAsOfDate: component.get('v.adhocAsOfDate')
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
            }
        ));
    },  
    
    getFinancialReportData : function (component){
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getFinancialReportData');
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
    
    validateReport : function(component) {
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.validateReport');
                action.setParams({
                    startDate:component.get('v.startDate'),
                    endDate:component.get('v.endDate'),
                    typeOfLoan: component.get('v.selectedTypeOfLoanFilter'),
                    adhocAsOfDate : component.get('v.adhocAsOfDate')
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
            }
        ));
    },
    
    pingForBatchJobStatus : function(component){
        console.log('pinging...');
        let self = this;
        let intervalId = window.setInterval(
            $A.getCallback(function() { 
                $A.enqueueAction(component.get('c.setBatchJobStatus'));
                //self.getBatchJobStatus(component);
            }), 5000
        );        
        component.set('v.intervalId', intervalId);
    },
    
    getBatchJobStatus : function (component){        
        return new Promise($A.getCallback(
            function(resolve,reject){                
                let action = component.get('c.getBatchJobStatus');
                action.setCallback(this,function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        //component.set('v.apexBatchJobOBJ', response.getReturnValue());
                        //self.updateProgress(component);
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    
    updateProgress : function (component){
        return new Promise(function(resolve, reject){
            let apexBatchJobOBJ = component.get('v.apexBatchJobOBJ');
            if(apexBatchJobOBJ != null){
                component.set('v.batchJobStatus',apexBatchJobOBJ.Status);
                component.set('v.batchJobProgress',0);
                component.set('v.batchJobItems', ' '+ 0 + '%');
                component.set('v.batchTotalJobItems', apexBatchJobOBJ != null? apexBatchJobOBJ.TotalJobItems : 0);
            	component.set('v.batchJobItemsProcessed', apexBatchJobOBJ != null? apexBatchJobOBJ.JobItemsProcessed : 0);
                if(apexBatchJobOBJ.Status == 'Processing' || apexBatchJobOBJ.Status == 'Completed'){
                    component.set('v.batchJobProgress',(apexBatchJobOBJ.JobItemsProcessed/(apexBatchJobOBJ.TotalJobItems!=0? apexBatchJobOBJ.TotalJobItems : 1))*100);
                    component.set('v.batchJobItems', ' '+ parseFloat((apexBatchJobOBJ.JobItemsProcessed/(apexBatchJobOBJ.TotalJobItems!=0? apexBatchJobOBJ.TotalJobItems : 1))*100).toFixed(0) + '%');
                    component.set('v.batchTotalJobItems', apexBatchJobOBJ.TotalJobItems);
                    component.set('v.batchJobItemsProcessed', apexBatchJobOBJ.JobItemsProcessed);
                }
            }
            if(apexBatchJobOBJ.Status == 'Completed'){
                component.set('v.batchJobProgress',100);
                component.set('v.batchJobItems', ' '+ 100 + '%');
                //$A.enqueueAction(component.get('c.getRecords'));                  
                resolve(true);
            }else{
                resolve(false);
            }
            
        });
    },
    
    getReportByProvinceHelper : function (component){       
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getReportDataByProvince');                
                action.setParams({
                    startDate:component.get('v.startDate'),
                    endDate:component.get('v.endDate'),
                    businessUnit:component.get('v.selectedBusinessUnitFilter'),
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
        var financeData = component.get('v.financials');
        
        var fileTotal = 0;
        var opptyTotal = 0;
        var amountTotal = 0;
        for(var i = 0; i < financeData.length; i++){
            fileTotal += financeData[i].fileCount;
            opptyTotal += financeData[i].opptyCount;
            amountTotal += financeData[i].amount;
        }
        component.set("v.fileTotal", fileTotal); 
        component.set("v.opptyTotal", opptyTotal); 
        component.set("v.amountTotal", amountTotal);
    },
    
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message, 'error');
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