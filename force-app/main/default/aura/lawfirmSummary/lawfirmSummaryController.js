({
	doInit : function(component, event, helper) {        
        
        helper.setDefaultTypeOfLoan(component);
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        //var endOfMonth = $A.localizationService.formatDate(new Date(2008, today.getMonth() + 1, 0), "YYYY-MM-DD");
        component.set("v.payOutDate", today);
        //component.set("v.endDate", endOfMonth);
        
        /*
        Select Name, Id FROM Account WHERE RecordType.Name = 'Law Firm' AND Id in (SELECT Law_firm__c FROM Opportunity WHERE accountId !=null AND isClosed = true AND isWon = true AND Stage_Status__c != 'Paid Off' )
        */
        
        //search query
        let fieldSet = [];
        fieldSet.push("Id");
        fieldSet.push("Name");        
        fieldSet.push("(Select id from Attachments where name like \'%List of Clients%\' and createddate = today order by createddate desc limit 1 )");
        fieldSet.push("(Select id,createddate from tasks where subject LIKE \'%Clients Summary%\' and type = \'Email\' and createddate = today order by createddate desc limit 1 )");
        let strQuery = "SELECT " + fieldSet.join(",");
            strQuery += " FROM Account WHERE RecordType.Name = \'Law Firm\' ";
        component.set("v.query", strQuery); 
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        helper.getPickListValues(component, 'Opportunity','Stage_Status__c','oppStageStatus');
        helper.getTypeofLoanPickList(component, 'Opportunity','Type_of_Loan__c','typeOfLoanOptions');
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.setDefaultDates(component);
        helper.getLawfirmList(component,event).then(
            function(result){
                component.set("v.spinner", false);
                component.set('v.accountsList', result);
            }
        ).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        
        let intervalId = window.setInterval(
            $A.getCallback(function() { 
                helper.pingBatchJobStatus(component, helper);
            }), 2000
        ); 
        component.set('v.intervalId', intervalId);
        
	},
    searchButton: function(component, event, helper) {        
        
        helper.validation(component).then(
            function(result){
                component.set("v.recordSelected", false);
                return helper.getLawfirmList(component, event);
            }
        ).then(
            function(result){
                component.set("v.spinner", false);
                component.set('v.accountsList', result);
            }
        ).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    sort: function(component, event, helper) {  
        
        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v.sortOrder');
        let oldField = component.get('v.sortField');
        
        sortOrder = ((sortOrder == 'DESC' && oldField == field) || oldField != field ) ? 'ASC' : 'DESC';
        
        component.set('v.sortField',field);   
        component.set('v.sortOrder',sortOrder);
        $A.enqueueAction(component.get('c.searchButton'));     
	},
    check:function(component, event, helper) {
        helper.check(component, event);
    },
    sendToSelected: function(component, event, helper) {
        let success = true;
        success = helper.validateEmailRecipient(component);
        if(!success)	return;
        helper.sendToSelected(component);
    },
    sendToIndividual: function(component, event, helper) {
        let success = true;
        success = helper.validateEmailRecipient(component);
        if(!success)	return;
        helper.sendToIndividual(component, event);
    },
    downloadAttachment: function(component, event, helper) {
        let attachmentId = event.currentTarget.dataset.attachment;
        window.open('/servlet/servlet.FileDownload?file=' + attachmentId + '');
    },
    generateForSelected: function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue == 'generatePayoutDocForSelectedExcel'){
            component.set("v.DefaultPDF", false);
            helper.generateForSelected(component);
        } else if(selectedMenuItemValue == 'generatePayoutDocForSelected'){
            component.set("v.DefaultPDF", true);
            helper.generateForSelected(component);
        }
    },
    generateForSelectedExcel: function(component, event, helper){
        component.set("v.DefaultPDF", false);
        helper.generateForSelected(component);
    },
    generateBalanceForSelected: function(component, event, helper) {
        component.set('v.spinner', true);
        helper.generateBalanceForSelected(component).then(
            function(result){
                component.set('v.spinner', false);
                window.clearInterval(component.get('v.intervalId'));
                let intervalId = window.setInterval(
                    $A.getCallback(function() { 
                        helper.pingBatchJobStatus(component, helper);
                    }), 2000
                ); 
                component.set('v.intervalId', intervalId);
            }
        ).catch(
            function(errors){
                component.set("v.spinner", false);
                console.log('errors');
                console.log(errors);
                console.log(JSON.stringify(errors));
                helper.errorsHandler(errors);
            }
        );
    },
    hideLookupInput: function(component, event, helper)
    {
        
    },
    openLinkReport : function(component, event, helper){
        
        let lawfirmid = event.currentTarget.dataset.lawfirmid;
        let newWin;
        let url = '/lightning/r/Report/00O0L000003n3kfUAA/view';
        let businessUnitFilter = component.get("v.selectedBusinessUnitFilter");
        let oppStageStatus = component.get("v.oppStageStatus");
        let oppTypeOfLoans = component.get("v.oppTypeOfLoans");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let typeOfLoan = component.get('v.selectedTypeOfLoanFilter');
        
        let fv6 = 'Active,Active - Partial Payment,Active - Collections,Active - Contingent Loan';
        if(loanFilterValue == "All" && oppStageStatus != null && oppStageStatus != undefined){
            fv6 = '';
            for(let i=6; i< oppStageStatus.length; i++){
                fv6 += oppStageStatus[i].value + ',';
            }
        }
        let loanTypes = [];
        if(typeOfLoan == "Consolidated"){            
            for(let i=0; i< oppTypeOfLoans.length; i++){
                loanTypes.push(oppTypeOfLoans[i].value);
            }
        } else {
            for(let i=0; i< typeOfLoan.length; i++){
                loanTypes.push(typeOfLoan[i].Name);
            }
        }
        
        let fv5 = (typeOfLoan == "Consolidated")? (loanTypes.join(',') + ',') : (loanTypes.join(',') + ',');
        
        try{                       
            newWin = window.open(url + '?fv3=' + lawfirmid.substring(0,15) + '&fv4=' + businessUnitFilter + '&fv5=' + fv5 + '&fv6=' + fv6);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    handleDestroy : function( component, event, helper ) {
        window.clearInterval(component.get("v.intervalId"));
    }
})