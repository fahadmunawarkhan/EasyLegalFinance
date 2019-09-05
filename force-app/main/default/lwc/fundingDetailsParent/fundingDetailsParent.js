import { LightningElement, wire, api, track } from 'lwc';
//import { refreshApex } from '@salesforce/apex';
//import { reduceErrors } from 'c/ldsUtils';

import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
//import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';
//import resetTestInfo from '@salesforce/apex/ScheduledPaymentHelper.resetTestInfo';
//import getOpportunitiesWithScheduledPayments from '@salesforce/apex/FundingDetailsComponentCtlr.getOpportunitiesWithScheduledPayments';
//import { CurrentPageReference } from 'lightning/navigation';
//import { fireEvent } from 'c/pubsub';
import { PERMISSION_CLASSES } from 'c/fundingDetailsUtils';

export default class FundingDetails_Parent extends LightningElement {
    @track permissions = {};
    @track stagingFilters = {preset: 'this_week'};
    @track currentStage = "Staging";

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
        }
    }

    connectedCallback() {
        // TODO - get history from url
    }

    canSendPayments() {
        return this.permissions.EFT_Permission;
    }

    canInputEFTNumbers() {
        return this.permissions.Can_Process_Scheduled_Payments;
    }

    canProcessAndValidateLoan() {
        return this.permissions.Can_Process_Scheduled_Payments;
    }

    canReviewClosedPayments() {
        return this.permissions.Can_Process_Scheduled_Payments;
    }

    /* VISIBILITY SETTERS */
    showStaging() {
        this.currentStage = "Staging"
    }

    showValidateEfts() {
        this.currentStage = "ValidateEfts"
    }

    showBankingSheet() {
        this.currentStage = "BankingSheet"
    }

    showInputEfts() {
        this.currentStage = "InputEfts"
    }

    showValidateCheques() {
        this.currentStage = "ValidateCheques"
    }

    showSendCheques() {
        this.currentStage = "SendCheques"
    }

    showOpportunityTable() {
        this.currentStage = "OpportunityTable"
    }

    showCompletedPayments() {
        this.currentStage = "OpportunityCompletedPayments"
    }
    /* VISIBILITY SETTERS */

    /* VISIBILITY GETTERS */
    get shouldShowSharedFilter() {
        return this.shouldShowStaging || this.shouldShowValidateEfts || this.shouldShowBankingSheet || this.shouldShowValidateCheques || this.shouldShowSendCheques
    }

    get shouldShowStaging() {
        return this.currentStage === "Staging"
    }

    get shouldShowValidateEfts() {
        return this.currentStage === "ValidateEfts"
    }

    get shouldShowBankingSheet() {
        return this.currentStage === "BankingSheet"
    }

    get shouldShowInputEfts() {
        return this.currentStage === "InputEfts"
    }

    get shouldShowValidateCheques() {
        return this.currentStage === "ValidateCheques"
    }

    get shouldShowSendCheques() {
        return this.currentStage === "SendCheques"
    }

    get shouldShowOpportunityTable() {
        return this.currentStage === "OpportunityTable"
    }

    get shouldShowOpportunityCompletedPayments() {
        return this.currentStage === "OpportunityCompletedPayments"
    }
    /* VISIBILITY GETTERS */

    handleFilterInitialized(event) {
        // Get Active Tab
        // Refresh Active Tab
        this._filters = {...event.detail};
        this.filterInitilized = true;
        if (this.resourcesInitialized) {
            this.refresh();
        }
    }

    handleStagingFilterChange(event) {
        this.stagingFilters = event.detail || {};
    }

    refreshStagingArea() {
        const tab = this.template.querySelector('c-funding-details-staging-area');
        if (tab)
            tab.refresh();
    }

    refreshValidateEfts() {
        const tab = this.template.querySelector('c-funding-details-validate-efts.eft');
        if (tab)
            tab.refresh();
    }

    refreshBankingSheet() {
        const tab = this.template.querySelector('c-funding-details-update-and-generate-banking-sheet');
        if (tab)
            tab.refresh();
    }

    refreshValidateCheques() {
        const tab = this.template.querySelector('c-funding-details-validate-efts.cheque');
        if (tab)
            tab.refresh();
    }

    refreshSendCheques() {
        const tab = this.template.querySelector('c-funding-details-send-cheques');
        if (tab)
            tab.refresh();
    }

    refreshOpportunityTable() {
        const tab = this.template.querySelector('c-funding-details-opportunity-table');
        if (tab)
            tab.refresh();
    }

    refreshClosedPayments() {
        const tab = this.template.querySelector('c-funding-details-completed-payments');
        if (tab)
            tab.refresh();
    }

}