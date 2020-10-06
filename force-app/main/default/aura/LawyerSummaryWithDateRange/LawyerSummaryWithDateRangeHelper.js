({
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 1;
        //var min = year+'-01-01';
        var min = '1980-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    setDefaultBussinessUnit: function(component){
        let selectedBusinessUnitFilter = [];
        selectedBusinessUnitFilter.push({Id:"ELFI",Name:"ELFI"});
        component.set("v.selectedBusinessUnitFilter", selectedBusinessUnitFilter); 
    },
    setDefaultTypeOfLoan : function(component){
        let selectedTypeOfLoanFilter = [];
        selectedTypeOfLoanFilter.push({Id:"Facility Loan",Name:"Facility Loan"});
        component.set("v.selectedTypeOfLoanFilter", selectedTypeOfLoanFilter);  
    },
    saveCustomSettings : function(component){
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessunitArr = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloanArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        var action = component.get('c.SaveCustomSettings');
        action.setParams({
            startdate : component.get("v.startDate"), 
            enddate: component.get("v.endDate"),
            payoutDate: component.get("v.payoutDate"),
            reportDate : component.get("v.reportDate"),
            typeofloans : typeofloanArr,
            businessUnitFilter : businessunitArr,
            LoanFilter: loanFilterValue
        });
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            component.set('v.spinner', false);
            if (state === 'SUCCESS') {
                component.set("v.contactsList", response.getReturnValue());                
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
    setDefaultDates : function(component){
        let dt = new Date();
        
        let defaultPayoutDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
        component.set("v.payoutDate", defaultPayoutDate);
        
        let defaultReportDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + dt.getDate() + '';
        component.set("v.reportDate", defaultReportDate); 
        
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
    /*
    getLawyersList : function(component) {
        //var recordId = component.get("v.recordId");
        var action = component.get('c.getLawyersContacts');             
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.contactsList", response.getReturnValue());                
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
    searchButton : function(component) {
        let searchString = component.get('v.searchString');
        let endDateSearch = component.get('v.endDateSearch');
		let loanFilterValue = component.find("activeLoanFilter").get("v.value"); 
        
        var action = component.get('c.getLawyersContacts');
        action.setParams({ sortField : '', sortOrder : '', searchString : searchString, LoanFilter: loanFilterValue});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.contactsList", response.getReturnValue());                
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
    },*/
    //sort : function(component, event) {
    
    formatDate : function(dateToFormat){
        var d = new Date(dateToFormat),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();
    	if (month.length < 2) month = '0' + month;
    	if (day.length < 2) day = '0' + day;
        return [year,month,day].join('-')+'T00:00:00Z';
    },
    getQueryString : function(component){
        let searchString = component.get('v.searchString');
        let field = component.get('v.sortField');
        let sortOrder = component.get('v.sortOrder');
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessUnitFilterValue = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloansFilterValue = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let strQuery = component.get('v.query');        
        
        searchString = searchString ? "'%"+searchString+"%'" : "'%%'";
        sortOrder = sortOrder? sortOrder : "ASC";
        field = field ? field : "Name";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        console.log(businessUnitFilterValue);
        strQuery += " AND (Name Like " + searchString + " OR Account.Name Like " + searchString + " ) ";
        strQuery += " AND Id in (SELECT Lawyer__c FROM Opportunity WHERE accountId !=null";
        strQuery += businessUnitFilterValue.length == 0? "" : " AND Account.Business_Unit__c IN ("+businessUnitFilterValue.join()+")";
        strQuery += typeofloansFilterValue.length == 0 ? "" : " AND Type_of_Loan__c IN (" + typeofloansFilterValue.join() + ")";
        strQuery += loanFilterValue == "Active"? " AND isClosed = true AND isWon = true AND Stage_Status__c != 'Paid Off')" : ")";
        if(component.get("v.startDate") && component.get("v.endDate")) strQuery += " AND CreatedDate >= "+this.formatDate(component.get("v.startDate"))+" AND CreatedDate <= "+this.formatDate(component.get("v.endDate"));
        strQuery += " order by " + field + " " + sortOrder + " limit 10000";
        console.log("this is testing the query");
        console.log(strQuery);
        return strQuery;
    },
    
    getLawyersList : function(component, event) {
        
        component.set('v.spinner', true);
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let strQuery = this.getQueryString(component);             
        let businessunitArr = this.getSelectedPickListValue(component, "", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloansArr = this.getSelectedPickListValue(component, "", component.find("typeOfLoanMS").get("v.selectedOptions"));
        var action = component.get('c.getLawyersContacts');
        action.setParams({
            strQuery : strQuery, 
            LoanFilter: loanFilterValue,
            businessUnitFilter: businessunitArr,
            typeofloans: typeofloansArr,
            startDate : component.get("v.startDate"),
            endDate : component.get("v.endDate")
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            component.set('v.spinner', false);
            if (state === 'SUCCESS') {
                component.set("v.contactsList", response.getReturnValue());                
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
    checkAll: function(component){
        
        let value = component.find("selectAllcheckbox").get("v.value");      
        let contactList = component.get("v.contactsList");
        
        for(let i=0; i<contactList.length; i++){
            contactList[i].checked = value;
        }
        
        component.set("v.contactsList",contactList);
        
    },
    check: function(component){    
        var comp = component.find("selectAllcheckbox");
        let value = comp.get("v.value");        
        if(value){
            value = false;
        }
        let contactList = component.get("v.contactsList");
        let count = 0;
        for(let i=0; i<contactList.length; i++){
            if(contactList[i].checked == true){
                count++;
            }
        }
        if(count == contactList.length){
            value = true;
        }
		comp.set("v.value", value);        
        
    },
    
    generateForSelected: function (component){
        component.set('v.spinner', true);
        let contactList = component.get("v.contactsList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessUnitFilterValue = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloanArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        
        let selectedIds = [];
        let conList = [];
        for(let i=0; i<contactList.length; i++){
            if(contactList[i].checked == true){
                selectedIds.push("'" + contactList[i].contact.Id + "'");
                conList.push(contactList[i].contact);
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
                typeofloans: typeofloanArr
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
    
    sendToSelected: function (component){
        component.set('v.spinner', true);
        let contactList = component.get("v.contactsList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let emailBody = component.get("v.emailBody");
        let businessUnitFilterValue = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloansArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let loanFilterValue = component.get("v.selectedLoanFilter");

        loanFilterValue = loanFilterValue ? loanFilterValue : "All";        
        
        let selectedIds = [];
        let conList = [];
        for(let i=0; i<contactList.length; i++){
            if(contactList[i].checked == true){
                console.log(contactList[i]);
                console.log(contactList[i].contact);
                selectedIds.push("'" + contactList[i].contact.Id + "'");
                conList.push(contactList[i].contact);
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
                typeofloans: typeofloansArr
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

    setDefaultDatesEndStart : function(component){
        var action = component.get('c.GetCustomSettings');
        return new Promise($A.getCallback(function(resolve, reject) {
            action.setCallback(this, function (response) {
                var state = response.getState();
                var result = response.getReturnValue();
                if (state === 'SUCCESS') {
                    component.set("v.endDate", result.Lawyer_Count_End_Date__c);
                    component.set("v.startDate", result.Lawyer_Count_Start_Date__c);
                    resolve(true);  
                } else if (state === 'ERROR') {
                    let dt = new Date();
                    let defaultEndDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
                    let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth()) +'-01';
                    component.set("v.endDate", defaultEndDate);
                    component.set("v.startDate", defaultStartDate);
                    reject(false);  
                }
            });
            $A.enqueueAction(action);
        }));
    },
    
    sendToIndividual: function(component, event){
        component.set('v.spinner', true);
        let contactId = event.currentTarget.dataset.selected;
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let emailBody = component.get("v.emailBody");
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
                businessUnitFilter: businessUnitFilterValue
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
    
    GenerateForAll: function (component){
        component.set('v.spinner', true);
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let query = this.getQueryString(component);
        let businessUnitFilterValue = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloanArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let loanFilterValue = component.get("v.selectedLoanFilter");

        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        
        var action = component.get('c.generate');
        action.setParams({
            query : query, 
            selectedIds : [], 
            payoutDate : payoutDate, 
            reportDate : reportDate,
            LoanFilter: loanFilterValue,
            businessUnitFilter: businessUnitFilterValue,
            typeofloans: typeofloanArr
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
    
    sendAll: function (component){
        component.set('v.spinner', true);
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let query = this.getQueryString(component);
        let emailBody = component.get("v.emailBody");
        let businessUnitFilterValue = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloanArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
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
            typeofloans: typeofloanArr
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
    setBusinessUnitFilter : function(component){
        let businessUnit = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloanArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        component.set("v.pv1",businessUnit.join('|'));
        component.set("v.pv2","");
        component.set("v.pv5", typeofloanArr.join('|'));
    },
    getViewUrl : function(component){
        component.set("v.viewUrl","/apex/APXTConga4__Conga_Composer?SolMgr=1&serverUrl="+$A.get("$Label.c.Partner_API_Server_Url")+"&Id="+$A.get("$SObjectType.CurrentUser.Id")+"&QueryId=[lawyerCount]"+$A.get("$Label.c.Lawyer_Count_Query_Id")+"?pv1="+component.get("v.pv1")+"~pv2=\'"+component.get("v.pv2")+"\'~pv3="+this.formatDate(component.get("v.startDate"))+"~pv4="+this.formatDate(component.get("v.endDate"))+"~pv5="+component.get("v.pv5")+"&TemplateId="+$A.get("$Label.c.Lawyer_Count_Template_Id")+"&DS7=3");
    },
    getViewUrlAll : function(component){
        component.set("v.viewUrlAll","/apex/APXTConga4__Conga_Composer?SolMgr=1&serverUrl="+$A.get("$Label.c.Partner_API_Server_Url")+"&Id="+$A.get("$Label.c.Drawdown_Id")+"&QueryId=[Drawdown]"+$A.get("$Label.c.Lawyer_Count_View_All")+"?pv1="+component.get("v.pv1")+"~pv2=\'"+component.get("v.pv2")+"\'~pv3="+this.formatDate(component.get("v.startDate"))+"~pv4="+this.formatDate(component.get("v.endDate"))+"~pv5="+component.get("v.pv5")+"&TemplateId="+$A.get("$Label.c.Lawyer_Count_Template_Id_View_All")+"&DS7=3");
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