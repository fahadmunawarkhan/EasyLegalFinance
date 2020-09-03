import { LightningElement, api } from 'lwc';

export default class drawdownReversalButton extends LightningElement {
    @api drawdown = null;

    get shouldShowButton() {
        return !!this.drawdown && (!!this.drawdown.Can_Be_Reversed__c || this.drawdown.Payment_Can_Be_Reversed__c)
        //return true
    }

    handleClick(event) {
        event.preventDefault();
        const evt = new CustomEvent("reverseclick", {
            detail: {Id: this.drawdown.Id, isPaymentFromClient: this.drawdown.Payment_Can_Be_Reversed__c},
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(evt);
    }
}