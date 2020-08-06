import { LightningElement, api, track, wire } from 'lwc';
import generateBankingSheet from '@salesforce/apex/FundingDetailsComponentCtlr.generateBankingSheet';

import { showToast } from 'c/showToast';
import { generateDataTableErrors } from 'c/ldsUtils';
import {
    download,
    loadGlobalCss,
    //sendScheduledPaymentsChangedEvent,
    //updateFlattenedListFromResult,
    updateScheduledPaymentsFromDraftValues,
    //sendNeedsRefreshEvent,
    PERMISSION_CLASSES,
    combineData,
    //updateSPList,
    groupPayments
} from 'c/fundingDetailsUtils';
import getCWBSheetNumbers from '@salesforce/apex/FundingDetailsComponentCtlr.getCWBSheetNumbers';
import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';
import getCWBFileSettings from '@salesforce/apex/FundingDetailsComponentCtlr.getCWBFileSettings';
import getCurrentUserInfo from '@salesforce/apex/FundingDetailsComponentCtlr.getCurrentUserInfo';
import updateCWBFileSettings from '@salesforce/apex/FundingDetailsComponentCtlr.updateCWBFileSettings';

export default class FundingDetailsUpdateAndGenerateBankingSheet extends LightningElement {
    sheetNumbersOptions = [
        {label: 'All', value: 'All'}
    ];
    _filters = {
        preset: 'this_week'
    }
    _fileType = 'CWB - EFT';
    _businessUnit = 'ELFI';
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
    @api 
    get filetype(){
        return this._fileType;
    }
    set filetype(value){
        this._fileType = value || this._fileType;
        this.refresh();
    }
    @api
    get businessunitfilter(){
        return this._businessUnit;
    }
    set businessunitfilter(value){
        this._businessUnit = value || this._businessUnit;
        this.refresh();
    }
    @api selectedSheetNumber = 'All';
    get sheetNumbersOptions() {
        return this.sheetNumbersOptions;
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
    @track isModalOpen = false;
    @api cwbFileSetting;

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
        }
    }

    @track flattenedList;
    @track loading = true;
    confirmed = true;
    @track bankingSheetText = 'Generate Banking Sheet';

    @track columns = [
        { label: 'Verified', fieldName: 'Verified_By__r.Name', sortable: true },
        { label: 'Can Send', fieldName: 'Can_Send_to_Bank__c', type:'boolean', sortable: true },
        { label: 'Notes', fieldName: 'Notes__c', type: 'helptext' },
        { label: 'Client Account', fieldName: 'opportunity.Account.Id', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Account.Name'}}, sortable: true },
        { label: 'File #', fieldName: 'opportunity.Account.Id', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Account.AccountNumber'}}, sortable: true },
        //{ label: 'Payment Account', fieldName: 'Current_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Account_Name__c'}}, sortable: true },
        //{ label: 'Bank Account', fieldName: 'Current_Bank_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Bank_Account_Name__c'}}, sortable: true },
        { label: 'Opportunity #', fieldName: 'opportunity.Id', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Loan_Requests__c'}}, sortable: true },
        { label: 'Payment Type', fieldName: 'Payment_Type__c', sortable: true },
        { label: 'Admin Fee', fieldName: 'Expected_Admin_Fee_Amount__c', type: 'currency', sortable: true },
        { label: 'Scheduled Date', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { label: 'Available Credit', fieldName: 'opportunity.Loan_Available_to_Drawdown__c', type: 'currency', sortable: true },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
        { label: 'Sheet#', fieldName: 'CWB_Sheet_Number__c', type: 'text', sortable: true, editable: false, cellAttributes: { class: { fieldName: 'CWB_Sheet_Number_CSS__c' } } },
    ];
    @track errors;
    @track sortedBy = 'Scheduled_Date__c';
    @track sortedDirection = 'asc';

    filterInitilized = true;
    resourcesInitialized = false;
    dt; // dataTable reference

    connectedCallback() {
        if (!this.resourcesInitialized) {
            this.loading = true;
            loadGlobalCss(this);
            this.resourcesInitialized = true;
            if (this.filterInitilized) {
                this.refresh();
            }
        }
    }

    @track currentUser;

    handleSheetNumberChange(event){
        this.selectedSheetNumber = event.detail.value;        
        this.refresh();
    }
    @api refresh() {
        this.loading = true;

        getCurrentUserInfo().then(
            result =>{
                this.currentUser = result;
            }
        ).catch(error => {
            this.loading = false;
            this.error = error;
            this.data = undefined;
            this.spList = undefined;
            this.oppList = undefined;
            this.selectedScheduledPayment = undefined;
            this.selectedOpportunity = undefined;
        });

        //this.selectedAll = false; // Seems to be bugging out, maybe a bug in LWC rendering?
        //this.selectAllText = 'Select All';
        let options = {
            startDate: this.filters.startDate,
            endDate: this.filters.endDate,
            workflowStage: 'generateBankingSheet',
            businessUnitFilter : this._businessUnit,
            //dateField: 'Sent_to_Bank_Date__c'
        };

        getCWBSheetNumbers(options).then(result => {
            let opts = [];
            opts.push({label : 'All', value: 'All'});
            for(let i = 0; i<result.length; i++){
                if(result[i] != null)
                    opts.push({label : result[i], value: result[i]})
            }

            this.sheetNumbersOptions = opts;
            
            let options = {
                startDate: this.filters.startDate,
                endDate: this.filters.endDate,
                workflowStage: 'generateBankingSheet',
                businessUnitFilter : this._businessUnit,
                //dateField: 'Sent_to_Bank_Date__c'
                fileType: this._fileType,
                fileNumber: this.selectedSheetNumber,
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
                        groupPayments(this.spList)
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

    get dataTable() {
        this.dt = this.dt || this.template.querySelector('c-funding-details-datatable-wrapper');
        return this.dt;
    }

    get canConfigCWBSheetNumbers(){
        return this.currentUser != undefined && this.currentUser != null? this.currentUser.Can_Configure_CWB_Settings__c : false;
    }

    openModal() {
        getCWBFileSettings().then(result => {
            console.log('CWB File Settings');
            console.log(result);
            this.cwbFileSetting = result;
            this.isModalOpen = true;
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
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
    updateCWBSheetNumbers() {
        this.loading = true;
        
        let options = {
            cwbFileSetting: this.cwbFileSetting
        };

        updateCWBFileSettings(options).then(
            result =>{
                showToast(this, 
                    'Success',
                    'Sheet Numbers are updated successfully.',
                    'success',
                );
                this.loading = false;
            }
        ).catch(error => {
            this.loading = false;
            this.error = error;
            this.data = undefined;
            this.spList = undefined;
            this.oppList = undefined;
            this.selectedScheduledPayment = undefined;
            this.selectedOpportunity = undefined;
        });

        this.isModalOpen = false;
    }

    handleFieldChange(event){
        this.template.querySelectorAll('lightning-input').forEach(each => {
           if(each.name != undefined && each.name != null){
               if(each.name == 'ELFIFileNumber'){
                   this.cwbFileSetting.ELFI_File_Number__c = each.value;
               }else if(each.name == 'RhinoFileNumber'){
                this.cwbFileSetting.Rhino_File_Number__c = each.value;
               }else if(each.name == 'SeaholdFileNumber'){
                this.cwbFileSetting.Seahold_File_Number__c = each.value;
               }
           }
        });
    }

    /*
    handleSave(event) {
        this.loading = true;
        this.errors = undefined;
        updateScheduledPaymentsFromDraftValues(event.detail.draftValues)
            .then(result => {
                showToast(this, 
                    'Successfully Saved Scheduled Payments',
                    'You may now generate an updated Banking Sheet',
                    'success'
                );
                this.confirmed = true;
                this.setBankingSheetText();
                this.spList = [...updateSPList(this.spList, result)];
                //sendScheduledPaymentsChangedEvent(this, result);
                this.dataTable.draftValues = [];
                this.loading = false;
            })
            .catch(error => {
                this.loading = false;
                if (error && error.body && error.body.message) {
                    this.dataTable.generateErrors(error.body.message);
                } else {
                    showToast(this, 
                        'There was an error',
                        JSON.stringify(error),
                        'error',
                        'sticky'
                    );
                }
            });
        this.saveDraftValues = event.detail.draftValues;
    }

    handleCancel(event) {
        this.errors = undefined;
    }
    */

    setBankingSheetText() {
        if (this.confirmed) {
            this.bankingSheetText = 'Generate Banking Sheet';
        } else {
            this.bankingSheetText = 'I confirm that this data is accurate';
        }
    }

    handleBankingSheetClick(event) {
        /*
        if (this.dataTable && this.dataTable.draftValues.length) {
            showToast(this, 
                'Unsaved Changes',
                'You have unsaved changes. Please either cancel or save them before continuing.',
                'warning'
            );
        } else */
        if (!this.confirmed) {
            this.confirmed = true;
            this.setBankingSheetText();
        } else {
            this.generateBankingSheet();
        }
    }

    get datatables() {
        return this.template.querySelectorAll('c-funding-details-datatable');
    }

    @track selectedAll = false;
    @track selectAllText = "Select All"
    toggleSelectAll() {
        const dts = this.datatables;
        this.selectedAll = !this.selectedAll;
        if (this.selectedAll) {
            this.selectAllText = 'Unselect All';
            dts.forEach(dt => {
                dt.selectedRows = dt.data.map(row => row.Id);
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

    generateBankingSheet() {
        this.errors = undefined;
        let spIds = this.getSelectedIds();

        if (spIds.length === 0) {
            showToast(
                this,
                'No Payments Selected',
                'Please select the payments you want included before generating the banking sheet.',
                'warning'
            )
        }else if(this._fileType == 'None'){
            alert("Please select a file type for which you want to generate a banking sheet from dropdown.");
            
        }else if(this._businessUnit == 'All' && this._fileType == 'CWB - EFT'){
            showToast(
                this,
                'Business unit Error.',
                'Business unit can not be "All" while generating CWB - EFT file. Please select a specific business unit from dropdown.',
                'warning'
            )

        } else {

            let generateSheet = true;

            if (this._fileType == 'CWB - EFT' && confirm('Are you sure you want to generate a banking sheet for CWB, If this is for any other bank please select "TD - EFT / Other" from options.\n\nDo you want to continue?')) {
                generateSheet = true;
            } else if (this._fileType == 'CWB - EFT'){
                generateSheet = false;
            }

            if(generateSheet){

                this.loading = true;
                generateBankingSheet({spIds: spIds, fileType : this._fileType, businessUnitFilter : this._businessUnit})
                    .then(result => {
                        showToast(this, 
                            'Successfully generated banking sheet',
                            'The payments have been marked as \'Sent to Bank\', and can be further processed now.',
                            'success',
                        );

                        // trigger download of banking sheet file
                        download(`bankingSheet-${new Date().toISOString()}.txt`, result);

                        // call for refresh of data
                        //sendNeedsRefreshEvent(this);
                        this.refresh();
                        this.loading = false;
                    })
                    .catch(error => {
                        this.loading = false;
                        if (error && error.body && error.body.message) {
                            //this.dataTable.generateErrors(error.body.message);
                            //const errorsMessage = JSON.parse(error.body.message);
                            //this.datatables
                            let allData = [];
                            this.datatables.forEach(dt => {
                                allData = allData.concat(dt.data);
                            });
                            console.log(JSON.stringify(error));
                            this.errors = generateDataTableErrors(JSON.parse(error.body.message), allData);
                            this.datatables.forEach(dt => {
                                dt.errors = this.errors;
                            });
                            showToast(this, 
                                'Unable to generate banking sheet',
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

}