({
    searchButton: function(component, event, helper) {
        component.set("v.spinner", true);
        helper.setCustomSettings(component).then($A.getCallback(
            function(result){
                return helper.getDrawdown(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.drawdown',result);
                return helper.getPaymentsGroupByProvince(component);
            }
        )).then(
            function(result){
                component.set('v.paymentsByProvince',result);
                helper.calculateReportByProvinceData(component);
                //return helper.getPartialPaymentsData(component);                
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
        //component.set("v.spinner", false);
        
    },
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        //helper.setDefaultDates(component);
        helper.setDefaultTypeOfLoanAndBusinessUnit(component);
        helper.getMultiSelectPickList(component, 'Opportunity', 'Type_of_Loan__c', 'typeOfLoanOptions', component.get("v.selectedTypeOfLoanFilter"));
        helper.getMultiSelectPickList(component, 'Account','Business_Unit__c','businessUnitOptions', component.get("v.selectedBusinessUnitFilter") );
        
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
            })
        ).then($A.getCallback(function(result){
            return helper.getPaymentsGroupByProvince(component);
        })).then($A.getCallback(
            function(result){
                component.set('v.paymentsByProvince',result);                
                helper.calculateReportByProvinceData(component);
                //return helper.getPartialPaymentsData(component);
            }
        )).then(
            //$A.getCallback(
                function(result){
                    component.set("v.spinner", false);
                    //component.set('v.partialPayments',result);
                }
        //)
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        component.set("v.spinner", true);
        helper.getDrawdown(component).then(
            function(result){
                component.set('v.drawdown',result);
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
             
    }
})