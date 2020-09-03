import { LightningElement, api, track } from 'lwc';
import getDrawdown from '@salesforce/apex/DrawdownHelper.getDrawdown';
import updateOpportunityPayoutDate from '@salesforce/apex/DrawdownHelper.updateOpportunityPayoutDate';


export default class rejectedPaymentFromClientForm extends LightningElement {
    @api recordId;
    @api drawdownToReverseId;
    @track drawdown;
    @track checkNumber;

    @track loading = false;
    nsfVisible = true;

    connectedCallback() {        
        getDrawdown({drawdownId: this.drawdownToReverseId})
            .then(result => {
                this.drawdown = result;                                
            }
        );            
    }

    onReasonForReversingChnage(event){
        this.nsfVisible = event.target.value == 'NSF Cheque';
    }

    onCheckNumberChange(event){
        this.checkNumber = event.target.value;
        this.validateFields();
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

    validateFields(){
        let isValid = true;
        let checkNumber = this.template.querySelector(".check-number");
        if (!checkNumber.value){
            checkNumber.setCustomValidity('Please specify Check # or short note explaining reason for reversing payment');
            checkNumber.reportValidity();
            isValid = false;
        }
        else{
            checkNumber.setCustomValidity('');
            checkNumber.reportValidity();
        }

        return isValid;
    }

    updateAndSubmitFields(fields){               
        fields.Opportunity__c = this.drawdown.Opportunity__c;        
        fields.Date__c = this.drawdown.Date__c;
        fields.Amount__c = this.drawdown.Amount__c;
        fields.Principal_Reversed__c = this.drawdown.Amount__c;
        fields.Payment_To_Reverse__c = this.drawdown.Id;
        fields.Reason_to_Reverse_Payment_NSF__c = fields.Reason_to_Reverse_Payment_NSF__c;        
        if (fields.Reason_to_Reverse_Payment_NSF__c == 'NSF Cheque'){        
            fields.Payment_Method__c = 'Cheque';                        
            fields.NSF_Fee__c = fields.NSF_Fee__c;
        }
        else{
            fields.Payment_Method__c = 'e-Transfer';            
        }
        fields.Reference_Notes__c = 'Payment to Client';
        fields.EFT__c = fields.Reason_to_Reverse_Payment_NSF__c;
        fields.CHQ__c = this.checkNumber;                                
        fields.Opportunity_Service_Provider__c = this.drawdown.Opportunity_Service_Provider__c;        
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting
        if (!this.validateFields())
            return;
        this.loading = true;        
        const fields = event.detail.fields;
        updateOpportunityPayoutDate({opportunityId: this.drawdown.Opportunity__c, payoutDate: this.drawdown.Date__c})
            .then(result => {             
                getDrawdown({drawdownId: this.drawdownToReverseId})
                    .then(res=> {
                        this.updateAndSubmitFields(fields);
                    }
                );                  
            }
        );         
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