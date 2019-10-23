({
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 1;
        //var min = year+'-01-01';
        var min = '2010-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    setDefaultDates : function(component){

        let customSettings = component.get('v.customSetting');
        console.log('customSettings ' + JSON.stringify(customSettings));
        let dt = new Date();
        
        let defaultPayoutDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
        component.set("v.payoutDate", customSettings.Payout_Date__c !=null? customSettings.Payout_Date__c: defaultPayoutDate);
        
        let defaultReportDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + dt.getDate() + '';
        component.set("v.reportDate", customSettings.Report_Date__c !=null? customSettings.Report_Date__c: defaultReportDate); 
        
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
    
    getAssessments : function(component){
    	return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get("c.getAssessmentData");
                action.setParams({
                    searchByName : component.get("v.searchByName"),
                    BusinessUnit : component.get("v.selectedBusinessUnitFilter"),
                    field : component.get('v.sortField'),
                    direction : component.get('v.sortOrder')
                });
                
                action.setCallback(this,function(response){
                    let state = response.getState();
                    if(state == "SUCCESS"){
                        resolve(response.getReturnValue());
                    }else if(state == "ERROR"){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));    
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
    checkAll : function(component){
        component.set('v.spinner', true);
        let value = component.find("selectAllcheckbox").get("v.value");      
        let assessmentOpps = component.get("v.data");
        
        for(let i=0; i<assessmentOpps.length; i++){
            assessmentOpps[i].checked = value;
        }
        
        component.set("v.data",assessmentOpps);
        component.set('v.spinner', false);
    },
    check : function(component){
        var value = component.find("selectAllcheckbox").get("v.value");                
        if(value){
            value = false;
        }
        let assessmentOpps = component.get("v.data");
        let count = 0;
        for(let i=0; i<assessmentOpps.length; i++){
            if(assessmentOpps[i].checked == true){
                count++;
            }
        }
        if(count == assessmentOpps.length){
            value = true;
        }
		component.find("selectAllcheckbox").set("v.value", value);
    },
    generateForSelected: function (component){
        component.set('v.spinner', true);
        let assessmentOpps = component.get("v.data");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        
        let selectedIds = [];
        let oppList = [];
        for(let i=0; i<assessmentOpps.length; i++){
            if(assessmentOpps[i].checked == true){
                selectedIds.push("'" + assessmentOpps[i].lawyerId + "'");
                oppList.push(assessmentOpps[i]);
            }
        }
        if(selectedIds.length == 0){
            component.set('v.spinner', false);
            alert("Please select records.");
        }else{
            //alert("Total " + selectedIds.length);
            var action = component.get('c.generate');
            action.setParams({
                selectedIds : selectedIds, 
                payoutDate : payoutDate, 
                reportDate : reportDate,
                businessUnitFilter: businessUnitFilterValue
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    
                    var newWin;
                    try{
                    newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '&ReturnPath=/lightning/n/Assessment_Loans?0.source=alohaHeader');
                    }
                    catch(e){}
                    if(!newWin || newWin.closed || typeof newWin.closed=='undefined') 
                    { 
                        //alert();
                        this.showToast('Error', 'Pop-up is blocked please click allow in the top right corner of browser in address bar!');
                        //POPUP BLOCKED
                    }
                    //window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&&ReportId=&QueryId=a0p21000003rhuC&RecordId=&UrlFieldName=Conga_Batch_Lawyer_Summary__c&Id=a1T21000000osQc');
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    console.log(JSON.stringify(errors[0]));
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                }
                component.set('v.spinner', false);
            });
            $A.enqueueAction(action);
            
        }
        
    },
    GenerateForAll: function (component){
        component.set('v.spinner', true);
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        
        var action = component.get('c.generate');
        action.setParams({ 
            selectedIds : [], 
            payoutDate : payoutDate, 
            reportDate : reportDate,
            businessUnitFilter: businessUnitFilterValue
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
                
            if (state === 'SUCCESS') {
                component.set('v.spinner', false);
                var newWin;
                try{
                    newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '&ReturnPath=/lightning/n/Assessment_Loans?0.source=alohaHeader');
                }
                catch(e){}
                if(!newWin || newWin.closed || typeof newWin.closed=='undefined') 
                { 
                    //alert();
                    this.showToast('Error', 'Pop-up is blocked please click allow in the top right corner of browser in address bar!');
                    //POPUP BLOCKED
                }
                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
        
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