import { LightningElement, api } from 'lwc';

export default class drawdownReversalButton extends LightningElement {
    @api drawdown = null;

    get shouldShowButton() {
        return !!this.drawdown && !!this.drawdown.Scheduled_Payment__c && this.drawdown.Amount__c && this.drawdown.Amount__c > 0
    }

    handleClick(event) {
        event.preventDefault();
        const evt = new CustomEvent("reverseclick", {
            detail: {Id: this.scheduledPaymentId},
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(evt);
    }
}