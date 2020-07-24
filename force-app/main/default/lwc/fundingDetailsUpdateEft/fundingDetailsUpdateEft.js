import { LightningElement, api, track, wire } from 'lwc';
//import generateBankingSheet from '@salesforce/apex/FundingDetailsComponentCtlr.generateBankingSheet';

import { showToast } from 'c/showToast';
import { generateDataTableErrors } from 'c/ldsUtils';
import {
    loadGlobalCss,
    //sendScheduledPaymentsChangedEvent,
    //sendNeedsRefreshEvent,
    updateScheduledPaymentsFromDraftValues,
    //updateFlattenedListFromResult,
    combineData,
    groupPayments,
    PERMISSION_CLASSES,
    generateObjectFromDraftValue
} from 'c/fundingDetailsUtils';
//import generateDrawdowns from '@salesforce/apex/ScheduledPaymentHelper.generateDrawdowns';
import getCWBSheetNumbers from '@salesforce/apex/FundingDetailsComponentCtlr.getCWBSheetNumbers';
import getSchedulePayments from '@salesforce/apex/FundingDetailsComponentCtlr.getSchedulePayments';
import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';
import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
import moveToProcessStep from '@salesforce/apex/FundingDetailsComponentCtlr.moveToProcessStep';

export default class FundingDetailsUpdateEft extends LightningElement {
    cwbSelected = true;
    fileNumbersOptions = [
        {label: 'All', value: 'All'}
    ];
    _filters = {
        preset: 'all'
    }
    @api 
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value || this._filters;
        if (this.filterInitilized && this.resourcesInitialized) {
            this.refresh();
        }
    }

    @api fileTypeValue = 'CWB - EFT';
    get options() {
        return [
            { label: 'TD - EFT', value: 'TD - EFT' },
            { label: 'CWB - EFT', value: 'CWB - EFT' }
        ];
    }

    @api selectedFileNumber = 'All';
    get fileNumbersOptions() {
        return fileNumbersOptions;
    }

    set setFileNumbersOptions(opts) {
        fileNumbersOptions = opts;
    }

    @track groupedPayments;
    @track data;
    @track spList;
    @track spMap;
    @track oppList;
    @track oppMap;
    @track selectedScheduledPayment;
    @track selectedOpportunity;
    @track permissions;
    @track pageSize = 50;
    @track eftNum;

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
        }
    }
    
    @track flattenedList;
    @track loading = true;
    @track errors;
    @track sortedBy = 'Sent_to_Bank_Date__c';
    @track sortedDirection = 'asc';

    filterInitilized = true;
    resourcesInitialized = false;
    dt; // dataTable reference

    connectedCallback() {
        this.loading = true;
        if (!this.resourcesInitialized) {
            loadGlobalCss(this);
            this.resourcesInitialized = true;
            if (this.filterInitilized) {
                this.refresh();
            }
        }
    }

    handleFileTypeChange(event){
        this.fileTypeValue = event.detail.value;
        this.selectedFileNumber = 'All';
        if(this.fileTypeValue == 'CWB - EFT'){
            this.cwbSelected = true;
        }else{
            this.cwbSelected = false;
            this.selectedFileNumber = '';
        }
        this.refresh();
    }

    handleFileNumberChange(event){
        this.selectedFileNumber = event.detail.value;
        console.log('selectedFileNumber ' + this.selectedFileNumber)
        this.refresh();
    }

    @api refresh() {
        this.loading = true;
        let options = {
            startDate: this.filters.startDate,
            endDate: this.filters.endDate,
            workflowStage: 'updateEFTInfo',
            dateField: 'Sent_to_Bank_Date__c'
        };
        getCWBSheetNumbers(options).then(result => {
            let opts = [];
            opts.push({label : 'All', value: 'All'});
            console.log(JSON.stringify(result));
            for(let i = 0; i<result.length; i++){
                if(result[i] != null)
                    opts.push({label : result[i], value: result[i]})
            }

            this.fileNumbersOptions = opts;

            let options = {
                startDate: this.filters.startDate,
                endDate: this.filters.endDate,
                workflowStage: 'updateEFTInfo',
                dateField: 'Sent_to_Bank_Date__c',
                fileType: this.fileTypeValue,
                fileNumber: this.selectedFileNumber
            };

            getScheduledPaymentsWithOpportunities(options)
            .then(result => {
                this.data = result;
                    combineData(this.data)
                        .then(combinedData => {
                            this.spList = combinedData.spList;
                            this.oppMap = combinedData.oppMap;
                            this.spMap = combinedData.spMap;
                            this.loading = false;
                            this.error = undefined;
                            

                            groupPayments(this.spList, 'Transaction_Reference_Number__c')
                                .then(groupedPayments => {
                                    this.groupedPayments = groupedPayments;
                                    this.loading = false;
                                })
                        });
                })
                .catch(error => {
                    this.loading = false;
                    this.error = error;
                    this.data = undefined;
                    this.spList = undefined;
                    this.oppList = undefined;
                    this.selectedScheduledPayment = undefined;
                    this.selectedOpportunity = undefined;
                });

        }).catch(error => {
            this.loading = false;
            this.error = error;
            this.data = undefined;
            this.spList = undefined;
            this.oppList = undefined;
            this.selectedScheduledPayment = undefined;
            this.selectedOpportunity = undefined;
        });
                
    }

    handleFilterInitialized(event) {
        this._filters = {...event.detail};
        this.filterInitilized = true;
        if (this.resourcesInitialized) {
            this.refresh();
        }
    }

    handleChangeFilterDate(event) {
        this._filters = {...event.detail};
        this.refresh();
        let evt = new CustomEvent('filterchange', {
            detail: {...this.filters}
        });
        this.dispatchEvent(evt);
    }

    get datatables() {
        return this.template.querySelectorAll('c-funding-details-eft-group');
    }

    @track selectedAll = false;
    @track selectAllText = "Select All"
    toggleSelectAll() {
        const dts = this.datatables;
        this.selectedAll = !this.selectedAll;
        if (this.selectedAll) {
            this.selectAllText = 'Unselect All';
            dts.forEach(dt => {
                dt.selectedRows = dt.getData().map(row => row.Id);
            });
        } else {
            this.selectAllText = 'Select All';
            dts.forEach(dt => {
                dt.selectedRows = [];
            });
        }
    }

    getSelectedIds() {
        let spIds = [];
        this.datatables.forEach(dt => {
            spIds = spIds.concat(dt.selectedRows);
        });
        return spIds
    }

    handleEFTChange(event) {
        this.eftNum = event.detail.value;
    }

    handleSetEFTClick(event) {
        // loop over group components and call setEFT on them
        let groups = this.template.querySelectorAll('c-funding-details-eft-group');
        groups.forEach(group => {
            group.setEFT(this.eftNum);
        });
        //this.dt.draftValues = this.draftValues;
    }
    handlePartialRejected(){
        if(this.getSelectedIds() == 0){
            alert('Please select a record first.');
        }else{
            if(this.fileTypeValue == 'CWB - EFT' && this.selectedFileNumber == 'All'){
                alert('Please select a file number form dropdown first.')
            }else{

                let options = {
                    fileNumber: this.selectedFileNumber
                };
                
                this.loading = true;
                this.errors = undefined;
                getSchedulePayments(options).then(result => {
                    
                    const spList = [];
                    this.getSelectedIds().forEach(id => spList.push({
                        Id: id,
                        Status__c: 'Pre Send Validation',
                        Banking_Verified__c: false,
                        Credit_Verified__c: false,
                        Documents_Verified__c: false,
                        BIA_PPSA_LL_Verified__c: false,
                        AFT_File_Number__c : null
                    }));
        
                    if(spList.length == result.length){
                        this.loading = false;
                        showToast(this, 
                            'Selected transaction cannot be marked partial rejected.',
                            'All transactions of a file cannot be partial rejected. There must be atleast one successful transaction.',
                            'error'
                        );

                    }else{
                        updateScheduledPaymentsFromDraftValues(spList)
                            .then(result => {
                                showToast(this, 
                                    'Successfully Reverted Scheduled Payments to \'Pre Send Validation\'',
                                    'You may now generate an updated Banking Sheet',
                                    'success'
                                );
                                this.refresh();
                                //sendNeedsRefreshEvent(this);
                            })
                            .catch(error => {
                                this.loading = false;
                                if (error && error.body && error.body.message) {
                                    //this.dataTable.generateErrors(error.body.message);
                                    this.errors = generateDataTableErrors(JSON.parse(error.body.message), this.spList);
                                    showToast(this, 
                                        'Unable to update EFT Number',
                                        this.errors.table.messages.join('\n'),
                                        'error',
                                        'sticky'
                                    );
                                } else {
                                    showToast(this, 
                                        'There was an error',
                                        JSON.stringify(error),
                                        'error',
                                        'sticky'
                                    );
                                }
                            });
                        }

                }).catch(error => {

                    this.loading = false;
                    if (error && error.body && error.body.message) {
                        //this.dataTable.generateErrors(error.body.message);
                        this.errors = generateDataTableErrors(JSON.parse(error.body.message), this.spList);
                        showToast(this, 
                            'Unable to update EFT Number',
                            this.errors.table.messages.join('\n'),
                            'error',
                            'sticky'
                        );
                    } else {
                        showToast(this, 
                            'There was an error',
                            JSON.stringify(error),
                            'error',
                            'sticky'
                        );
                    }

                });                                
            
            }
        }
    }
    handleFullRejected(){
        if(this.getSelectedIds() == 0){
            alert('Please select a record first.');
        }else{
            if(this.fileTypeValue == 'CWB - EFT' && this.selectedFileNumber == 'All'){
                alert('Please select a file number form dropdown first.')
            }else{

                let options = {
                    fileNumber: this.selectedFileNumber
                };
                
                this.loading = true;
                this.errors = undefined;
                getSchedulePayments(options).then(result => {

                    console.log('1');
                    const spIds = [];
                    this.getSelectedIds().forEach(id => spIds.push(id));
                    console.log('2');
                    const spList = [];
                    for(let i = 0; i < spIds.length; i++){
                        for(let j = 0; j < this.spList.length; j++){
                            if(spIds[i] == this.spList[j].Id && this.selectedFileNumber == this.spList[j].CWB_Sheet_Number__c){
                                spList.push({
                                    Id: this.spList[j].Id,
                                    Status__c: 'Pre Send Validation',
                                    Banking_Verified__c: false,
                                    Credit_Verified__c: false,
                                    Documents_Verified__c: false,
                                    BIA_PPSA_LL_Verified__c: false
                                });
                            }
                        }
                    }
                    console.log('3');

                    if(spList.length != result.length){

                        this.loading = false;
                        showToast(this, 
                            'Error',
                            'Please select all transactions of sheet # ' + this.selectedFileNumber + ' to mark them fully rejected.',
                            'error'
                        );
                    }else{
                        updateScheduledPaymentsFromDraftValues(spList)
                        .then(result => {
                            showToast(this, 
                                'Successfully Reverted Scheduled Payments to \'Pre Send Validation\'',
                                'You may now generate an updated Banking Sheet',
                                'success'
                            );
                            this.refresh();
                            //sendNeedsRefreshEvent(this);
                        })
                        .catch(error => {
                            this.loading = false;
                            if (error && error.body && error.body.message) {
                                //this.dataTable.generateErrors(error.body.message);
                                this.errors = generateDataTableErrors(JSON.parse(error.body.message), this.spList);
                                showToast(this, 
                                    'Unable to update EFT Number',
                                    this.errors.table.messages.join('\n'),
                                    'error',
                                    'sticky'
                                );
                            } else {
                                showToast(this, 
                                    'There was an error',
                                    JSON.stringify(error),
                                    'error',
                                    'sticky'
                                );
                            }
                        });
                    }
                }).catch(error => {
                    this.loading = false;
                    console.log(JSON.stringify(error));
                    if (error && error.body && error.body.message) {
                        //this.dataTable.generateErrors(error.body.message);
                        this.errors = generateDataTableErrors(JSON.parse(error.body.message), this.spList);
                        showToast(this, 
                            'Unable to update EFT Number',
                            this.errors.table.messages.join('\n'),
                            'error',
                            'sticky'
                        );
                    } else {
                        showToast(this, 
                            'There was an error',
                            JSON.stringify(error),
                            'error',
                            'sticky'
                        );
                    }
                });
            }
        }
    }    
    handleSendBack() {
        const spList = [];
        this.getSelectedIds().forEach(id => spList.push({
            Id: id,
            Status__c: 'Pre Send Validation',
            Banking_Verified__c: false,
            Credit_Verified__c: false,
            Documents_Verified__c: false,
            BIA_PPSA_LL_Verified__c: false
        }));

        this.loading = true;
        this.errors = undefined;
        updateScheduledPaymentsFromDraftValues(spList)
            .then(result => {
                showToast(this, 
                    'Successfully Reverted Scheduled Payments to \'Pre Send Validation\'',
                    'You may now generate an updated Banking Sheet',
                    'success'
                );
                this.refresh();
                //sendNeedsRefreshEvent(this);
            })
            .catch(error => {
                this.loading = false;
                if (error && error.body && error.body.message) {
                    //this.dataTable.generateErrors(error.body.message);
                    this.errors = generateDataTableErrors(JSON.parse(error.body.message), this.spList);
                    showToast(this, 
                        'Unable to update EFT Number',
                        this.errors.table.messages.join('\n'),
                        'error',
                        'sticky'
                    );
                } else {
                    showToast(this, 
                        'There was an error',
                        JSON.stringify(error),
                        'error',
                        'sticky'
                    );
                }
            });
    }

    handleSave() {
        // validate that all selected have an EFT_Number__c
        let _draftValues = [];
        let spList = [];
        this.errors = undefined;
        let _errors = {
            rows: {},
            table: {
                title: 'Your entry cannot be saved. Please fix the errors and try again.',
                messages: []
            }
        }

        this.datatables.forEach(dt => {
            _draftValues = _draftValues.concat(dt.draftValues);
            dt.selectedRows.forEach(id => {
                const idx = _draftValues.findIndex(record => {return record.Id === id});
                if (!(idx >= 0) || !(_draftValues[idx].EFT_Number__c)) {
                    // Invalid
                    // Selected a row that does not have an EFT_Number__c set
                    let rowNumber = _draftValues.findIndex(record => {return record.Id === id}) + 1;
                    _errors.rows[id] = {
                        title: `Row ${rowNumber} is invalid`,
                        messages: ['Scheduled Payment needs an EFT # before drawdowns can be created'],
                        fieldNames: ['EFT_Number__c']
                    };
                    _errors.table.messages.push(`Row ${rowNumber} needs an EFT #`);
                } else {
                    // Valid
                    //selectedDraftValues[_draftValues[idx].Id] = _draftValues[idx].EFT_Number__c;
                    spList.push(generateObjectFromDraftValue('Scheduled_Payment__c', _draftValues[idx]))
                }

                dt.errors = _errors;
            });
        })

        if (_errors.table.messages.length) {
            // Invalid
            this.errors = _errors;
        } else {
            // Valid
            // Send selectedDraftValues
            this.loading = true;
            moveToProcessStep({scheduledPayments: spList})
                .then(result => {
                    showToast(this, 
                        'Successfully updated EFT numbers',
                        'The payments have been marked as \'Processed by Bank\', and can be further processed now.',
                        'success',
                    );

                    // call for refresh of data
                    this.refresh();
                    //sendNeedsRefreshEvent(this);
                    this.loading = false;
                })
                .catch(error => {
                    this.loading=false;
                    showToast(this, 
                        'Unable to generate drawdowns',
                        error.body.message,
                        'error',
                        'sticky'
                    );
                });
        }
    }
}