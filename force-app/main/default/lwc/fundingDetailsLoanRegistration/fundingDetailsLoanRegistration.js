import { LightningElement, api } from 'lwc';

export default class FundingDetailsLoanRegistration extends LightningElement {
    @api opp;
    @api readOnly = false;

    saveOpportunity(event) {
        // Save the opp...
        // Set the status
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Funding_Details_Status__c = 'Final Review';
        this.template.querySelector("lightning-record-edit-form").submit(fields);
    }

    handleSuccess(event) {
        // send event to update the opp
        const evt = new CustomEvent("opportunitychanged", {
            detail: {Id: this.opp.Id, Funding_Details_Status__c: event.detail.fields.Funding_Details_Status__c.value},
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(evt);
    }
}