({
    getCalendarMin: function(component) {
        var year = new Date().getFullYear() - 5;
        //var min = year+'-01-01';
        var min = '1980-01-01';
        component.set("v.calendarMin", min);
    },

    getCalendarMax: function(component) {
        var year = new Date().getFullYear() + 5;
        var max = year + '-12-31';
        component.set("v.calendarMax", max);
    },
    setDefaultTypeOfLoan : function(component){
        let selectedTypeOfLoanFilter = [];
        selectedTypeOfLoanFilter.push({Id:"Lump-Sum",Name:"Lump-Sum"});
        component.set("v.selectedTypeOfLoanFilter", selectedTypeOfLoanFilter);  
    },
    setDefaultBussinessUnit: function(component){
        let selectedBusinessUnitFilter = [];
        selectedBusinessUnitFilter.push({Id:"ELFI",Name:"ELFI"});
        component.set("v.selectedBusinessUnitFilter", selectedBusinessUnitFilter); 
    },
    setCustomSettings: function(component) {
        let typeofloanArr = this.getSelectedTypeOfLoanArr(component, "'");
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "'");
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.saveCustomSettings');
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate'),
                businessUnit: businessunitArr,
                typeOfLoan: typeofloanArr,
                searchByName: component.get('v.searchByName')
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('The start date and end date in custom settings have been updated.');
                    resolve(true);
                } else if (state === 'ERROR') {
                    console.log('The start date and end date in custom settings could not be updated.');
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },

    getCustomSettings: function(component) {
        //get report dates from custom setting
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getCustomSetting');
                action.setCallback(this, function(response) {
                    let state = response.getState();
                    if (state === 'SUCCESS') {
                        console.log('1');
                        console.log(response.getReturnValue());
                        resolve(response.getReturnValue());
                    } else if (state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },

    setDefaultDates: function(component) {
        return new Promise(function(resolve, reject) {
            let dt = new Date();
            let customSetting = component.get('v.customSetting');
            let defaultEndDate = dt.getFullYear() + '-' + (dt.getMonth() + 1) + '-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
            let defaultStartDate = dt.getFullYear() + '-' + (dt.getMonth()) + '-01';
            try {
                component.set("v.endDate", customSetting.End_Date__c == null ? defaultEndDate : customSetting.End_Date__c);
                component.set("v.startDate", customSetting.Start_Date__c == null ? defaultStartDate : customSetting.Start_Date__c);

                resolve(true);
            } catch (e) {
                reject(new Error('Not defined.'));
            }
        });
    },

    getPickListCustomSpecifiedValues: function(component, allValues, attributeId) {
        var opts = [];
        for (var i = 0; i < allValues.length; i++) {

            if (allValues[i].includes('===SEPERATOR===')) {
                opts.push({
                    class: "optionClass",
                    label: allValues[i].split('===SEPERATOR===')[0],
                    value: allValues[i].split('===SEPERATOR===')[1]
                });
            } else {
                opts.push({
                    class: "optionClass",
                    label: allValues[i],
                    value: allValues[i]
                });
            }
        }
        opts.push({
            class: "optionClass",
            label: 'Consolidated',
            value: 'Consolidated'
        });
        component.set('v.' + attributeId, opts);
    },

    OrgCheck: function(component) {
        var orgCheckResult = component.get("c.orgInstanceCheck");
        orgCheckResult.setParams({});
        orgCheckResult.setCallback(this, function(response) {
            if (response.getState() == 'SUCCESS') {
                // console.log("Org Is=====>");
                // console.log(response.getReturnValue());
                // console.log("Org Is=====>");
                var result = response.getReturnValue();
                component.set("v.OrgInstance", result);
            }
        });
        $A.enqueueAction(orgCheckResult);
    },

    getPPSExpiryLoans: function(component) {
        let typeofloanArr = this.getSelectedTypeOfLoanArr(component, "");
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "");
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get("c.getPPSExpiryLoans");
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate'),
                field: component.get('v.sortField'),
                direction: component.get('v.sortOrder'),
                BusinessUnit: businessunitArr,
                searchByName: component.get('v.searchByName'),
                typeOfLoan: typeofloanArr,
                expiryDateFilter: component.get("v.expiryDateFilter"),
                statusFilter: component.get("v.statusFilter")
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('List if loans');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                } else if (state === 'ERROR') {
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    errorsHandler: function(errors) {
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },

    getSummarizeReportData: function(component) {
        let typeofloanArr = this.getSelectedTypeOfLoanArr(component, "");
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "");
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getSummarizeData');
                action.setParams({
                    startDate: component.get('v.startDate'),
                    endDate: component.get('v.endDate'),
                    BusinessUnit: businessunitArr,
                    typeOfLoan: typeofloanArr
                });
                action.setCallback(this, function(response) {
                    let state = response.getState();
                    if (state === 'SUCCESS') {
                        console.log('#####RESULT#####');
                        console.log(JSON.stringify(response.getReturnValue()));
                        resolve(response.getReturnValue());
                    } else if (state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    getPickListValues : function(component, object, field, attributeId, selectedFilterValue){
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });
        picklistgetter.setCallback(this, function(response){
            var opts = [];
            let selectedFilter = component.get("v."+selectedFilterValue);
            if(response.getState() == 'SUCCESS')
            {
                var allValues = response.getReturnValue();
                for (var i = 0; i < allValues.length; i++) {
                    if(allValues[i].includes('===SEPERATOR==='))
                    {
                        opts.push({
                            Id: allValues[i].split('===SEPERATOR===')[0],
                            Name: allValues[i].split('===SEPERATOR===')[1],
                            selected : false
                        });
                    }
                    else
                    {
                        opts.push({
                            Id: allValues[i],
                            Name: allValues[i],
                            selected : false
                        });
                    }
                }
                for(let i=0; i<opts.length; i++){
                    for(let j=0; j< selectedFilter.length; j++){
                        if(opts[i].Name == selectedFilter[j].Name){
                            opts[i].selected = true;
                        }
                    }
                }                
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },
    getSelectedTypeOfLoanArr : function(component, quote){
        let selectedTypeOfLoanOptions = component.find("typeOfLoanMS").get("v.selectedOptions");
        let typeOfLoanArr = [];
        for(let i=0; i<selectedTypeOfLoanOptions.length; i++){
            typeOfLoanArr.push(quote + selectedTypeOfLoanOptions[i].Name + quote);
        }
        return typeOfLoanArr;
    },
    getSelectedBusinessUnitArr : function(component, quote){
        let selectedBusinessUnitOptions = component.find("businessunitMS").get("v.selectedOptions");
        let businessUnitArr = [];
        for(let i=0; i<selectedBusinessUnitOptions.length; i++){
            businessUnitArr.push(quote + selectedBusinessUnitOptions[i].Name + quote);
        }
        return businessUnitArr;
    },
    validation : function(component, multiListId){
        const selectedTypeOfLoanOptions = component.find(multiListId).get("v.selectedOptions");
        let msgidentifier = '';
        return new Promise($A.getCallback(
            function(resolve, reject){
                if(selectedTypeOfLoanOptions.length >= 1){
                    resolve(true);
                }else{
                    msgidentifier = (multiListId == 'typeOfLoanMS')? 'type of loan' : 'business unit';
                    reject([{message: 'Please select at least one '+msgidentifier+' filter from dropdown.'}]);
                }
            })
        );
    }
})