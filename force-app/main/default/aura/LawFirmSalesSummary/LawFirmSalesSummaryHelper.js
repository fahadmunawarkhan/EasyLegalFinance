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

        var rhinofileTotal = 0;
        var rhinoClosedFileTotal = 0;
        var rhinoClosedAmountTotal = 0;
        var rhinoOpptyTotal = 0;
        var rhinoamountTotal = 0;
        var RhinoNoBadDebtTotal = 0;
        var RhinoBadDebtAmtTotal = 0;
        var RhinoShortFallFileTotal = 0;
        var RhinoShortFallAmtTotal = 0;
        var RhinoOverAgeFileTotal = 0;
        var RhinoOverAgeAmtTotal = 0;

        var elfifileTotal = 0;
        var elfiClosedFileTotal = 0;
        var elfiClosedAmountTotal = 0;
        var elfiOpptyTotal = 0;
        var elfiamountTotal = 0;
        var ElfiNoBadDebtTotal = 0;
        var ElfiBadDebtAmtTotal = 0;
        var ElfiShortFallFileTotal = 0;
        var ElfiShortFallAmtTotal = 0;
        var ElfiOverAgeFileTotal = 0;
        var ElfiOverAgeAmtTotal = 0;

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

            rhinofileTotal += (paymentData[i].rhinoFileCount == null) ? 0 : paymentData[i].rhinoFileCount;
            rhinoClosedFileTotal += (paymentData[i].rhinoClosedFileCount == null) ? 0 : paymentData[i].rhinoClosedFileCount;
            rhinoOpptyTotal += (paymentData[i].rhinoOpptyCount == null) ? 0 : paymentData[i].rhinoOpptyCount;
            rhinoClosedAmountTotal += (paymentData[i].rhinoClosedAmount == null) ? 0 : paymentData[i].rhinoClosedAmount;
            rhinoamountTotal += (paymentData[i].rhinoAmount == null) ? 0 : paymentData[i].rhinoAmount;
            RhinoNoBadDebtTotal += (paymentData[i].rhinoBadDebtFile == null) ? 0 : paymentData[i].rhinoBadDebtFile;
            RhinoBadDebtAmtTotal += (paymentData[i].rhinoBadDebtAmount == null) ? 0 : paymentData[i].rhinoBadDebtAmount;
            RhinoShortFallFileTotal += (paymentData[i].rhinoShortFallFile == null) ? 0 : paymentData[i].rhinoShortFallFile;
            RhinoShortFallAmtTotal += (paymentData[i].rhinoShortFallamt == null) ? 0 : paymentData[i].rhinoShortFallamt;
            RhinoOverAgeFileTotal += (paymentData[i].rhinoOverAgeFile == null) ? 0 : paymentData[i].rhinoOverAgeFile;
            RhinoOverAgeAmtTotal += (paymentData[i].rhinoOverAgeamt == null) ? 0 : paymentData[i].rhinoOverAgeamt;

            elfifileTotal += (paymentData[i].elfiFileCount == null) ? 0 : paymentData[i].elfiFileCount;
            elfiClosedFileTotal += (paymentData[i].elfiClosedFileCount == null) ? 0 : paymentData[i].elfiClosedFileCount;
            elfiOpptyTotal += (paymentData[i].elfiOpptyCount == null) ? 0 : paymentData[i].elfiOpptyCount;
            elfiClosedAmountTotal += (paymentData[i].elfiClosedAmount == null) ? 0 : paymentData[i].elfiClosedAmount;
            elfiamountTotal += (paymentData[i].elfiAmount == null) ? 0 : paymentData[i].elfiAmount;
            ElfiNoBadDebtTotal += (paymentData[i].elfiBadDebtFile == null) ? 0 : paymentData[i].elfiBadDebtFile;
            ElfiBadDebtAmtTotal += (paymentData[i].elfiBadDebtAmount == null) ? 0 : paymentData[i].elfiBadDebtAmount;
            ElfiShortFallFileTotal += (paymentData[i].elfiShortFallFile == null) ? 0 : paymentData[i].elfiShortFallFile;
            ElfiShortFallAmtTotal += (paymentData[i].elfiShortFallAmt == null) ? 0 : paymentData[i].elfiShortFallAmt;
            ElfiOverAgeFileTotal += (paymentData[i].elfiOverAgeFile == null) ? 0 : paymentData[i].elfiOverAgeFile;
            ElfiOverAgeAmtTotal += (paymentData[i].elfiOverAgeAmt == null) ? 0 : paymentData[i].elfiOverAgeAmt;
        }

        console.log("ElfiShortFallFileTotal : " + ElfiShortFallFileTotal);
        console.log("ElfiOverAgeFileTotal : " + ElfiOverAgeFileTotal);

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

        component.set("v.RhinofileTotal", rhinofileTotal);
        component.set("v.RhinoClosedFileTotal", rhinoClosedFileTotal);
        component.set("v.RhinoOpptyTotal", rhinoOpptyTotal);
        component.set("v.RhinoClosedAmtTotal", rhinoClosedAmountTotal);
        component.set("v.RhinoamtTotal", rhinoamountTotal);
        component.set("v.RhinoNoBadDebtTotal", RhinoNoBadDebtTotal);
        component.set("v.RhinoBadDebtAmtTotal", RhinoBadDebtAmtTotal);
        component.set("v.RhinoShortFallFileTotal", RhinoShortFallFileTotal);
        component.set("v.RhinoShortFallAmtTotal", RhinoShortFallAmtTotal);
        component.set("v.RhinoOverAgeFileTotal", RhinoOverAgeFileTotal);
        component.set("v.RhinoOverAgeAmtTotal", RhinoOverAgeAmtTotal);

        component.set("v.ElfifileTotal", elfifileTotal);
        component.set("v.ElfiClosedFileTotal", elfiClosedFileTotal);
        component.set("v.ElfiOpptyTotal", elfiOpptyTotal);
        component.set("v.ElfiClosedAmtTotal", elfiClosedAmountTotal);
        component.set("v.ElfiamtTotal", elfiamountTotal);
        component.set("v.ElfiNoBadDebtTotal", ElfiNoBadDebtTotal);
        component.set("v.ElfiBadDebtAmtTotal", ElfiBadDebtAmtTotal);
        component.set("v.ElfiShortFallFileTotal", ElfiShortFallFileTotal);
        component.set("v.ElfiShortFallAmtTotal", ElfiShortFallAmtTotal);
        component.set("v.ElfiOverAgeFileTotal", ElfiOverAgeFileTotal);
        component.set("v.ElfiOverAgeAmtTotal", ElfiOverAgeAmtTotal);
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