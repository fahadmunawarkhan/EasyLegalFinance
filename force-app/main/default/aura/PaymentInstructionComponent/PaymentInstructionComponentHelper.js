({
	copyAsRichText : function(component, event) {
        let richText = this.generateRichText(component);        
        let plainText = this.generatePlainText(component);  
        console.log(richText);
        var hiddenInput = document.createElement("input");
        hiddenInput.setAttribute("value", richText);
        document.body.appendChild(hiddenInput);
        hiddenInput.select();
        function listener(e) {
            e.clipboardData.setData("text/html", richText);
            e.clipboardData.setData("text/plain", plainText);
            e.preventDefault();
        }
        document.addEventListener("copy", listener);
        document.execCommand("copy");
        document.body.removeChild(hiddenInput);                
        document.removeEventListener("copy", listener);
	},
    generatePlainText : function(component){
        let paymentInfo = component.get("v.paymentInfo");
        let instruction = 'Payment Instructions\r\n';
        instruction += '\r\n';        
        instruction += 'File Number: ' + paymentInfo.fileNumber + '\r\n';
        instruction += 'Name: ' + paymentInfo.opportunityName + '\r\n';
        instruction += 'Date of payment: ' + paymentInfo.paymentDateString + '\r\n';        
        instruction += '\r\n';
        if (paymentInfo.principal || paymentInfo.interest || paymentInfo.surplus || paymentInfo.shortfallPrincipal || paymentInfo.shortfallInterest){
            instruction += 'Please apply the payment received as follows:\r\n';
            if (paymentInfo.principal)
                instruction += '	• Principal: $' + paymentInfo.principal + '\r\n';
            if (paymentInfo.interest)
                instruction += '	• Interest: $' + paymentInfo.interest + '\r\n';
            if (paymentInfo.surplus)
                instruction += '	• Surplus: $' + paymentInfo.surplus + '\r\n';
            if (paymentInfo.shortfallPrincipal)
                instruction += '	• Shortfall Principal: $' + paymentInfo.shortfallPrincipal + '\r\n';            
            if (paymentInfo.shortfallInterest)
                instruction += '	• Shortfall Interest: $' + paymentInfo.shortfallInterest + '\r\n';                        
            instruction += '\r\n';
        }
		if (paymentInfo.badDebtPrincipal || paymentInfo.badDebtInterest){
            instruction += 'Please write off the following as bad debts:\r\n';
            if (paymentInfo.badDebtPrincipal)
                instruction += '	• Principal: $' + paymentInfo.badDebtPrincipal + '\r\n';
            if (paymentInfo.badDebtInterest)
                instruction += '	• Interest: $' + paymentInfo.badDebtInterest + '\r\n';
            instruction += '\r\n';
        }    
        if (paymentInfo.reserve){
            instruction += 'Please reverse the following reserve:\r\n';
            instruction += '	• Reserve: $' + paymentInfo.reserve + '\r\n';
        }
        if (paymentInfo.badDebtRecovery){
            instruction += 'Please apply as bad debt recovery:\r\n';
            instruction += '	• Bad debt recovery: $' + paymentInfo.badDebtRecovery + '\r\n';
        }
        if (paymentInfo.wireFee){
            instruction += 'Please expense wire fees:\r\n';
            instruction += '	• Wire Fee: $' + paymentInfo.wireFee + '\r\n';
        }        
        instruction += '\r\n\r\n';
        instruction += 'Respectfully,\r\n';
        instruction += 'Easy Legal Finance Team';
        return instruction;
    },
    generateRichText : function(component){
        let paymentInfo = component.get("v.paymentInfo");
        let htmlInstruction = '<div style="font-size: 37px; font-family: Calibri Light, sans-serif;">';        
        htmlInstruction += '<p>Payment Instructions</p>';
        htmlInstruction += '</div>';
        htmlInstruction += '<div style="font-size: 16px; font-family: Calibri, sans-serif;">';
        htmlInstruction += '<br/>';        
        htmlInstruction += 'File Number: ' + paymentInfo.fileNumber + '<br/>';
        htmlInstruction += 'Name: ' + paymentInfo.opportunityName + '<br/>';
        htmlInstruction += 'Date of payment: ' + paymentInfo.paymentDateString + '<br/>';        
        htmlInstruction += '<br/>';
        if (paymentInfo.principal || paymentInfo.interest || paymentInfo.surplus || paymentInfo.shortfallPrincipal || paymentInfo.shortfallInterest){
            htmlInstruction += '<p>Please apply the payment received as follows:</p>';
            htmlInstruction += '<ul>';
            if (paymentInfo.principal)
                htmlInstruction += '<li>Principal: $' + paymentInfo.principal + '</li>';
            if (paymentInfo.interest)
                htmlInstruction += '<li>Interest: $' + paymentInfo.interest + '</li>';
            if (paymentInfo.surplus)
                htmlInstruction += '<li>Surplus: $' + paymentInfo.surplus + '</li>';
            if (paymentInfo.shortfallPrincipal)
                htmlInstruction += '<li>Shortfall Principal: $' + paymentInfo.shortfallPrincipal + '</li>';            
            if (paymentInfo.shortfallInterest)
                htmlInstruction += '<li>Shortfall Interest: $' + paymentInfo.shortfallInterest + '</li>';            
            
            htmlInstruction += '</ul>';
        }
		if (paymentInfo.badDebtPrincipal || paymentInfo.badDebtInterest){
            htmlInstruction += '<p>Please write off the following as bad debts:</p>';
            htmlInstruction += '<ul>';
            if (paymentInfo.badDebtPrincipal)
                htmlInstruction += '<li>Principal: $' + paymentInfo.badDebtPrincipal + '</li>';
            if (paymentInfo.badDebtInterest)
                htmlInstruction += '<li>Interest: $' + paymentInfo.badDebtInterest + '</li>';
            htmlInstruction += '</ul>';
        }    
        if (paymentInfo.reserve){
            htmlInstruction += '<p>Please reverse the following reserve:</p>';
            htmlInstruction += '<ul><li>Reserve: $' + paymentInfo.reserve + '</li></ul>';
        }
        if (paymentInfo.badDebtRecovery){
            htmlInstruction += '<p>Please apply as bad debt recovery:</p>';
            htmlInstruction += '<ul><li>Bad debt recovery: $' + paymentInfo.badDebtRecovery + '</li></ul>';
        }
        if (paymentInfo.wireFee){
            htmlInstruction += '<p>Please expense wire fees:</p>';
            htmlInstruction += '<ul><li>Wire Fee: $' + paymentInfo.wireFee + '</li></ul>';
        }        
        htmlInstruction += '<br/>';
        htmlInstruction += '<div>';
        htmlInstruction += 'Respectfully,<br/>';
        htmlInstruction += 'Easy Legal Finance Team';
        htmlInstruction += '</div>';
        htmlInstruction += '</div>';
        return htmlInstruction;
    },
    sendEmail : function(component){
        console.log('sendEmail');        
        let paymentInfo = component.get("v.paymentInfo");
        var action = component.get('c.emailBookkeeper'); 
        let subject = 'Payment Instructions for ' + paymentInfo.description + ' - ' + paymentInfo.opportunityName;
        let message = this.generateRichText(component);
        var self = this;
        return new Promise($A.getCallback(
            function(resolve, reject){        
                action.setParams({ subject : subject, message : message});                        
                action.setCallback(this, function (response) {
                    var state = response.getState();                                
                    if (state === 'SUCCESS') {                
                        resolve(true); 
                    } else if (state === 'ERROR') {                        
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action); 
            }
        ));
    },
    showToast : function(title, message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
})