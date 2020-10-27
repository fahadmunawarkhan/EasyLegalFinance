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
        selectedTypeOfLoanFilter.push({Id:"Lump-Sum",Name:"Lump-Sum"});
        component.set("v.selectedTypeOfLoanFilter", selectedTypeOfLoanFilter);  
    },
    setDefaultDates : function(component){
        let action = component.get("c.GetCustomSettings");
        return new Promise(function(resolve, reject) { 
            action.setCallback(this, function(response){
                let state = response.getState();
                let result = response.getReturnValue();
                if(state == 'SUCCESS'){
                    component.set("v.startDate", result.Start_Date_Law_Firm_Report__c);
                    component.set("v.endDate", result.End_Date_Law_Firm_Report__c);
                    // setBusinessUnitTypeofLoan(component, result.Business_Unit_Law_Firm_Report__c);
                    resolve(result);
                } else if(state == 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                    reject(new Error(response.getError()));
                }
            });
            $A.enqueueAction(action);
        });
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
        let typeofloanFilterValue = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let strQuery = component.get('v.query');
        
        searchString = searchString ? "'%"+searchString+"%'" : "'%%'";
        sortOrder = sortOrder? sortOrder : "ASC";
        field = field ? field : "Name";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        
        strQuery += " AND Name Like " + searchString + "";
        strQuery += " AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null";
        strQuery += businessUnitFilterValue.length == 0? "" : " AND Account.Business_Unit__c IN ("+businessUnitFilterValue.join()+")";
        strQuery += typeofloanFilterValue.length == 0 ? "" : " AND Type_of_Loan__c IN (" + typeofloanFilterValue.join() + ")";
        strQuery += loanFilterValue == "Active"? " AND stagename = 'Closed With Loan' AND Stage_Status__c != 'Paid Off')" : ")";
        if(component.get("v.startDate") && component.get("v.endDate")) strQuery += " AND CreatedDate >= "+this.formatDate(component.get("v.startDate"))+" AND CreatedDate <= "+this.formatDate(component.get("v.endDate"));
        strQuery += " order by " + field + " " + sortOrder + " limit 10000";
        // console.log(strQuery);
        return strQuery;
    },
    
    getLawfirmList : function(component, event) {
        
        component.set('v.spinner', true);
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let strQuery = this.getQueryString(component);             
        let businessUnitFilterValue = this.getSelectedPickListValue(component, "", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloanArr = this.getSelectedPickListValue(component, "", component.find("typeOfLoanMS").get("v.selectedOptions"));
        this.getViewUrl(component);

        var action = component.get('c.getLawfirmAccounts');
        action.setParams({
            strQuery : strQuery, 
            LoanFilter: loanFilterValue,
            businessUnitFilter: businessUnitFilterValue,
            startDate : component.get("v.startDate"),
            endDate : component.get("v.endDate"),
            typeofloan: typeofloanArr
        });
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            component.set('v.spinner', false);
            if (state === 'SUCCESS') {
                component.set("v.accountsList", response.getReturnValue());
                component.set('v.showWarning', (component.get("v.accountsList").length > 1000) ? true : false);                
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
    SaveCustomSettings : function(component){
        let businessUnitFilterArr = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloanFilterArr = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        let action = component.get("c.SaveCustomSettings");
        action.setParams({
            startdate: component.get("v.startDate"),
            enddate: component.get("v.endDate"),
            payoutDate: component.get("v.payoutDate"),
            reportDate: component.get("v.reportDate"),
            LoanFilter: component.get("v.selectedLoanFilter"),
            businessUnitFilter: businessUnitFilterArr,
            typeofloanFilter: typeofloanFilterArr
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state == 'SUCCESS'){
            } else if(state == 'ERROR') {
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
                businessUnitFilter: businessUnitFilterValue
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
    
    sendToSelected: function (component){
        component.set('v.spinner', true);
       	let accountList = component.get("v.accountsList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let emailBody = component.get("v.emailBody");
        let emailRecipient = component.get("v.emailRecipient");    
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";        
        
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
            
        }
        
    },
    
    sendToIndividual: function(component, event){
        component.set('v.spinner', true);
        let accountId = event.currentTarget.dataset.selected;
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
		let emailRecipient = component.get("v.emailRecipient");        
        let emailBody = component.get("v.emailBody");
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
                businessUnitFilter: businessUnitFilterValue
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
    setBusinessUnitFilter : function(component){
        let businessUnit = this.getSelectedPickListValue(component, "'", component.find("businessunitMS").get("v.selectedOptions"));
        let typeofloan = this.getSelectedPickListValue(component, "'", component.find("typeOfLoanMS").get("v.selectedOptions"));
        component.set("v.pv1",businessUnit.join('|'));
        component.set("v.pv2","");
        component.set("v.pv5", typeofloan.join('|'));
    },
    getViewUrl : function(component){
        component.set("v.viewUrl","/apex/APXTConga4__Conga_Composer?SolMgr=1&serverUrl="+$A.get("$Label.c.Partner_API_Server_Url")+"&Id="+$A.get("$SObjectType.CurrentUser.Id")+"&QueryId=[lawyerCount]"+$A.get("$Label.c.Law_Firm_Count_Query_Id")+"?pv1="+component.get("v.pv1")+"~pv2=\'"+component.get("v.pv2")+"\'~pv3="+this.formatDate(component.get("v.startDate"))+"~pv4="+this.formatDate(component.get("v.endDate"))+"~pv5="+component.get("v.pv5")+"&TemplateId="+$A.get("$Label.c.Law_Count_Firm_Template_Id")+"&DS7=3");
    },
    getViewUrlViewAll : function(component) {
        component.set("v.viewUrlViewAll", "/apex/APXTConga4__Conga_Composer?SolMgr=1&serverUrl="+$A.get("$Label.c.Partner_API_Server_Url")+"&Id="+$A.get("$Label.c.Drawdown_Id")+"&QueryId=[Drawdown]"+$A.get("$Label.c.Law_Firm_Count_Query_Id_View_All")+"?pv1="+component.get("v.pv1")+"~pv2=\'"+component.get("v.pv2")+"\'~pv3="+this.formatDate(component.get("v.startDate"))+"~pv4="+this.formatDate(component.get("v.endDate"))+"~pv5="+component.get("v.pv5")+"&TemplateId="+$A.get("$Label.c.Law_Count_Firm_Template_Id_View_All")+"&DS7=3");
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