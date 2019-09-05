import { LightningElement, api, track } from 'lwc';

export default class ReversePaymentForm extends LightningElement {
    @api recordId;
    @api scheduledPaymentId;
    @api showProcessedFields = false;

    @track loading = false;

    connectedCallback() {
    }

    handleCancel(event) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    alreadyLoaded = false;
    handleLoad(event){
        //this.loading = false;
        if (!this.alreadyLoaded && this.recordId) {
            this.alreadyLoaded = true;
        }
    }

    handleSubmit(event){
        this.loading = true;
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Scheduled_Payment__c = this.scheduledPaymentId;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        this.loading = false;
        event.preventDefault();
        event.stopImmediatePropagation();

        this.dispatchEvent(
            new CustomEvent(
                'success',
                {detail: {...event.detail}}
            ));
    }

    handleError() {
        this.loading = false;
    }

}