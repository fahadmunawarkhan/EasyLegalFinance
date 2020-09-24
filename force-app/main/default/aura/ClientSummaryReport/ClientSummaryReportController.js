({
	doInit : function(component, event, helper) {
		component.set("v.spinner", true);
        helper.setDefaultTypeOfLoan(component);
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set("v.payOutDate", today);
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        helper.getPickListValues(component, 'Opportunity','Stage_Status__c','oppStageStatus');
        helper.getTypeofLoanPickList(component, 'Opportunity','Type_of_Loan__c','typeOfLoanOptions');
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.setDefaultDates(component);

        helper.getClientList(component).then(
            function(result){
                console.log(result);
                component.set("v.spinner", false);
                component.set('v.clientList', result);
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
                return helper.getClientList(component);
            }
        ).then(
            function(result){
                component.set("v.spinner", false);
                component.set('v.clientList', result);
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
    generatePayoutBalanceButton : function(component, event, helper){
        let selectedCount = component.get('v.selectedCount');
        let clientList = component.get("v.clientList");
        var selectedMenuItemValue = event.getParam("value");        
        let helperToCall = null;
        if(selectedMenuItemValue == 'generatePayoutBalanceForSelected' && clientList.length != selectedCount){
            if(selectedCount == 0){
                alert("Please select records to generate payout balance.");
            }else{
                helperToCall = helper.generatePayoutBalanceForSelected;                
            }            
        }else if(selectedMenuItemValue == 'generatePayoutBalanceForAll' || (clientList.length == selectedCount && selectedCount != 0)){
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
                        }), 2500
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
    
    GenerateForAll: function(component, event, helper) {
        helper.GenerateForAll(component);
    },
    generateForSelected: function(component, event, helper) {
        helper.generateForSelected(component);
    },
    downloadAttachment: function(component, event, helper) {
        let attachmentId = event.currentTarget.dataset.attachment;
        window.open('/servlet/servlet.FileDownload?file=' + attachmentId + '');
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
})