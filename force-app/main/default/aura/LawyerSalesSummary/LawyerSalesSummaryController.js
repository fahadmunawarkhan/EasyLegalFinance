({
    
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);        
        helper.setDefaultTypeOfLoan(component);
        helper.setDefaultBussinessUnit(component);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        helper.getTypeofLoanPickList(component, 'Opportunity', 'Type_of_Loan__c', 'typeOfLoanOptions', 'selectedTypeOfLoanFilter');
        helper.getTypeofLoanPickList(component, 'Account','Business_Unit__c','businessUnitOptions', 'selectedBusinessUnitFilter');
        console.log('test===??>');
console.log(component.get("v.businessUnitOptions"));
        
        
        helper.getReportCongaURL(component).then($A.getCallback(
            function(result){ 
                component.set('v.ViewAllUrl', result[0].Conga_Lawyer_Sales_Summary_View_All__c);
                component.set('v.PrintAllUrl', result[0].Conga_Lawyer_Sales_Summary_Print_All__c);
            }));
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){ 
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
            }
        )).then($A.getCallback(
            function(result){
                return helper.getLawyerName(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set("v.searchByName", result);
                return helper.getAmountGroupByLawyer(component);
            }
        )).then($A.getCallback(            
            function(result){
                component.set('v.AmountByLawyer', result);
                component.set("v.ChosenFilter", component.get("v.selectedBusinessUnitFilter"));
                
                helper.GetFileTotalAndAmountTotalForLawyer(component);
                //return helper.getPartialPaymentsData(component);
                component.set("v.spinner", false);
            }            
        )).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );       
        
    },
    
    searchButton : function(component, event, helper){
        
        component.set("v.spinner", true);
        helper.resetGrandTotal(component);
        helper.validation(component, 'businessunitMS').then($A.getCallback(
            function(result){
                return helper.validation(component, 'typeOfLoanMS');
            }
        )).then($A.getCallback(
            function(result){
                return helper.getAmountGroupByLawyer(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.AmountByLawyer', result);
                helper.GetFileTotalAndAmountTotalForLawyer(component);
                component.set("v.ChosenFilter", component.get("v.selectedBusinessUnitFilter"));
                return helper.setCustomSettings(component);
            }
        )).then($A.getCallback(
            function(result){                
                return helper.getReportCongaURL(component);                    
            }
        )).then(
            function(result){ 
                component.set('v.ViewAllUrl', result[0].Conga_Lawyer_Sales_Summary_View_All__c);
                component.set('v.PrintAllUrl', result[0].Conga_Lawyer_Sales_Summary_Print_All__c);
                component.set("v.spinner", false);
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
        
        sortOrder = (sortOrder == 'DESC' && oldField == field) ? 'ASC' : 'DESC';
        
        component.set('v.sortField',field);   
        component.set('v.sortOrder',sortOrder); 
        
        component.set("v.spinner", true);
        
        $A.enqueueAction(component.get('c.searchButton'));     
    },
    handleViewAllButtonMenu : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        
        let newWin;
        let url = '';
        
        
        if(selectedMenuItemValue == "ViewAll"){
            url = component.get('v.ViewAllUrl');
        }else if(selectedMenuItemValue == "PayoutViewAll"){
            url = '/apex/LawyerSalesSummaryPayoutReportVF?StartDate='+component.get('v.startDate')+'&EndDate='+component.get('v.endDate')+'&BusinessUnit='+component.get('v.selectedBusinessUnitFilter')+ '&ContentType=Excel';
        }
        
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    handleViewAllPDFButtonMenu : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        
        let newWin;
        let url = '';
        
        
        if(selectedMenuItemValue == "ViewAll"){
            url = component.get('v.ViewAllUrl') +'%26'+'DefaultPDF=1';
        }else if(selectedMenuItemValue == "PayoutViewAll"){
            url = '/apex/LawyerSalesSummaryPayoutReportVF?StartDate='+component.get('v.startDate')+'&EndDate='+component.get('v.endDate')+'&BusinessUnit='+component.get('v.selectedBusinessUnitFilter')+ '&ContentType=PDF';
        }
        
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    viewAllReportButton : function(component, event, helper){
        let typeofloanArr = helper.getSelectedTypeOfLoanArr(component, "");
        let businessunitArr = helper.getSelectedBusinessUnitArr(component, "");
        let url = '/apex/LawyerSalesSummaryViewAllVF?BusinessUnit=' + businessunitArr
        url += '&StartDate=' + component.get('v.startDate') + '&EndDate=' + component.get('v.endDate') + '&SearchByName='+ component.get('v.searchByName');
        url += '&TypeOfLoan='+ typeofloanArr;
        
        let newWin;
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    viewAllPDFReportButton : function(component, event, helper){
        let typeofloanArr = helper.getSelectedTypeOfLoanArr(component, "");
        let businessunitArr = helper.getSelectedBusinessUnitArr(component, "");
        let url = '/apex/LawyerSalesSummaryViewAllVF?BusinessUnit=' + businessunitArr;
        url += '&StartDate=' + component.get('v.startDate') + '&EndDate=' + component.get('v.endDate') + '&SearchByName='+ component.get('v.searchByName')
        url += '&TypeOfLoan='+ typeofloanArr + '&ContentType=PDF';
        
        let newWin;
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    printPDFReportButton : function(component, event, helper){
        let typeofloanArr = helper.getSelectedTypeOfLoanArr(component, "");
        let businessunitArr = helper.getSelectedBusinessUnitArr(component, "");
        let url = '/apex/LawyerSalesSummaryPrintPDF?BusinessUnit=' + businessunitArr;
        url += '&StartDate=' + component.get('v.startDate') + '&EndDate=' + component.get('v.endDate') + '&SearchByName='+ component.get('v.searchByName')
        url += '&TypeOfLoan='+ typeofloanArr + '&ContentType=PDF';
        
        let newWin;
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    openTotalFileReport: function(component, event, helper){
        
        var ctarget = event.currentTarget;
        var lawyerId = ctarget.dataset.lawyer;
        var lawfirmId = ctarget.dataset.lawfirm;
        var typeOfColumn = ctarget.dataset.column;

        var startDate = component.get("v.startDate");
        var endDate = component.get("v.endDate");
        
        let typeofloanArr = helper.getSelectedTypeOfLoanArr(component, "");
        let businessunitArr = helper.getSelectedBusinessUnitArr(component, "");

        // LawyerIdSet=0030L00001zCnvu,003E000001YbpjW

        let singleReportURL = '';

        if(typeOfColumn == "totalAccounts"){

            singleReportURL = '/lightning/r/Report/00OL0000000sCKwMAM/view?';
        }else if(typeOfColumn == "activeAccounts"){

            singleReportURL = '/lightning/r/Report/00OL0000000sCQBMA2/view?';
        }else if(typeOfColumn == "closedAccounts"){

            singleReportURL = '/lightning/r/Report/00OL0000000sCQGMA2/view?';
        }else if(typeOfColumn == "baddebtAccounts"){

            singleReportURL = '/lightning/r/Report/00OL0000000sCQLMA2/view?';
        }else if(typeOfColumn == "shortfallAccounts"){

            singleReportURL = '/lightning/r/Report/00OL0000000sCQQMA2/view?';
        }else if(typeOfColumn == "surplusAccounts"){

            singleReportURL = '/lightning/r/Report/00OL0000000sCQVMA2/view?';
        }

        if(singleReportURL != '')
        singleReportURL += 'fv0=' + startDate + '&fv1=' + endDate + '&fv2=' + typeofloanArr + '&fv3=' + businessunitArr
           + '&fv4=' + lawyerId.substring(0,15) + '&fv5=' + lawfirmId.substring(0,15);

        var RecordIdsString = '';

        /// get the lawyer id string
        var paymentData = component.get('v.AmountByLawyer');
        if(paymentData != null && paymentData != undefined){

            var RecordIds;

            if(paymentData[0].LawyerIds.indexOf("[") > -1){

                RecordIds = paymentData[0].LawyerIds.replace("[", '');

                if(RecordIds.indexOf("]") > -1){

                    RecordIds = RecordIds.replace("]", '');
                }

                if(RecordIds.indexOf(",") > -1){

                    RecordIds = RecordIds.split(",");
                }

                for(var i = 0; i < RecordIds.length; i++){

                    RecordIdsString += RecordIds[i].replaceAll('"', '').substring(0,15);
    
                    if(i < RecordIds.length - 1){
                        RecordIdsString += ',';
                    }
                }
            }else{
                RecordIdsString = 'NoIDs';
            }
        }

        // For Totals
        let completeReportURL = '';

        if(typeOfColumn == "totalAccountsTotal"){

            completeReportURL = '/lightning/r/Report/00OL0000000sCWTMA2/view?';
        }else if(typeOfColumn == "activeAccountsTotal"){

            completeReportURL = '/lightning/r/Report/00OL0000000sCWiMAM/view?';
        }else if(typeOfColumn == "closedAccountsTotal"){

            completeReportURL = '/lightning/r/Report/00OL0000000sCWnMAM/view?';
        }else if(typeOfColumn == "baddebtAccountsTotal"){

            completeReportURL = '/lightning/r/Report/00OL0000000sCWoMAM/view?';
        }else if(typeOfColumn == "shortfallAccountsTotal"){

            completeReportURL = '/lightning/r/Report/00OL0000000sCWsMAM/view?';
        }else if(typeOfColumn == "surplusAccountsTotal"){

            completeReportURL = '/lightning/r/Report/00OL0000000sCWxMAM/view?';
        }

        if(completeReportURL != '')
            completeReportURL += 'fv0=' + startDate + '&fv1=' + endDate + '&fv2=' + typeofloanArr + 
            '&fv3=' + businessunitArr + '&fv6=' + RecordIdsString;

        let newWin;
        try{                       
            newWin = window.open(singleReportURL != ''?singleReportURL:completeReportURL);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    }
})