({
	doInit : function(component, event, helper) {
		
        component.set("v.spinner", true);
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');

        helper.getDrawdown(component).then(
            function(result){
                component.set('v.drawdown',result);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        component.set("v.spinner", true);
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){ 
                component.set('v.customSetting', result);
                component.set("v.spinner", false);
                return helper.getAssessments(component);
            }
        )).then(
            function(result){
                component.set("v.data", result);
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
	},
    searchButton : function(component, event, helper){
        component.set("v.spinner", true);
        helper.getAssessments(component).then($A.getCallback(
            function(result){
                console.log('--DATA--');
                console.log(result[0]);
                component.set("v.data", result);
                component.set("v.businessUnitForDesign", component.get("v.selectedBusinessUnitFilter"));
                return helper.getDrawdown(component);
            }
        )).then($A.getCallback(
            function(result){
            component.set('v.drawdown',result);
            return helper.getCustomSettings(component);
            }
        )).then(function(result){
            component.set('v.customSetting', result);
            component.set("v.spinner", false);
        }).catch(
            function(errors){
                console.log('Error ' + errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    sort: function(component, event, helper) {  
        
        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v.sortOrder');
        let oldField = component.get('v.sortField');
        
        sortOrder = (sortOrder == 'DESC' && oldField == field) ? 'ASC' : 'DESC';
        
        component.set('v.sortField',field);   
        component.set('v.sortOrder',sortOrder); 
        
        component.set("v.spinner", true);
        
        helper.getAssessments(component).then($A.getCallback(
            function(result){
                console.log('----');
                console.log(result);
                component.set("v.data", result);
                component.set("v.businessUnitForDesign", component.get("v.selectedBusinessUnitFilter"));
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                console.log('Error ' + errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );       
    },
    openLinkReport : function(component, event, helper) { 
        let lawyerId = event.currentTarget.dataset.attachment;
        let newWin;
        let url = '/lightning/r/Report/00O1F000000iWziUAE/view';
        
        try{                       
            newWin = window.open(url + '?fv2=' + lawyerId);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    }
})