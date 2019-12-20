({
	doInit : function(component, event, helper) {
		
        component.set("v.spinner", true);
        component.set("v.countSelected",0);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);

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

                component.set("v.businessUnitForDesign", result.Business_Unit__c == null ? 'ELFI' : result.Business_Unit__c);

                return helper.getAssessments(component);
            }
        )).then(
            function(result){
                console.log('----r----');
                console.log(result);
                component.set("v.providerList", result);
                helper.setDefaultDates(component);
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
        component.set("v.countSelected",0);
        helper.getAssessments(component).then($A.getCallback(
            function(result){
                console.log('--DATA--');
                console.log(result[0]);
                component.set("v.providerList", result);
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
            //component.find("selectAllcheckbox").set("v.value", false);
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
        component.set("v.countSelected",0);
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
                component.set("v.providerList", result);
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
        let providerId = event.currentTarget.dataset.attachment;
        let newWin;

        let url = '/lightning/r/Report/00O0L000003mxbSUAQ/view';

        
        try{                       
            newWin = window.open(url + '?fv1=' + providerId);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    check : function(component, event, helper){
        let target =  event.getSource();
        let value = target.get('v.value');
        let countSelected = component.get("v.countSelected");

        if(value){
            if(countSelected >= 10){
                alert('You have selected maximum allowed records.');
                target.set('v.value', !value);
            }else{
                countSelected++;               
            }
        }else{
            countSelected--;
        }
        component.set("v.countSelected", countSelected);

    },
    printReportButtnClick : function(component, event, helper){
        component.set("v.spinner", true);
        
        helper.setCustomSettings(component).then($A.getCallback(
            function(result){
                return helper.getCustomSettings(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.customSetting', result);
                return helper.getDrawdown(component);
            }
        )).then(function(result){            
            component.set('v.drawdown',result);
            let url = result.Conga_Assessment_Provider_Report_Print__c;
            url += '%26'+'DefaultPDF=1';
            let newWin;
            try{                       
                newWin = window.open(url);
            }catch(e){}
            if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
            {
                reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
            }
            component.set("v.spinner", false);

        }).catch(function(errors){
            console.log('Error ' + errors);
            component.set("v.spinner", false);
            helper.errorsHandler(errors);
        });
    },
    viewAllButtnClick : function(component, event, helper){
        component.set("v.spinner", true);
        
        helper.setCustomSettings(component).then($A.getCallback(
            function(result){
                return helper.getCustomSettings(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.customSetting', result);
                return helper.getDrawdown(component);
            }
        )).then(function(result){            
            component.set('v.drawdown',result);
            let url = result.Conga_Assessment_Provider_Report_ViewAll__c;
            let target = event.getSource();

            if(target.get('v.label') == 'View All (PDF)'){
                url += '%26'+'DefaultPDF=1';
            }
            let newWin;
            try{                       
                newWin = window.open(url);
            }catch(e){}
            if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
            {
                reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
            }
            component.set("v.spinner", false);

        }).catch(function(errors){
            console.log('Error ' + errors);
            component.set("v.spinner", false);
            helper.errorsHandler(errors);
        });
        
    },
    generateForSelected : function(component, event, helper){
        if(component.get("v.selectedBusinessUnitFilter") != "Consolidated"){
            helper.generateForSelected(component);
        }else{
            alert("Can not generate payouts for selected business unit. Please select ELFI or Rhino from dropdown.");
        }
                
    },
    GenerateForAll : function(component, event, helper){
        if(component.get("v.selectedBusinessUnitFilter") != "Consolidated"){
            helper.GenerateForAll(component);
        }else{
            alert("Can not generate payouts for selected business unit. Please select ELFI or Rhino from dropdown.");
        }
    },
    downloadAttachment : function(component, event, helper){
        let attachmentId = event.currentTarget.dataset.attachment;
        window.open('/servlet/servlet.FileDownload?file=' + attachmentId + '');
    }
})