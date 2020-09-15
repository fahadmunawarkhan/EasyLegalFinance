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
    setDefaultTypeOfLoan : function(component){
        let selectedTypeOfLoanFilter = [];
        selectedTypeOfLoanFilter.push({Id:"Facility Loan",Name:"Facility Loan"});
        component.set("v.selectedTypeOfLoanFilter", selectedTypeOfLoanFilter);  
    },
    setDefaultBussinessUnit: function(component){
        let selectedBusinessUnitFilter = [];
        selectedBusinessUnitFilter.push({Id:"ELFI",Name:"ELFI"});
        component.set("v.selectedBusinessUnitFilter", selectedBusinessUnitFilter); 
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

                /*if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "All",
                        value: "All"
                    });
                }*/
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
    getTypeofLoanPickList : function(component, object, field, attributeId, selectedFilterValue){
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

    getAmountGroupByLawyer: function(component) {
        let typeofloanArr = this.getSelectedTypeOfLoanArr(component, "");
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "");
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.getAmountGroupByLawyer');
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate'),
                field: component.get('v.sortField'),
                direction: component.get('v.sortOrder'),
                BusinessUnit: businessunitArr,
                searchByName: component.get('v.searchByName'),
                typeOfLoan: typeofloanArr
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('Amount for Law firm in helper.');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                } else if (state === 'ERROR') {
                    console.log('Amount for Law firm in helper ERROR.');
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    getReportCongaURL: function(component) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.getDrawdownLawyerSalesCongaURLs');
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
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "'");
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.saveCustomSettings');
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate'),
                businessUnit: businessunitArr,
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

    GetFileTotalAndAmountTotalForLawyer: function(component) {
        var paymentData = component.get('v.AmountByLawyer');
        // calculate financial summary total for file and amount
        // calculate financial summary total for file and amount
        var fileTotal = 0;
        var ClosedFileTotal = 0;
        var OpptyTotal = 0;
        var ClosedAmtTotal = 0;
        var amountTotal = 0;

        var BadDebtTotal = 0,
            BadDebtAmtTotal = 0.0,
            ShortfallTotal = 0,
            ShortfallAmtTotal = 0.0,
            OverageTotal = 0,
            OverageAmtTotal = 0.0;
        
        var ActiveFileTotal = 0,
            AdminFeeReceivedTotal = 0.0,
            InterestAmtTotal = 0.0;
        
        if(paymentData != null && paymentData != undefined){
            
            for (var i = 0; i < paymentData.length; i++) {
                
                fileTotal += (paymentData[i].FileCount == null) ? 0 : paymentData[i].FileCount;
                ActiveFileTotal += (paymentData[i].ActiveFileCount == null) ? 0 : paymentData[i].ActiveFileCount;
                OpptyTotal += (paymentData[i].OpptyCount == null) ? 0 : paymentData[i].OpptyCount;
                amountTotal += (paymentData[i].Amount == null) ? 0 : paymentData[i].Amount;
                InterestAmtTotal += (paymentData[i].InterestRepaid == null) ? 0 : paymentData[i].InterestRepaid;
                AdminFeeReceivedTotal += (paymentData[i].AdminFeeReceived == null) ? 0 : paymentData[i].AdminFeeReceived;
                //ElfifileTotal += (paymentData[i].elfiFileCount == null) ? 0 : paymentData[i].elfiFileCount;
                //ElfiOpptyTotal += (paymentData[i].elfiOpptyCount == null) ? 0 : paymentData[i].elfiOpptyCount;
                //ElfiamountTotal += (paymentData[i].elfiAmount == null) ? 0 : paymentData[i].elfiAmount;
                
                ClosedAmtTotal += (paymentData[i].ClosedAmount == null) ? 0 : paymentData[i].ClosedAmount;
                //ElfiClosedAmtTotal += (paymentData[i].elfiClosedAmount == null) ? 0 : paymentData[i].elfiClosedAmount;
                //ElfiClosedFileTotal += (paymentData[i].elfiClosedFileCount == null) ? 0 : paymentData[i].elfiClosedFileCount;
                ClosedFileTotal += (paymentData[i].ClosedFileCount == null) ? 0 : paymentData[i].ClosedFileCount;
                
                BadDebtTotal += (paymentData[i].BadDebtFileCount == null) ? 0 : paymentData[i].BadDebtFileCount;
                BadDebtAmtTotal += (paymentData[i].BadDebtAmount == null) ? 0 : paymentData[i].BadDebtAmount;
                ShortfallTotal += (paymentData[i].ShortfallFileCount == null) ? 0 : paymentData[i].ShortfallFileCount;
                ShortfallAmtTotal += (paymentData[i].ShortfallAmount == null) ? 0 : paymentData[i].ShortfallAmount;
                OverageTotal += (paymentData[i].OverageFileCount == null) ? 0 : paymentData[i].OverageFileCount;
                OverageAmtTotal += (paymentData[i].OverageAmount == null) ? 0 : paymentData[i].OverageAmount;
                
                //ElfiBadDebtTotal += (paymentData[i].elfiBadDebtFileCount == null) ? 0 : paymentData[i].elfiBadDebtFileCount;
                //ElfiBadDebtAmtTotal += (paymentData[i].elfiBadDebtAmount == null) ? 0 : paymentData[i].elfiBadDebtAmount;
                //ElfiShortfallTotal += (paymentData[i].elfiShortfallFileCount == null) ? 0 : paymentData[i].elfiShortfallFileCount;
                //ElfiShortfallAmtTotal += (paymentData[i].elfiShortfallAmount == null) ? 0 : paymentData[i].elfiShortfallAmount;
                //ElfiOverageTotal += (paymentData[i].elfiOverageFileCount == null) ? 0 : paymentData[i].elfiOverageFileCount;
                //ElfiOverageAmtTotal += (paymentData[i].elfiOverageAmount == null) ? 0 : paymentData[i].elfiOverageAmount;
                
                /*if(paymentData[i].businessunit == "Rhino"){
                RhinofileTotal += (paymentData[i].file == null) ? 0 : paymentData[i].file;
                RhinoamountTotal += (paymentData[i].amt == null) ? 0 : paymentData[i].amt;
            }else if(paymentData[i].businessunit == "ELFI"){
                ElfifileTotal += (paymentData[i].elfiCount == null) ? 0 : paymentData[i].file;
                ElfiamountTotal += (paymentData[i].amt == null) ? 0 : paymentData[i].amt;
            }*/
            }
        }
        component.set("v.fileTotal", fileTotal);
        component.set("v.ActiveFileTotal", ActiveFileTotal);
        component.set("v.AdminFeeReceivedTotal", AdminFeeReceivedTotal);
        component.set("v.InterestAmtTotal", InterestAmtTotal);
        component.set("v.OpptyTotal", OpptyTotal);
        component.set("v.ClosedFileTotal", ClosedFileTotal);
        //component.set("v.ElfiClosedFileTotal", ElfiClosedFileTotal); 

        component.set("v.ClosedAmtTotal", ClosedAmtTotal);
        //component.set("v.ElfiClosedAmtTotal", ElfiClosedAmtTotal);        
        component.set("v.amtTotal", amountTotal);
        //component.set("v.ElfifileTotal", ElfifileTotal); 
        //component.set("v.ElfiOpptyTotal", ElfiOpptyTotal); 
        //component.set("v.ElfiamtTotal", ElfiamountTotal); 

        component.set("v.BadDebtTotal", BadDebtTotal);
        component.set("v.BadDebtAmtTotal", BadDebtAmtTotal);
        component.set("v.ShortfallTotal", ShortfallTotal);
        component.set("v.ShortfallAmtTotal", ShortfallAmtTotal);
        component.set("v.OverageTotal", OverageTotal);
        component.set("v.OverageAmtTotal", OverageAmtTotal);

        //component.set("v.ElfiBadDebtTotal", ElfiBadDebtTotal);
        //component.set("v.ElfiBadDebtAmtTotal", ElfiBadDebtAmtTotal);
        //component.set("v.ElfiShortfallTotal", ElfiShortfallTotal);
        //component.set("v.ElfiShortfallAmtTotal", ElfiShortfallAmtTotal);
        //component.set("v.ElfiOverageTotal", ElfiOverageTotal);
        //component.set("v.ElfiOverageAmtTotal", ElfiOverageAmtTotal);
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
    },
    getLawyerName : function(component){
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getLawyerName');
                action.setParams({
                    recordId : component.get('v.recordId')
                });
                action.setCallback(this, function(response) {
                    let state = response.getState();
                    if (state === 'SUCCESS') {
                        resolve(response.getReturnValue());
                    } else if (state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        )); 
    }
})