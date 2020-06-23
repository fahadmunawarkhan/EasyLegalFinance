({
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 1;
        //var min = year+'-01-01';
        var min = '1980-01-01';
        component.set("v.calendarMin", min);                 
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 10;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    setDefaultTypeOfLoan : function(component){
        let selectedTypeOfLoanFilter = [];
        selectedTypeOfLoanFilter.push({Id:"Facility Loan",Name:"Facility Loan"});
        component.set("v.selectedTypeOfLoanFilter", selectedTypeOfLoanFilter);  
    },
    setDefaultDates : function(component){
        let dt = new Date();
        
        let defaultPayoutDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
        component.set("v.payoutDate", defaultPayoutDate);
        
        let defaultReportDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + dt.getDate() + '';
        component.set("v.reportDate", defaultReportDate); 
        
    },
    validation : function(component){
        const selectedTypeOfLoanOptions = component.find("typeOfLoanMS").get("v.selectedOptions");
        return new Promise($A.getCallback(
            function(resolve, reject){
                if(selectedTypeOfLoanOptions.length >= 1){
                    resolve(true);
                }else{
                    reject([{message: 'Please select at least one type of loan filter from dropdown.'}]);
                }
            })
        );
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
                if(attributeId == 'typeOfLoanOptions'){
                    opts.push({
                        class: "optionClass",
                        label: 'Consolidated',
                        value: 'Consolidated'
                    });
                }                
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },    
    getQueryString : function(component){
        let searchString = component.get('v.searchString');
        let field = component.get('v.sortField');
        let sortOrder = component.get('v.sortOrder');
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let selectedTypeOfLoanOptions = component.find("typeOfLoanMS").get("v.selectedOptions");
        let strQuery = component.get('v.query');
        
        let typeOfLoanArr = [];
        for(let i=0; i<selectedTypeOfLoanOptions.length; i++){
            typeOfLoanArr.push("\'" + selectedTypeOfLoanOptions[i].Name + "\'");
        }
        let typeOfLoanStr = typeOfLoanArr.length >0 ? typeOfLoanArr.join(',') : "";
        
        searchString = searchString ? "'%"+searchString+"%'" : "'%%'";
        sortOrder = sortOrder? sortOrder : "ASC";
        field = field ? field : "Name";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : 'All';
        
        strQuery += " AND Name Like " + searchString + "";
        strQuery += " AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null AND StageName = \'Closed With Loan\' AND Drawdown_Total__c > 0";
        strQuery += businessUnitFilterValue == 'All'? "" : " AND Account.Business_Unit__c = \'"+businessUnitFilterValue+"\'";
        strQuery += loanFilterValue == "Active"? " AND Stage_Status__c LIKE \'%Active%\'" : "";
        strQuery += typeOfLoanStr == ""? "" : " AND Type_of_Loan__c IN ("+typeOfLoanStr+")";
        strQuery += ")"
        strQuery += " order by " + field + " " + sortOrder + " limit 10000";
        
        return strQuery;
    },
    
    getLawfirmList : function(component, event) {
        
        component.set('v.spinner', true);
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let strQuery = this.getQueryString(component);             
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        
        return new Promise($A.getCallback(
            function(resolve,reject){
                var action = component.get('c.getLawfirmAccounts');
                action.setParams({
                    strQuery : strQuery, 
                    LoanFilter: loanFilterValue,
                    businessUnitFilter: businessUnitFilterValue,
                    typeOfLoan : typeOfLoanArr
                });
                action.setCallback(this, function (response) {
                    let state = response.getState();
                    if (state === 'SUCCESS') {
                        resolve(response.getReturnValue());                
                    } else if(state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));   
    },
    check: function(component, event){
        //console.log('---- ' + event.getSource().get("v.value"));
        let isRecSelected = component.get("v.recordSelected");
        if(isRecSelected == false && event.getSource().get("v.value")){
            component.set("v.recordSelected", true);
        }else if(event.getSource().get("v.value") == false){
            component.set("v.recordSelected", false);
        }else{
            alert('You have already selected a record.');
            event.getSource().set("v.value",false);
        }
        		        
        
    },    
    generateForSelected: function (component){        
        
        component.set('v.spinner', true);
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "'");
        let accountList = component.get("v.accountsList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        
        let selectedIds = [];
        
        for(let i=0; i<accountList.length; i++){
            if(accountList[i].checked == true){
                selectedIds.push("'" + accountList[i].account.Id + "'");                
            }
        }
        if(selectedIds.length == 0){
            component.set('v.spinner', false);
            alert("Please select records.");
        }else{
            //alert("Total " + selectedIds.length);
            var action = component.get('c.generate');
            action.setParams({
                query : '', 
                selectedIds : selectedIds, 
                payoutDate : payoutDate, 
                reportDate : reportDate,
                LoanFilter: loanFilterValue,
                businessUnitFilter: businessUnitFilterValue,
                typeOfLoan : typeOfLoanArr
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    component.set('v.spinner', false);
                    var newWin;
                    try{
                        newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '&ReturnPath=/lightning/n/Custom_Reports?0.source=alohaHeader');
                        //newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '');
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
            
        }
        
    },
    
    generateBalanceForSelected : function (component){        
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "");
        return new Promise($A.getCallback(
            function(resolve, reject){                
                let accountList = component.get("v.accountsList");
                let payoutDate = component.get("v.payoutDate");
                let reportDate = component.get("v.reportDate");        
                let loanFilterValue = component.get("v.selectedLoanFilter");
                let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
                loanFilterValue = loanFilterValue ? loanFilterValue : "All";
                businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
                
                let lawfirmId;
                for(let i=0; i<accountList.length; i++){
                    if(accountList[i].checked == true){
                        lawfirmId = accountList[i].account.Id;     
                    }
                }
                if(lawfirmId == undefined || lawfirmId == null){
                    component.set('v.spinner', false);
                    alert("Please select records.");
                    reject({message : 'Please select records.'});
                }else{
                    //alert("Total " + selectedIds.length);
                    var action = component.get('c.generatePayoutBalance');
                    action.setParams({
                        lawfirmId : lawfirmId, 
                        payoutDate : payoutDate,
                        LoanFilter :loanFilterValue,
                        businessUnitFilter : businessUnitFilterValue,
                        typeOfLoan : typeOfLoanArr
                    });
                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        
                        if (state === 'SUCCESS') {
                            console.log('SUCCESS');
                            resolve(response.getReturnValue()); 
                        } else if (state === 'ERROR') {
                            var errors = response.getError();
                            console.log('ERROR');
                            console.log(JSON.stringify(errors));
                            reject(response.getError());
                        }
                    });
                    $A.enqueueAction(action);
                    
                }
            }
        ));
        
        
    },
    
    sendToSelected: function (component){
        component.set('v.spinner', true);
       	let accountList = component.get("v.accountsList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let emailBody = component.get("v.emailBody");
        emailBody = emailBody != undefined && emailBody != null && emailBody != ''? emailBody.split("\n").join("<br/>") : '';
        let emailRecipient = component.get("v.emailRecipient");    
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";      
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "'");
        
        let selectedIds = [];        
        for(let i=0; i<accountList.length; i++){
            if(accountList[i].checked == true){                
                selectedIds.push("'" + accountList[i].account.Id + "'");                
            }
        }
        if(selectedIds.length == 0){
            component.set('v.spinner', false);
            alert("Please select records.");
        }else{
            //alert("Total " + selectedIds.length);
            var action = component.get('c.send');
            action.setParams({
                query : '', 
                selectedIds : selectedIds, 
                payoutDate : payoutDate, 
                reportDate : reportDate, 
                emailRecipientId : emailRecipient.Id,
                emailBody : emailBody,
                LoanFilter: loanFilterValue,
                businessUnitFilter: businessUnitFilterValue,
                typeOfLoan : typeOfLoanArr
            });            
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    component.set('v.spinner', false);
                    var newWin;
                    try{
                        newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '&ReturnPath=/lightning/n/Custom_Reports?0.source=alohaHeader');
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
            
        }
        
    },
    
    sendToIndividual: function(component, event){
        component.set('v.spinner', true);
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "'");
        let accountId = event.currentTarget.dataset.selected;
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
		let emailRecipient = component.get("v.emailRecipient");        
        let emailBody = component.get("v.emailBody");
        emailBody = emailBody != undefined && emailBody != null && emailBody != ''? emailBody.split("\n").join("<br/>") : '';
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";        
        
        var action = component.get('c.send');
            action.setParams({
                query : '', 
                selectedIds : "'" + accountId + "'", 
                payoutDate : payoutDate, 
                reportDate : reportDate, 
                emailRecipientId : emailRecipient.Id,
                emailBody : emailBody,
                LoanFilter: loanFilterValue,
                businessUnitFilter: businessUnitFilterValue,
                typeOfLoan : typeOfLoanArr
            });
        
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    component.set('v.spinner', false);
                    var newWin;
                    try{
                        newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '');
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
    
    unknownErrorsHandler : function(){
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error'); 
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
    validateEmailRecipient: function(component) {
        let emailRecipientId = component.get("v.emailRecipient.Id");
        console.log(emailRecipientId);
        if(emailRecipientId){
            return true;
        }else{
            this.showToast('ERROR', 'Please select email recipient', 'ERROR');
            return false;
        }
    },
    pingBatchJobStatus : function (component, helper){ 
        console.log('Is pinging..');
        helper.getBatchJobStatus(component).then($A.getCallback(
            function(result){
                let showBatchError = component.get("v.showZeroBatchError");
                if(result != null && result.TotalJobItems == 0 && showBatchError){
                    helper.showToast('ERROR', 'No records found for selected date range or type of loan to run the job.', 'error');
                    component.set("v.showZeroBatchError", false);
                }
                component.set('v.apexBatchJobOBJ', result);
                helper.updateProgress(component);
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    updateProgress : function (component){
        return new Promise(function(resolve, reject){
            component.set('v.disableButtons',true);
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
            if(apexBatchJobOBJ != null && apexBatchJobOBJ.Status == 'Completed'){
                window.clearInterval(component.get('v.intervalId'));
                component.set('v.disableButtons',false);
                resolve(true);
            }else if(apexBatchJobOBJ == null){
                window.clearInterval(component.get('v.intervalId'));
                component.set('v.disableButtons',false);
                resolve(true);
            }else{
                resolve(false);
            }
            
        });
    },
    getBatchJobStatus : function (component){
        return new Promise($A.getCallback(
            function(resolve,reject){                
                let action = component.get('c.getBatchJobStatus');
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
    getSelectedTypeOfLoanArr : function(component, quote){
        let selectedTypeOfLoanOptions = component.find("typeOfLoanMS").get("v.selectedOptions");
        let typeOfLoanArr = [];
        for(let i=0; i<selectedTypeOfLoanOptions.length; i++){
            typeOfLoanArr.push(quote + selectedTypeOfLoanOptions[i].Name + quote);
        }
        return typeOfLoanArr;
    }
})