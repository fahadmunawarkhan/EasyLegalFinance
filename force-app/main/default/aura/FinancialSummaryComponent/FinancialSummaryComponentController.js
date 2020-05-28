({
    doInit : function(component, event, helper) {        
        component.set("v.spinner", true);        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component); 
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        helper.getPickListValues(component, 'Opportunity', 'Type_of_Loan__c', 'typeOfLoanOptions');
        
        helper.getCustomSettings(component).then(
            function(result){                
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
            }
        ).then($A.getCallback(function(result){
            return helper.getReportByProvinceHelper(component);
        })).then($A.getCallback(function(result){
            component.set('v.financials',result);
            helper.calculateReportByProvinceData(component);
            return helper.getFinancialReportData(component);
        })).then($A.getCallback(function(result){
            component.set('v.financialReportData',result);
            return helper.validateReport(component);
        })).then($A.getCallback(function(result){
            let customSettings = component.get('v.customSetting');
            console.log('Comparison');
            console.log('result ' + result);
            console.log('customSetting SI ' + customSettings.Since_Inception__c);
            console.log('Component SI ' + component.get('v.sinceInception'));
            console.log('CS Start Date ' + customSettings.Start_Date__c);
            console.log('Component Start Date ' + component.get('v.startDate'));
            if(!result || (customSettings.Since_Inception__c && !component.get('v.sinceInception')) 
               || (!customSettings.Since_Inception__c && customSettings.Start_Date__c != component.get('v.startDate'))){
                component.set('v.showWarning',true);
            }else{
                component.set('v.showWarning', false);
            }
            return helper.getBatchJobStatus(component);
        })).then(function(result){
            component.set('v.apexBatchJobOBJ', result);
            component.set('v.batchJobStatus',result.Status);
            component.set('v.batchTotalJobItems', (result.TotalJobItems > 0) ? result.TotalJobItems : 0);
            component.set('v.batchJobItemsProcessed', (result.TotalJobItems > 0) ? result.JobItemsProcessed : 0);
            component.set('v.batchJobProgress',(result.TotalJobItems > 0) ? (result.JobItemsProcessed/(result.TotalJobItems !=0? result.TotalJobItems: 1)*100) : 0);
            component.set('v.batchJobItems', (result.TotalJobItems > 0) ? ' '+ parseFloat((result.JobItemsProcessed/(result.TotalJobItems !=0? result.TotalJobItems: 1))*100).toFixed(0) + '%' : '0%');
            if(result != null && (result.Status != 'Completed' && result.Status != 'Aborted' && result.Status != 'Failed')){                    
                helper.pingForBatchJobStatus(component);
            }else{
                
            }                
        }).then(function(){
            component.set("v.spinner", false);
        }).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        ); 
    },
    
    searchButton: function(component, event, helper) {
        component.set("v.spinner", true);
        
        helper.setBUCustomSettings(component);
        
        $A.enqueueAction(component.get('c.filterButton'));
        
        component.set("v.spinner", false);
        
    },
    
    setBatchJobStatus : function(component, event, helper){
        helper.getBatchJobStatus(component).then(function(result){
            component.set('v.apexBatchJobOBJ', result);
            return helper.updateProgress(component);        
        }).then($A.getCallback(function(result){
            if(result){
                let apexBatchJobOBJ = component.get('v.apexBatchJobOBJ');
                let showBatchError = component.get("v.showZeroBatchError");
                if(apexBatchJobOBJ != null && apexBatchJobOBJ.TotalJobItems == 0 && showBatchError){
                    helper.showToast('ERROR', 'No records found for selected date range or type of loan to run the job.', 'error');
                    component.set("v.showZeroBatchError", false);
                }
                
                window.clearInterval(component.get('v.intervalId'));
                $A.get('e.force:refreshView').fire();
                return helper.getCustomSettings(component);                
            }
        })).then($A.getCallback(function(result){
            if(result != null){
                component.set('v.customSetting', result);
            	return helper.setDefaultDates(component);
            }            
        })).then($A.getCallback(function(result){
            if(result){
                component.set('v.showWarning', false);
                $A.enqueueAction(component.get('c.filterButton'));
            }            
        })).catch(function(errors){            
            helper.errorsHandler(errors);
        });
    },
    
    filterButton : function(component, event, helper){
        console.log('Filter Button');
        component.set("v.spinner", true);        
        helper.setBUCustomSettings(component);
        
        helper.getReportByProvinceHelper(component).then($A.getCallback(
            function(result){
                var res = JSON.stringify(result);
                console.log('****'+res);
                component.set('v.financials',result);
                helper.setDateCustomSettings(component);
                helper.calculateReportByProvinceData(component);
                return helper.getFinancialReportData(component);
            }
        )).then($A.getCallback(function(result){
            component.set('v.financialReportData',result);
            return helper.getCustomSettings(component);
        })).then($A.getCallback(
            function(result){                
                component.set('v.customSetting', result);
                return helper.validateReport(component);
            }
        )).then(
            function(result){
                let customSettings = component.get('v.customSetting');                
                if(!result || (customSettings.Since_Inception__c && !component.get('v.sinceInception')) || (!customSettings.Since_Inception__c && component.get('v.sinceInception')) 
                   || (!customSettings.Since_Inception__c && customSettings.Start_Date__c != component.get('v.startDate'))){
                    component.set('v.showWarning',true);
                }else{
                    component.set('v.showWarning', false);
                }
            }
        ).then(
            function(){
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log('errors');
                console.log(errors);
                component.set("v.spinner", false);  
                helper.errorsHandler(errors);
            }
        );
    },
    closeWarning : function(component, event, helper){        
        component.set('v.showWarning', false);
    },
    
    runJobButton : function(component, event, helper) {
        //component.set('v.showWarning',false);
        let customSetting = component.get('v.customSetting');
        /*if(customSetting.Start_Date__c == component.get('v.startDate') && customSetting.End_Date__c == component.get('v.endDate')){
            
        }*/
        component.set("v.spinner", true);
        component.set("v.showZeroBatchError", true);
        let apexBatchJobOBJ = component.get('v.apexBatchJobOBJ');
        if(apexBatchJobOBJ != null && (apexBatchJobOBJ.Status != 'Completed' && apexBatchJobOBJ.Status != 'Aborted' && apexBatchJobOBJ.Status != 'Failed')){
            window.clearInterval(component.get('v.intervalId'));
        }
        
        
        
        helper.executeBatchJob(component).then(
            function(result){
                return helper.getBatchJobStatus(component);
            }
        ).then(
            function(result){
                component.set('v.apexBatchJobOBJ', result);                        
                return helper.updateProgress(component);
            }
        ).then(
            function(resut){
                return helper.pingForBatchJobStatus(component);
            }
        ).then(
            function(){
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );        
    },
    sinceInceptionClicked : function(component, event, helper){
        let adhocAsOfDate = component.get("v.adhocAsOfDate");
        let sinceInception = component.get("v.sinceInception");
        console.log('sinceInception = ' + sinceInception);
        if(sinceInception){
            component.set("v.adhocAsOfDate", '');
        }else{
            component.set("v.adhocAsOfDate", component.get("v.startDate"));
        }
    },
    handleAdhocAsOfDateChange : function(component, event, helper){
        let adhocAsOfDate = component.get("v.adhocAsOfDate");
        console.log('adhocAsOfDateChange ' + adhocAsOfDate);
        component.set("v.sinceInception", true);
        if(adhocAsOfDate != null && adhocAsOfDate != ''){
            component.set("v.sinceInception", false);
        }
    },
    handleDestroy : function( component, event, helper ) {
        console.log('clear interval due to navigation');
        window.clearInterval(component.get("v.intervalId"));
    },
})