({
	getCalendarMin : function(component){
        component.set("v.calendarMin", '1980-01-01');                  
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
    getClientList : function(component) {
		let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "");       
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getClientList');
                action.setParams({
                    searchByName : component.get('v.searchString'),
                    sortField : component.get('v.sortField'),
                    sortOrder : component.get('v.sortOrder'),
                    loanFilter: component.get("v.selectedLoanFilter"),
                    businessUnitFilter: component.get('v.selectedBusinessUnitFilter'),
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
                    if(!allValues[i].includes('Lawyer Loan-Contingency Fee Acceleration')){
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
    },
    
    getQueryString : function(component){
        let searchString = component.get('v.searchString');
        let field = component.get('v.sortField');
        let sortOrder = component.get('v.sortOrder');
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let selectedTypeOfLoanOptions = component.find("typeOfLoanMS").get("v.selectedOptions");
        let strQuery = "SELECT Id, Name, Account.Name, Account.AccountNumber, AccountId"; 
        strQuery += " FROM Contact WHERE AccountId != null";
        let typeOfLoanArr = [];
        for(let i=0; i<selectedTypeOfLoanOptions.length; i++){
            typeOfLoanArr.push("\'" + selectedTypeOfLoanOptions[i].Name + "\'");
        }
        let typeOfLoanStr = typeOfLoanArr.length >0 ? typeOfLoanArr.join(',') : "";
        console.log('typeOfLoanStr ' + typeOfLoanStr);
        
        searchString = searchString ? "'%"+searchString+"%'" : "'%%'";
        sortOrder = sortOrder? sortOrder : "ASC";
        field = field ? field : "Name";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : 'ELFI';
            
        strQuery += " AND (Name Like " + searchString + " OR Account.AccountNumber Like " + searchString + " ) ";
        strQuery += " AND Id in (SELECT Primary_Contact__c FROM Opportunity WHERE accountId !=null AND Account.Exclude_from_Payout__c = false"
        
        strQuery += " AND StageName = \'Closed With Loan\' AND Drawdown_Total__c > 0";
        strQuery += businessUnitFilterValue == 'All'? "" : " AND Account.Business_Unit__c = \'"+businessUnitFilterValue+"\'";
        strQuery += loanFilterValue == "Active"? " AND Stage_Status__c LIKE \'%Active%\'" : "";
        strQuery += typeOfLoanStr == ""? ")" : " AND Type_of_Loan__c IN ("+typeOfLoanStr+"))";
        strQuery += " order by createdDate desc limit 10000";
        console.log(strQuery);
        component.set("v.query", strQuery);
        return strQuery;
    },
    
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message, 'error');
        }else{
            this.unknownErrorsHandler();
        }
    },
    unknownErrorsHandler : function(){
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error', 'error'); 
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
    checkAll: function(component){
        
        let value = component.find("selectAllcheckbox").get("v.value");
        let clientList = component.get("v.clientList");
        let selectedCount = component.get('v.selectedCount');
        selectedCount = 0;
        if(value){
            selectedCount = clientList.length;
        }
        for(let i=0; i<clientList.length; i++){
            clientList[i].checked = value;
        }
        
        component.set("v.clientList",clientList);
        component.set('v.selectedCount', selectedCount);
        
    },
    check: function(component, event){
        let selectedCount = component.get('v.selectedCount');
        if(event.getSource().get('v.value')){
            selectedCount++;
        }else{
            selectedCount--;
        }
        
        var comp = component.find("selectAllcheckbox");
        let value = comp.get("v.value");        
        if(value){
            value = false;
        }
        let clientList = component.get("v.clientList");
        
        if(selectedCount == clientList.length){
            value = true;
        }
        component.set("v.selectedCount", selectedCount);
		comp.set("v.value", value);        
        
    },
    generatePayoutBalanceForSelected: function(component, helper){
        console.log('generatePayoutBalanceForSelected');
        let typeOfLoanArr = helper.getSelectedTypeOfLoanArr(component, "");
        console.log('typeOfLoanArr ' + typeOfLoanArr);
        return new Promise($A.getCallback(
            function(resolve, reject){
                let clientList = component.get("v.clientList");
                let selectedIds = [];
                for(let i=0; i<clientList.length; i++){
                    if(clientList[i].checked == true){
                        selectedIds.push(clientList[i].contact.Id);
                    }
                }
                
                let action = component.get("c.generatePayoutBalance");
                action.setParams({
                    selectedIds : selectedIds,
                    payoutDate : component.get("v.payoutDate"),
                    searchByName : component.get('v.searchString'),
                    loanFilter: component.get("v.selectedLoanFilter"),
                    businessUnitFilter: component.get('v.selectedBusinessUnitFilter'),
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
    generatePayoutBalanceForAll : function(component,helper){
        let typeOfLoanArr = helper.getSelectedTypeOfLoanArr(component, "");
        return new Promise($A.getCallback(
            function(resolve, reject){
                let selectedIds = [];
                
                let action = component.get("c.generatePayoutBalance");
                action.setParams({
                    selectedIds : selectedIds,
                    payoutDate : component.get("v.payoutDate"),
                    searchByName : component.get('v.searchString'),
                    loanFilter: component.get("v.selectedLoanFilter"),
                    businessUnitFilter: component.get('v.selectedBusinessUnitFilter'),
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
    pingBatchJobStatus : function (component, helper){ 
        console.log('Is pinging..');
        helper.getBatchJobStatus(component).then($A.getCallback(
            function(result){
                let showBatchError = component.get("v.showZeroBatchError");
                if(result != null && result.TotalJobItems == 0 && result.Status == 'Completed' && showBatchError){
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
    generateForSelected: function (component){
        component.set('v.spinner', true);
        let clientList = component.get("v.clientList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "'");
        
        let selectedIds = [];
        let conList = [];
        for(let i=0; i<clientList.length; i++){
            if(clientList[i].checked == true){
                selectedIds.push("'" + clientList[i].contact.Id + "'");
                conList.push(clientList[i].contact);
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
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "'");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let query = this.getQueryString(component);
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        
        var action = component.get('c.generate');
        action.setParams({ 
            query : query, 
            selectedIds : [], 
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
    sendToSelected: function (component){
        component.set('v.spinner', true);
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "'");
        let clientList = component.get("v.clientList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let emailBody = component.get("v.emailBody");
        emailBody = emailBody != undefined && emailBody != null && emailBody != ''? emailBody.split("\n").join("<br/>") : '';
		let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";        
        
        let selectedIds = [];
        let conList = [];
        for(let i=0; i<clientList.length; i++){
            if(clientList[i].checked == true){
                console.log(clientList[i]);
                console.log(clientList[i].contact);
                selectedIds.push("'" + clientList[i].contact.Id + "'");
                conList.push(clientList[i].contact);
            }
        }
        console.log(selectedIds);
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
                emailBody : emailBody,
                LoanFilter: loanFilterValue,
                businessUnitFilter: businessUnitFilterValue,
                typeOfLoan : typeOfLoanArr
            });            
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
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
                component.set('v.spinner', false);
            });
            $A.enqueueAction(action);
            
        }
        
    },
    
    sendToIndividual: function(component, event){
        component.set('v.spinner', true);
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "'");
        let contactId = event.currentTarget.dataset.selected;
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let emailBody = component.get("v.emailBody");
        emailBody = emailBody != undefined && emailBody != null && emailBody != ''? emailBody.split("\n").join("<br/>") : '';
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        
        var action = component.get('c.send');
            action.setParams({
                query : '', 
                selectedIds : "'" + contactId + "'", 
                payoutDate : payoutDate, 
                reportDate : reportDate, 
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
    },
    sendAll: function (component){
        component.set('v.spinner', true);
        let typeOfLoanArr = this.getSelectedTypeOfLoanArr(component, "'");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let query = this.getQueryString(component);
        let emailBody = component.get("v.emailBody");
        emailBody = emailBody != undefined && emailBody != null && emailBody != ''? emailBody.split("\n").join("<br/>") : '';
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All"; 
        
        var action = component.get('c.send');
        action.setParams({
            query : query, 
            selectedIds : [], 
            payoutDate : payoutDate, 
            reportDate : reportDate, 
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
})