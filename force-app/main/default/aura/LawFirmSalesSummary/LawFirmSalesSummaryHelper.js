({
    getCalendarMin: function(component) {
        var year = new Date().getFullYear() - 5;
        //var min = year+'-01-01';
        var min = '1980-01-01';
        component.set("v.calendarMin", min);
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
    getAmountGroupByLawFirm: function(component) {
        console.log("sortFiels Is ====>");
        console.log(component.get('v.sortField'));

        let typeofloanArr = this.getSelectedTypeOfLoanArr(component, "");
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "");
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.getAmountGroupByLawFirm');
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
        let businessunitArr = this.getSelectedBusinessUnitArr(component, "'");
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.saveCustomSettings');
            action.setParams({
                startDate: component.get('v.startDate'),
                endDate: component.get('v.endDate'),
                businessUnit: businessunitArr
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
        
        var InterestRepaidTotal = 0.0,
            AdminFeeReceivedTotal = 0.0,
            ActiveFileTotal = 0,
            ActivePFileTotal = 0,
            TotalNetAmount = 0.0,
            totalPrincipalAdvanceOpen = 0.0,
            totalPrincipalAdvanceClosed = 0.0,
            totalPrincipalRepaid = 0.0,
            totalROI = 0.0;

        console.log('----');

        for (var i = 0; i < paymentData.length; i++) {
            fileTotal += (paymentData[i].totalFileCount == null) ? 0 : paymentData[i].totalFileCount;
            ActiveFileTotal += (paymentData[i].totalActiveFileCount == null) ? 0 : paymentData[i].totalActiveFileCount;
            closedFileTotal += (paymentData[i].totalClosedFileCount == null) ? 0 : paymentData[i].totalClosedFileCount;
            opptyTotal += (paymentData[i].totalOpptyCount == null) ? 0 : paymentData[i].totalOpptyCount;
            closedAmountTotal += (paymentData[i].totalClosedAmount == null) ? 0 : paymentData[i].totalClosedAmount;
            //amountTotal += (paymentData[i].totalAmount == null) ? 0 : paymentData[i].totalAmount;
            NoBadDebtTotal += (paymentData[i].totalbdfile == null) ? 0 : paymentData[i].totalbdfile;
            BadDebtAmtTotal += (paymentData[i].totalbdamount == null) ? 0 : paymentData[i].totalbdamount;
            ShortFallFileTotal += (paymentData[i].totalShortFallFile == null) ? 0 : paymentData[i].totalShortFallFile;
            ShortFallAmtTotal += (paymentData[i].totalShortFallAmt == null) ? 0 : paymentData[i].totalShortFallAmt;
            OverAgeFileTotal += (paymentData[i].totalOverAgeFile == null) ? 0 : paymentData[i].totalOverAgeFile;
            OverAgeAmtTotal += (paymentData[i].totalOverAgeAmt == null) ? 0 : paymentData[i].totalOverAgeAmt;
            InterestRepaidTotal += (paymentData[i].totalInterestRepaid == null) ? 0 : paymentData[i].totalInterestRepaid;
            AdminFeeReceivedTotal += (paymentData[i].totalAdminFeeReceived == null) ? 0 : paymentData[i].totalAdminFeeReceived;
            ActivePFileTotal += (paymentData[i].ActivePartialFileCount == null) ? 0 : paymentData[i].ActivePartialFileCount;
            TotalNetAmount += (paymentData[i].NetAmount == null) ? 0 : paymentData[i].NetAmount;
            totalPrincipalAdvanceOpen += (paymentData[i].PrincipalAdvancedOpen == null) ? 0 : paymentData[i].PrincipalAdvancedOpen;
            totalPrincipalAdvanceClosed += (paymentData[i].PrincipalAdvancedClosed == null) ? 0 : paymentData[i].PrincipalAdvancedClosed;
            totalPrincipalRepaid += (paymentData[i].PrincipalRepaid == null) ? 0 : paymentData[i].PrincipalRepaid;
            totalROI += (paymentData[i].ROI == null) ? 0 : parseFloat(paymentData[i].ROI);
        }


        component.set("v.fileTotal", fileTotal);
        component.set("v.closedFileTotal", closedFileTotal);
        component.set("v.opptyTotal", opptyTotal);
        component.set("v.closedAmtTotal", closedAmountTotal);
        //component.set("v.amtTotal", amountTotal);
        component.set("v.NoBadDebtTotal", NoBadDebtTotal);
        component.set("v.BadDebtAmtTotal", BadDebtAmtTotal);
        component.set("v.ShortFallFileTotal", ShortFallFileTotal);
        component.set("v.ShortFallAmtTotal", ShortFallAmtTotal);
        component.set("v.OverAgeFileTotal", OverAgeFileTotal);
        component.set("v.OverAgeAmtTotal", OverAgeAmtTotal);
        component.set("v.InterestRepaidTotal", InterestRepaidTotal);
        component.set("v.AdminFeeReceivedTotal", AdminFeeReceivedTotal);
        component.set("v.ActiveFileTotal", ActiveFileTotal);
        component.set("v.ActivePFileTotal", ActivePFileTotal);
        component.set("v.TotalNetAmount", TotalNetAmount);
        
        component.set("v.totalPrincipalAdvanceOpen", totalPrincipalAdvanceOpen);
        component.set("v.totalPrincipalAdvanceClosed", totalPrincipalAdvanceClosed);
        component.set("v.totalPrincipalRepaid", totalPrincipalRepaid);
        component.set("v.totalROI", totalROI/(paymentData.length >0? paymentData.length : 1));
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
    },
    resetGrandTotal: function(component){
        component.set("v.fileTotal", 0);
        component.set("v.closedFileTotal", 0);
        component.set("v.opptyTotal", 0);
        component.set("v.closedAmtTotal", 0.0);
        //component.set("v.amtTotal", amountTotal);
        component.set("v.NoBadDebtTotal", 0);
        component.set("v.BadDebtAmtTotal", 0.0);
        component.set("v.ShortFallFileTotal", 0);
        component.set("v.ShortFallAmtTotal", 0.0);
        component.set("v.OverAgeFileTotal", 0);
        component.set("v.OverAgeAmtTotal", 0.0);
        component.set("v.InterestRepaidTotal", 0.0);
        component.set("v.AdminFeeReceivedTotal", 0.0);
        component.set("v.ActiveFileTotal", 0);
        component.set("v.ActivePFileTotal", 0);
        component.set("v.TotalNetAmount", 0.0);
        
        component.set("v.totalPrincipalAdvanceOpen", 0.0);
        component.set("v.totalPrincipalAdvanceClosed", 0.0);
        component.set("v.totalPrincipalRepaid", 0.0);
        component.set("v.totalROI", 0);
    }
})