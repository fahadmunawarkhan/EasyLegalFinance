({
    
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);        
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        helper.getPickListValues(component, 'Opportunity', 'Type_of_Loan__c', 'typeOfLoanOptions');
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        
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
        helper.getAmountGroupByLawyer(component).then($A.getCallback(
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
        let url = '/apex/LawyerSalesSummaryViewAllVF?BusinessUnit=' + component.get('v.selectedBusinessUnitFilter');
        url += '&StartDate=' + component.get('v.startDate') + '&EndDate=' + component.get('v.endDate') + '&SearchByName='+ component.get('v.searchByName')
        url += '&TypeOfLoan='+ component.get('v.selectedTypeOfLoanFilter')
        
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
        let url = '/apex/LawyerSalesSummaryViewAllVF?BusinessUnit=' + component.get('v.selectedBusinessUnitFilter');
        url += '&StartDate=' + component.get('v.startDate') + '&EndDate=' + component.get('v.endDate') + '&SearchByName='+ component.get('v.searchByName')
        url += '&TypeOfLoan='+ component.get('v.selectedTypeOfLoanFilter') + '&ContentType=PDF';
        
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
        let url = '/apex/LawyerSalesSummaryPrintPDF?BusinessUnit=' + component.get('v.selectedBusinessUnitFilter');
        url += '&StartDate=' + component.get('v.startDate') + '&EndDate=' + component.get('v.endDate') + '&SearchByName='+ component.get('v.searchByName')
        url += '&TypeOfLoan='+ component.get('v.selectedTypeOfLoanFilter') + '&ContentType=PDF';
        
        let newWin;
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    }
})