({
    searchButton: function(component, event, helper) {
        component.set("v.spinner", true);
        console.log("1");
        helper.setCustomSettings(component).then($A.getCallback(
            function(result){
                console.log("2");
                return helper.getDrawdown(component);
            }
        )).then($A.getCallback(
            function(result){
                console.log("3");
                component.set('v.drawdown',result);
                return helper.getPaymentsGroupByProvince(component);
            }
        )).then(
            function(result){
                console.log("4");
                component.set('v.paymentsByProvince',result);
                helper.calculateReportByProvinceData(component);
                //return helper.getPartialPaymentsData(component);
                let filter = component.get("v.selectedBusinessUnitFilter");
                if(filter == "Consolidated"){
                    component.set("v.design", true); 
                }else{
                    component.set("v.design", false); 
                }
                console.log("5");
                component.set("v.ChosenFilter", component.get("v.selectedBusinessUnitFilter"));
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log("6");
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
        helper.getPickListValues(component, 'Opportunity', 'Type_of_Loan__c', 'typeOfLoanOptions');
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){ 
                console.log('Custom settings are:');
                console.log(result);
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
            })
        ).then($A.getCallback(function(result){
            return helper.getPaymentsGroupByProvince(component);
        })).then($A.getCallback(
            function(result){
                component.set('v.paymentsByProvince',result);
                let filter = component.get("v.selectedBusinessUnitFilter");
                if(filter == "Consolidated"){
                   component.set("v.design", true); 
                }else{
                    component.set("v.design", false); 
                }
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