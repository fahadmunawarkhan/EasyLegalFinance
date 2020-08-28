({
    doInit : function(component, event, helper) {
        component.set("v.spinner", true);        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        helper.setDefaultTypeOfLoan(component);
        helper.setDefaultBussinessUnit(component);
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions', 'selectedBusinessUnitFilter');
        helper.getPickListValues(component, 'Opportunity', 'Type_of_Loan__c', 'typeOfLoanOptions', 'selectedTypeOfLoanFilter');
        component.set("v.selectedBusinessUnitFilterVal", helper.getSelectedBusinessUnitArr(component, "").join());
        
        helper.getCustomSettings(component).then(
            function(result){                
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
            }
        ).then($A.getCallback(function(result){
            return helper.getReportByProvinceHelper(component);
        })).then($A.getCallback(function(result){
            component.set('v.dataByProvince',result);
            helper.calculateReportByProvinceData(component);
            return helper.getSummarizeReportData(component);
        })).then(function(result){
            component.set('v.summarizeReportData',result);
            component.set("v.spinner", false);
        }).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
        
    searchButton : function(component, event, helper){
        
        component.set("v.spinner", true);
        
        helper.validation(component, 'businessunitMS');
        helper.validation(component, 'typeOfLoanMS');

        component.set("v.selectedBusinessUnitFilterVal", helper.getSelectedBusinessUnitArr(component, "").join());        
        helper.validation(component, 'businessunitMS').then($A.getCallback(
            function(result){
                return helper.validation(component, 'typeOfLoanMS');
            }
        )).then($A.getCallback(
            function(result){
                helper.setCustomSettings(component);
                return helper.getReportByProvinceHelper(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.dataByProvince',result);
                helper.calculateReportByProvinceData(component);
                return helper.getSummarizeReportData(component);
            }
        )).then($A.getCallback(function(result){
            component.set('v.summarizeReportData',result);
            return helper.getCustomSettings(component);
        })).then(
            function(result){                
                component.set('v.customSetting', result);
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log('errors');
                console.log(errors);
                component.set("v.spinner", false);  
                helper.errorsHandler(errors);
            }
        );
    },
})