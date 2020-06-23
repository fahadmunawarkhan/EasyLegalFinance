({
	doInit : function(component, event, helper) {
        component.set("v.spinner", true);
        helper.setDefaultTypeOfLoan(component);
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set("v.payOutDate", today);        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        helper.getPickListValues(component, 'Opportunity','Stage_Status__c','oppStageStatus');
        helper.getTypeofLoanPickList(component, 'Opportunity','Type_of_Loan__c','typeOfLoanOptions');
        //helper.getPickListValues(component, 'Opportunity','Type_of_Loan__c','typeOfLoanOptions');
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.setDefaultDates(component);
        helper.getLawyersList(component).then(
            function(result){
                component.set("v.spinner", false);
                component.set('v.contactsList', result);
            }
        ).catch(
            function(errors){
                console.log('errors');
                console.log(JSON.stringify(errors));
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
        console.log('### Search ###');
        const selectedTypeOfLoanOptions = component.find("typeOfLoanMS").get("v.selectedOptions");
        console.log(JSON.stringify(selectedTypeOfLoanOptions));
        component.set("v.spinner", true);
        component.set("v.selectedCount", 0);
        component.find("selectAllcheckbox").set("v.value", false);
        
        helper.validation(component).then(
            function(result){
                return helper.getLawyersList(component);
            }
        ).then(
            function(result){
                component.set("v.spinner", false);
                component.set('v.contactsList', result);
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
    checkAll:function(component, event, helper) {
        helper.checkAll(component);
    },
    check:function(component, event, helper) {
        helper.check(component,event);
    },
    sendToSelected: function(component, event, helper) {
        helper.sendToSelected(component);
    },
    sendAll: function(component, event, helper) {
        helper.sendAll(component);
    },
    sendToIndividual: function(component, event, helper) {
        helper.sendToIndividual(component, event);
    },
    downloadAttachment: function(component, event, helper) {
        let attachmentId = event.currentTarget.dataset.attachment;
        window.open('/servlet/servlet.FileDownload?file=' + attachmentId + '');
    },
    GenerateForAll: function(component, event, helper) {
        helper.GenerateForAll(component);
    },
    generateForSelected: function(component, event, helper) {
        helper.generateForSelected(component);
    },
    
    /**
     * New
     * */
    generatePayoutBalanceButton : function(component, event, helper){
        let selectedCount = component.get('v.selectedCount');
        let contactList = component.get("v.contactsList");
        var selectedMenuItemValue = event.getParam("value");        
        let helperToCall = null;
        if(selectedMenuItemValue == 'generatePayoutBalanceForSelected' && contactList.length != selectedCount){
            if(selectedCount == 0){
                alert("Please select records to generate payout balance.");
            }else{
                helperToCall = helper.generatePayoutBalanceForSelected;                
            }            
        }else if(selectedMenuItemValue == 'generatePayoutBalanceForAll' || (contactList.length == selectedCount && selectedCount != 0)){
            helperToCall = helper.generatePayoutBalanceForAll;
        }
        
        if(helperToCall != null){
            component.set('v.spinner', true);
            component.set("v.showZeroBatchError", true);
            helperToCall(component, helper).then(
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
                    helper.errorsHandler(errors);
                }
            );
        }
        
    },
    generatePayoutDocumentButton : function(component, event, helper){
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue == 'generatePayoutDocForSelected'){
            $A.enqueueAction(component.get("c.generateForSelected"));
        }else if(selectedMenuItemValue == 'generatePayoutDocForAll'){
            $A.enqueueAction(component.get("c.GenerateForAll"));
        }
    },
    sendPayoutDocumentButton : function(component, event, helper){
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue == 'sendPayoutDocToSelected'){
            $A.enqueueAction(component.get("c.sendToSelected"));
        }else if(selectedMenuItemValue == 'sendPayoutDocToAll'){
            $A.enqueueAction(component.get("c.sendAll"));
        }
    },
    handleDestroy : function( component, event, helper ) {
        window.clearInterval(component.get("v.intervalId"));
    },
    openLinkReport : function(component, event, helper){
        
        let oppStageStatus = component.get("v.oppStageStatus");
        let oppTypeOfLoans = component.get("v.oppTypeOfLoans");
        let lawyerId = event.currentTarget.dataset.lawyerid;
        let lawfirmid = event.currentTarget.dataset.lawfirmid;
        let businessUnitFilter = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let typeOfLoan = component.get('v.selectedTypeOfLoanFilter');
        
        let fv7 = 'Active,Active - Partial Payment,Active - Collections';
        if(loanFilterValue == "All" && oppStageStatus != null && oppStageStatus != undefined){
            fv7 = '';
            for(let i=0; i< oppStageStatus.length; i++){
                fv7 += oppStageStatus[i].value + ',';
            }
        }
        let loanTypes = [];
        if(typeOfLoan == "Consolidated"){            
            for(let i=0; i< oppTypeOfLoans.length; i++){
                loanTypes.push(oppTypeOfLoans[i].value);
            }
        }
        
        let fv6 = (typeOfLoan == "Consolidated")? (loanTypes.join(',') + ',') : typeOfLoan;
        
        let newWin;
        let url = '/lightning/r/Report/00O3J000000O7g7UAC/view';
        
        try{                       
            newWin = window.open(url + '?fv3=' + lawyerId.substring(0,15) + '&fv4=' + lawfirmid.substring(0,15) + '&fv5=' + businessUnitFilter + '&fv6=' + fv6 + '&fv7=' + fv7);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    }
})