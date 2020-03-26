({
    getCalendarMin: function(component) {
        var year = new Date().getFullYear() - 5;
        //var min = year+'-01-01';
        var min = '2010-01-01';
        component.set("v.calendarMin", min);
    },

    getCalendarMax: function(component) {
        var year = new Date().getFullYear() + 5;
        var max = year + '-12-31';
        component.set("v.calendarMax", max);
    },
    setBUCustomSettings: function(component) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.saveBusinessUnitCustomSettings');
            action.setParams({
                BusinessUnit: component.get('v.selectedBusinessUnitFilter')
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log(response.getReturnValue());
                } else if (state === 'ERROR') {
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
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

    getData: function(component) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.getData');
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate'),
                BusinessUnit: component.get("v.selectedBusinessUnitFilter"),
                typeOfLoan: component.get("v.selectedTypeOfLoanFilter")
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('getData returns this result:');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                } else if (state === 'ERROR') {
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    getReportCongaURL: function(component) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.getDrawdownCongaURLs');
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('drawdown report view all.');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                } else if (state === 'ERROR') {
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    setDateCustomSettings: function(component) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.saveDateCustomSettings');
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate')
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('The start date and end date in custom settings have been updated.');
                    console.log(response.getReturnValue());
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

    getPickListValues: function(component, object, field, attributeId) {
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });


        picklistgetter.setCallback(this, function(response) {
            var opts = [];
            if (response.getState() == 'SUCCESS') {
                var allValues = response.getReturnValue();
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
            }
        });
        $A.enqueueAction(picklistgetter);
    }
})