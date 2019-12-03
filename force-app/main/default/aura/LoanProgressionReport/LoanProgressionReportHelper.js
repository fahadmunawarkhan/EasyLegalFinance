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
    },
    getReportCongaURL : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getDrawdownCongaURLs');
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('drawdown report view all.');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    getCustomSettings: function(component){
        return new Promise($A.getCallback(function(resolve,reject){
            let action = component.get('c.getCustomSettings');
            action.setCallback(this, function(response){
                if(response.getState() == 'SUCCESS'){
                    resolve(response.getReturnValue());
                }else if(response.getState() == 'ERROR'){
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
    getFinancialProgressionData : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getProgressionReportData');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                BusinessUnit: component.get('v.selectedBusinessUnitFilter')
            });
            
            action.setCallback(this, function(response){
                if(response.getState() == 'SUCCESS')
                {
                    resolve(response.getReturnValue());
                }else if(response.getState() == 'ERROR'){
                    reject(response.getError());
                }
            });
             $A.enqueueAction(action);
        }));
    },
    calculateGrandTotal : function(component){
        let financialProgressionData = component.get('v.progressionReportData');
        console.log('financialProgressionData ' + financialProgressionData);
        let gTotalAdvancesElfi = 0,
            gTotalAdvancesRhino = 0,
            gTotalNumberOfLoansElfi = 0,
            gTotalNumberOfLoansRhino = 0,
            gTotalLossesAmtElfi = 0,
            gTotalLossesAmtRhino = 0,
            gTotalPercentageElfi = 0,
            gTotalPercentageRhino = 0;
        
        for(let i=0; i< financialProgressionData.length; i++){
            
            console.log('++++++++ ' + i);
            
            console.log(JSON.stringify(financialProgressionData[i]));
            console.log(financialProgressionData[i].totalAdvanceLoanAmountElfi);
            
            gTotalAdvancesElfi += (financialProgressionData[i].totalAdvanceLoanAmountElfi == null) ? 0 : financialProgressionData[i].totalAdvanceLoanAmountElfi;
            gTotalAdvancesRhino += (financialProgressionData[i].totalAdvanceLoanAmountRhino == null) ? 0 : financialProgressionData[i].totalAdvanceLoanAmountRhino;
            
            gTotalNumberOfLoansElfi += (financialProgressionData[i].totalNumberOfLoansElfi == null) ? 0 : financialProgressionData[i].totalNumberOfLoansElfi;
            gTotalNumberOfLoansRhino += (financialProgressionData[i].totalNumberOfLoansRhino == null) ? 0 : financialProgressionData[i].totalNumberOfLoansRhino;
            
            gTotalLossesAmtElfi += (financialProgressionData[i].totalLoanLosesAmountElfi == null) ? 0 : financialProgressionData[i].totalLoanLosesAmountElfi;
            gTotalLossesAmtRhino += (financialProgressionData[i].totalLoanLosesAmountRhino == null) ? 0 : financialProgressionData[i].totalLoanLosesAmountRhino;
            
            gTotalPercentageElfi += (financialProgressionData[i].lossesPercentageElfi == null) ? 0 : parseFloat(financialProgressionData[i].lossesPercentageElfi);
            gTotalPercentageRhino += (financialProgressionData[i].lossesPercentageRhino == null) ? 0 : parseFloat(financialProgressionData[i].lossesPercentageRhino);
            
            console.log('------' + i);
        }
        
        gTotalPercentageElfi = parseFloat(((gTotalLossesAmtElfi == null) ? 0 : gTotalLossesAmtElfi)/ ((gTotalAdvancesElfi == null || gTotalAdvancesElfi < 1)? 1 : gTotalAdvancesElfi));
        
        gTotalPercentageRhino = parseFloat(((gTotalLossesAmtRhino == null) ? 0 : gTotalLossesAmtRhino) / ((gTotalAdvancesRhino == null || gTotalAdvancesRhino < 1)? 1 : gTotalAdvancesRhino));
        
        
        component.set('v.gTotalAdvancesElfi',gTotalAdvancesElfi);        
        component.set('v.gTotalAdvancesRhino',gTotalAdvancesRhino);
        
        component.set('v.gTotalNumberOfLoansElfi',gTotalNumberOfLoansElfi);
        component.set('v.gTotalNumberOfLoansRhino',gTotalNumberOfLoansRhino);
        
        component.set('v.gTotalLossesAmtElfi',gTotalLossesAmtElfi);
        component.set('v.gTotalLossesAmtRhino',gTotalLossesAmtRhino);
        
        component.set('v.gTotalPercentageElfi',gTotalPercentageElfi);
        component.set('v.gTotalPercentageRhino',gTotalPercentageRhino);
            
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
    }
})