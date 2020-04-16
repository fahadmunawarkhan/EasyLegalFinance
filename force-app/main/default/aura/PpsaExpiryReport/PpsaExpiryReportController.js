({
    doInit: function(component, event, helper) {

        component.set("v.spinner", true);

        helper.getCalendarMin(component);
        helper.getCalendarMax(component);

        helper.getPickListValues(component, 'Opportunity', 'Type_of_Loan__c', 'typeOfLoanOptions');
        helper.getPickListValues(component, 'Account', 'Business_Unit__c', 'businessUnitOptions');

        helper.getCustomSettings(component).then($A.getCallback(
            function(result) {
                component.set('v.customSetting', result);
                console.log('customSetting:' + component.get('v.customSetting.Business_Unit__c'));
                let filter = component.get("v.selectedBusinessUnitFilter");
                return helper.setDefaultDates(component); // this will set start date and end date
            })).then($A.getCallback(
            function(result) {
                return helper.getPPSExpiryLoans(component);
            }
        )).catch(
            function(errors) {
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );


    }
})