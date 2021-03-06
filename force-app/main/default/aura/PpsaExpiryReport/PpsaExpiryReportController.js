({
    doInit: function(component, event, helper) {

        component.set("v.spinner", true);

        helper.getCalendarMin(component);
        helper.getCalendarMax(component);

        helper.setDefaultTypeOfLoan(component);
        helper.setDefaultBussinessUnit(component);
        helper.getPickListValues(component, 'Opportunity', 'Type_of_Loan__c', 'typeOfLoanOptions', 'selectedTypeOfLoanFilter');
        helper.getPickListValues(component, 'Account', 'Business_Unit__c', 'businessUnitOptions', 'selectedBusinessUnitFilter');
        helper.OrgCheck(component);

        helper.getCustomSettings(component).then($A.getCallback(
            function(result) {
                component.set('v.customSetting', result);
                // console.log('customSetting:' + component.get('v.customSetting.BusinessUnit__c'));
                let filter = component.get("v.selectedBusinessUnitFilter");
                return helper.setDefaultDates(component); // this will set start date and end date
            })).then($A.getCallback(
            function(result) {
                return helper.getPPSExpiryLoans(component);
            }
        )).then($A.getCallback(
            function(result) {
                component.set("v.LoansList", result);
                component.set("v.ChosenFilter", component.get("v.selectedBusinessUnitFilter"));
            }
        )).then($A.getCallback(
            function(result) {
                return helper.getSummarizeReportData(component); // this will set excel, pdf and conga url's
            }
        )).then($A.getCallback(
            function(result) {
                component.set("v.summarizeReportData", result);
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors) {
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );


    },
    searchButton: function(component, event, helper) {
        component.set("v.spinner", true);

        helper.validation(component, 'businessunitMS').then($A.getCallback(
            function(result){
                return helper.validation(component, 'typeOfLoanMS');
            }
        )).then($A.getCallback(
            function(result){
                return helper.getPPSExpiryLoans(component);
            }
        )).then($A.getCallback(
                function(result) {
                    component.set('v.LoansList', result);
                    component.set("v.ChosenFilter", component.get("v.selectedBusinessUnitFilter"));

                    return helper.setCustomSettings(component);

                }
            ))
            .then($A.getCallback(
                function(result) {
                    component.set("v.spinner", false);
                    return helper.getSummarizeReportData(component);
                }
            )).then($A.getCallback(
                function(result) {
                    component.set("v.summarizeReportData", result);
                    component.set("v.spinner", false);
                }
            )).catch(
                function(errors) {
                    component.set("v.spinner", false);
                    helper.errorsHandler(errors);
                }
            );
    },

    viewAllReportButton: function(component) {
        let newWin;
        let url = '';
        url = component.get("v.summarizeReportData.congaViewAllURL");
        try {
            newWin = window.open(url);
        } catch (e) {}
        if (!newWin || newWin.closed || typeof newWin.closed == 'undefined') {
            reject([{ message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!' }]);
        }
    },

    viewAllPDFReportButton: function(component) {
        let newWin;
        let url = '';
        url = component.get("v.summarizeReportData.congaViewAllURL") + '%26' + 'DefaultPDF=1';
        console.log("Url is: === >");
        console.log(url);
        try {
            newWin = window.open(url);
        } catch (e) {}
        if (!newWin || newWin.closed || typeof newWin.closed == 'undefined') {
            reject([{ message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!' }]);
        }
    },

    printPDFReportButton: function(component) {
        let newWin;
        let url = '';
        url = component.get("v.summarizeReportData.congaPrintReportURL") + '%26' + 'DefaultPDF=1';
        console.log("Url is: === >");
        console.log(url);
        try {
            newWin = window.open(url);
        } catch (e) {}
        if (!newWin || newWin.closed || typeof newWin.closed == 'undefined') {
            reject([{ message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!' }]);
        }
    },

    sort: function(component, event, helper) {

        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v.sortOrder');
        let oldField = component.get('v.sortField');
        console.log(selectedItem + '|' + field + '|' + sortOrder + '|' + oldField);
        sortOrder = (sortOrder == 'DESC' && oldField == field) ? 'ASC' : 'DESC';
        component.set('v.sortField', field);
        component.set('v.sortOrder', sortOrder);
        component.set("v.spinner", true);
        $A.enqueueAction(component.get('c.searchButton'));
    },

    filter: function(component, event, helper) {
        var expiryDateFilterValue = component.find("expiryDateFilter").get("v.value");
        var statusFilterValue = component.find("statusFilter").get("v.value");
        component.set("v.expiryDateFilter", expiryDateFilterValue);
        component.set("v.statusFilter", statusFilterValue);
        component.set("v.spinner", true);
        $A.enqueueAction(component.get('c.searchButton'));
    }
})