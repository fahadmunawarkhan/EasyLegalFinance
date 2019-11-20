import { LightningElement, api } from 'lwc';

export default class drawdownReversalButton extends LightningElement {
    @api drawdown = null;

    get shouldShowButton() {
        return !!this.drawdown && !!this.drawdown.Can_Be_Reversed__c
    }

    handleClick(event) {
        event.preventDefault();
        const evt = new CustomEvent("reverseclick", {
            detail: {Id: this.drawdown.Scheduled_Payment__c},
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(evt);
    }
}