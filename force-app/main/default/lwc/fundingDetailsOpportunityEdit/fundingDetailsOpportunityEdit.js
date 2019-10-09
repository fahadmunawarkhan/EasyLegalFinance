import { LightningElement, api, track, wire } from 'lwc';
import updateOpportunity from '@salesforce/apex/FundingDetailsComponentCtlr.updateOpportunity';
import { showToast } from 'c/showToast';
//import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
//import { updateRecord } from 'lightning/uiRecordApi';

const STAGE_CHOICES = [
    'Loan Setup Check',
    'Process Drawdowns',
    'Populate PPSA',
    'Final Review',
    'Closed'
]

export default class FundingDetailsOpportunityEdit extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @track loading = true;

    @track _opp;
    @api
    get opp(){
        return this._opp;
    }
    set opp(value){
        this.loading = true;
        this._opp = value;
        this.buildPathOptions();
        this.loading = false;
    }

    @track pathOptions = []

    @api refresh() {
        console.log('OppEdit.refresh()');
        this.loading = true;
        this.buildPathOptions();
        //this.template.querySelector("c-lightning-path").initOptions();
        this.loading = false;
    }

    buildPathOptions () {
        let pathOptions = [];
        for (const stage of STAGE_CHOICES) {
            let option = {
                label: stage,
                value: stage,
                current: this.opp.Funding_Details_Status__c === stage
            };
            pathOptions.push(option);
        }
        this.pathOptions = pathOptions;
    }

    handleStageComplete(event) {
        // Move opp to next Funding_Details_Status__c
        const currIndex = STAGE_CHOICES.findIndex(option => {return option === this.opp.Funding_Details_Status__c});
        if (currIndex < 0) {
            this.updateOpp({Id: this.opp.Id, Funding_Details_Status__c: STAGE_CHOICES[0]});
        } else if (currIndex < STAGE_CHOICES.length - 1) {
            this.updateOpp({Id: this.opp.Id, Funding_Details_Status__c: STAGE_CHOICES[currIndex + 1]});
        }
    }
    
    handleStageSelected(event) {
        // Move opp to specified Funding_Details_Status__c
        this.updateOpp({Funding_Details_Status__c: event.detail.stage});
    }

    get isLoanSetupCheck() {
        return this.opp.Funding_Details_Status__c === 'Loan Setup Check'
    }

    get isProcessDrawdowns() {
        return this.opp.Funding_Details_Status__c === 'Process Drawdowns'
    }

    get isPopulatePPSA() {
        return this.opp.Funding_Details_Status__c === 'Populate PPSA'
    }

    get isCloseTransaction() {
        return this.opp.Funding_Details_Status__c === 'Final Review'
    }

    updateOpp(payload) {
        // Ensure Id in payload
        payload.Id = this.opp.Id;
        payload.sobjectType = 'Opportunity';
        this.loading = true;
        updateOpportunity({opp: payload})
            .then(result => {
                this.loading = false;
                if (result.Funding_Details_Status__c === 'Closed') {
                    this.fireRemoveOpportunity(result);
                } else {
                    this.fireOpportunityChanged(result);
                    //this.buildPathOptions();
                }
            })
            .catch(error => {
                this.loading = false;
                let message;
                try {
                    message = error.body.message;
                } catch (e) {
                    message = JSON.stringify(error);
                }
                showToast(
                    this,
                    'Unable to update opportunity',
                    message,
                    'error',
                    'sticky'
                );
            })
    }

    fireOpportunityChanged(payload) {
        const evt = new CustomEvent("opportunitychanged", {
            detail: payload
        });
        this.dispatchEvent(evt);
    }

    fireRemoveOpportunity(payload) {
        const evt = new CustomEvent("opportunityremoved", {
            detail: payload
        });
        this.dispatchEvent(evt);
    }

    connectedCallback() {
        console.log('connected');
        // registerListener('opportunityChanged', this.refresh, this);
    }

    disconnectedCallback() {
        // unregisterAllListeners(this);
    }

}