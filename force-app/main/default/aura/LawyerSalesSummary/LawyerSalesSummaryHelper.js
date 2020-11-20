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
            InterestAmtTotal = 0.0,
            TotalNetAmount = 0.0,
            TotalActivePartialFileCount = 0,
            PrincipalAdvancedOpen = 0.0,
            PrincipalAdvancedClosed = 0.0,
            TotalNetAmount = 0.0,
            TotalPrincipalRepaid = 0.0,
            TotalROI = 0.0;
        
        if(paymentData != null && paymentData != undefined){
            
            for (var i = 0; i < paymentData.length; i++) {
                
                fileTotal = (paymentData[i].FileCountTotal == null) ? 0 : paymentData[i].FileCountTotal;
                ActiveFileTotal = (paymentData[i].ActiveFileTotal == null) ? 0 : paymentData[i].ActiveFileTotal;
                OpptyTotal = (paymentData[i].OpptyCountTotal == null) ? 0 : paymentData[i].OpptyCountTotal;
                OverageTotal = (paymentData[i].OverageFileTotal == null) ? 0 : paymentData[i].OverageFileTotal;
                ClosedFileTotal = (paymentData[i].ClosedFileTotal == null) ? 0 : paymentData[i].ClosedFileTotal;
                BadDebtTotal = (paymentData[i].BadDebtFileTotal == null) ? 0 : paymentData[i].BadDebtFileTotal;
                ShortfallTotal = (paymentData[i].ShortfallFileTotal == null) ? 0 : paymentData[i].ShortfallFileTotal;
                TotalActivePartialFileCount = (paymentData[i].ActivePartialFileTotal == null) ? 0 : 
                paymentData[i].ActivePartialFileTotal;

                amountTotal += (paymentData[i].PrincipalAdvanced == null) ? 0 : paymentData[i].PrincipalAdvanced;
                PrincipalAdvancedOpen += (paymentData[i].PrincipalAdvancedOpen == null) ? 0 : paymentData[i].PrincipalAdvancedOpen;
                PrincipalAdvancedClosed += (paymentData[i].PrincipalAdvancedClosed == null) ? 0 : paymentData[i].PrincipalAdvancedClosed;
                InterestAmtTotal += (paymentData[i].InterestRepaid == null) ? 0 : paymentData[i].InterestRepaid;
                AdminFeeReceivedTotal += (paymentData[i].AdminFeeReceived == null) ? 0 : paymentData[i].AdminFeeReceived;
                
                ClosedAmtTotal += (paymentData[i].ClosedAmount == null) ? 0 : paymentData[i].ClosedAmount;
                
                
                
                BadDebtAmtTotal += (paymentData[i].BadDebtAmount == null) ? 0 : paymentData[i].BadDebtAmount;
                
                ShortfallAmtTotal += (paymentData[i].ShortfallAmount == null) ? 0 : paymentData[i].ShortfallAmount;
                
                OverageAmtTotal += (paymentData[i].OverageAmount == null) ? 0 : paymentData[i].OverageAmount;
                
                
                TotalNetAmount += (paymentData[i].NetAmount == null) ? 0 : paymentData[i].NetAmount;
                TotalPrincipalRepaid += (paymentData[i].PrincipalRepaid == null) ? 0 : paymentData[i].PrincipalRepaid;
                TotalROI += (paymentData[i].ROI == null) ? 0 : parseFloat(paymentData[i].ROI);
                
                
            }
        }
        console.log('FileTotal has values: ' + fileTotal);
        component.set("v.fileTotal", fileTotal);
        component.set("v.ActiveFileTotal", ActiveFileTotal);
        component.set("v.AdminFeeReceivedTotal", AdminFeeReceivedTotal);
        component.set("v.InterestAmtTotal", InterestAmtTotal);
        component.set("v.OpptyTotal", OpptyTotal);
        component.set("v.ClosedFileTotal", ClosedFileTotal);
        component.set("v.TotalActivePartialFileCount", TotalActivePartialFileCount);
        component.set("v.TotalNetAmount", TotalNetAmount);

        component.set("v.ClosedAmtTotal", ClosedAmtTotal);        
        component.set("v.amtTotal", amountTotal);

        component.set("v.BadDebtTotal", BadDebtTotal);
        component.set("v.BadDebtAmtTotal", BadDebtAmtTotal);
        component.set("v.ShortfallTotal", ShortfallTotal);
        component.set("v.ShortfallAmtTotal", ShortfallAmtTotal);
        component.set("v.OverageTotal", OverageTotal);
        component.set("v.OverageAmtTotal", OverageAmtTotal);

        component.set("v.TotalPrincipalAdvancedOpen", PrincipalAdvancedOpen);
        component.set("v.TotalPrincipalAdvancedClosed", PrincipalAdvancedClosed);
        component.set("v.TotalPrincipalRepaid", TotalPrincipalRepaid);
        component.set("v.TotalROI", TotalROI/(paymentData.length >0? paymentData.length : 1));
        console.log("ROI SUM = " + TotalROI);
        
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
    },
    resetGrandTotal: function(component){
        component.set("v.fileTotal", 0);
        component.set("v.ActiveFileTotal", 0);
        component.set("v.AdminFeeReceivedTotal", 0.0);
        component.set("v.InterestAmtTotal", 0.0);
        component.set("v.OpptyTotal", 0);
        component.set("v.ClosedFileTotal", 0);
        component.set("v.TotalActivePartialFileCount", 0);
        component.set("v.TotalNetAmount", 0.0);

        component.set("v.ClosedAmtTotal", 0.0);        
        component.set("v.amtTotal", 0.0);

        component.set("v.BadDebtTotal", 0);
        component.set("v.BadDebtAmtTotal", 0.0);
        component.set("v.ShortfallTotal", 0);
        component.set("v.ShortfallAmtTotal", 0.0);
        component.set("v.OverageTotal", 0);
        component.set("v.OverageAmtTotal", 0.0);

        component.set("v.TotalPrincipalAdvancedOpen", 0.0);
        component.set("v.TotalPrincipalAdvancedClosed", 0.0);
        component.set("v.TotalPrincipalRepaid", 0.0);
        component.set("v.TotalROI", 0);
    }
})