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
    },
    getAmountGroupByLawFirm: function(component) {
        console.log("sortFiels Is ====>");
        console.log(component.get('v.sortField'));
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.getAmountGroupByLawFirm');
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate'),
                field: component.get('v.sortField'),
                direction: component.get('v.sortOrder'),
                BusinessUnit: component.get('v.selectedBusinessUnitFilter'),
                searchByName: component.get('v.searchByName'),
                typeOfLoan: component.get("v.selectedTypeOfLoanFilter")
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('Amount for Law firm in helper.');
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
            let action = component.get('c.getDrawdownLawFirmSalesCongaURLs');
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
    setCustomSettings: function(component) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.saveCustomSettings');
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate'),
                businessUnit: component.get('v.selectedBusinessUnitFilter')
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

    GetFileTotalAndAmountTotalForLawFirm: function(component) {
        var paymentData = component.get('v.AmountByLawFirm');
        // calculate financial summary total for file and amount
        var fileTotal = 0;
        var closedFileTotal = 0;
        var opptyTotal = 0;
        var amountTotal = 0;
        var closedAmountTotal = 0;
        var NoBadDebtTotal = 0;
        var BadDebtAmtTotal = 0;
        var ShortFallFileTotal = 0;
        var ShortFallAmtTotal = 0;
        var OverAgeFileTotal = 0;
        var OverAgeAmtTotal = 0;

        console.log('----');

        for (var i = 0; i < paymentData.length; i++) {
            fileTotal += (paymentData[i].totalFileCount == null) ? 0 : paymentData[i].totalFileCount;
            closedFileTotal += (paymentData[i].totalClosedFileCount == null) ? 0 : paymentData[i].totalClosedFileCount;
            opptyTotal += (paymentData[i].totalOpptyCount == null) ? 0 : paymentData[i].totalOpptyCount;
            closedAmountTotal += (paymentData[i].totalClosedAmount == null) ? 0 : paymentData[i].totalClosedAmount;
            amountTotal += (paymentData[i].totalAmount == null) ? 0 : paymentData[i].totalAmount;
            NoBadDebtTotal += (paymentData[i].totalbdfile == null) ? 0 : paymentData[i].totalbdfile;
            BadDebtAmtTotal += (paymentData[i].totalbdamount == null) ? 0 : paymentData[i].totalbdamount;
            ShortFallFileTotal += (paymentData[i].totalShortFallFile == null) ? 0 : paymentData[i].totalShortFallFile;
            ShortFallAmtTotal += (paymentData[i].totalShortFallAmt == null) ? 0 : paymentData[i].totalShortFallAmt;
            OverAgeFileTotal += (paymentData[i].totalOverAgeFile == null) ? 0 : paymentData[i].totalOverAgeFile;
            OverAgeAmtTotal += (paymentData[i].totalOverAgeAmt == null) ? 0 : paymentData[i].totalOverAgeAmt;
        }


        component.set("v.fileTotal", fileTotal);
        component.set("v.closedFileTotal", closedFileTotal);
        component.set("v.opptyTotal", opptyTotal);
        component.set("v.closedAmtTotal", closedAmountTotal);
        component.set("v.amtTotal", amountTotal);
        component.set("v.NoBadDebtTotal", NoBadDebtTotal);
        component.set("v.BadDebtAmtTotal", BadDebtAmtTotal);
        component.set("v.ShortFallFileTotal", ShortFallFileTotal);
        component.set("v.ShortFallAmtTotal", ShortFallAmtTotal);
        component.set("v.OverAgeFileTotal", OverAgeFileTotal);
        component.set("v.OverAgeAmtTotal", OverAgeAmtTotal);
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
    }
})