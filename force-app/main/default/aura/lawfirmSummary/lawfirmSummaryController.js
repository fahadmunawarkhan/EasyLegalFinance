({
	doInit : function(component, event, helper) {        
        
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        //var endOfMonth = $A.localizationService.formatDate(new Date(2008, today.getMonth() + 1, 0), "YYYY-MM-DD");
        component.set("v.payOutDate", today);
        //component.set("v.endDate", endOfMonth);
        
        /*
        Select Name, Id FROM Account WHERE RecordType.Name = 'Law Firm' AND Id in (SELECT Law_firm__c FROM Opportunity WHERE accountId !=null AND isClosed = true AND isWon = true AND Stage_Status__c != 'Paid Off' )
        */
        
        //search query
        let fieldSet = [];
        fieldSet.push("Id");
        fieldSet.push("Name");        
        fieldSet.push("(Select id from Attachments where name like \'%List of Clients%\' and createddate = today order by createddate desc limit 1 )");
        fieldSet.push("(Select id,createddate from tasks where type='Email' and createddate = today order by createddate desc limit 1 )");
        let strQuery = "SELECT " + fieldSet.join(",");
            strQuery += " FROM Account WHERE RecordType.Name = \'Law Firm\' ";
        component.set("v.query", strQuery); 
        helper.getPickListValues(component, 'Opportunity','Type_of_Loan__c','typeOfLoanOptions');
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.setDefaultDates(component);
        helper.getLawfirmList(component,event);
        
	},
    searchButton: function(component, event, helper) {
        component.set("v.recordSelected", false);
        helper.getLawfirmList(component,event);
    },
    sort: function(component, event, helper) {  
        
        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v.sortOrder');
        let oldField = component.get('v.sortField');
        
        sortOrder = ((sortOrder == 'DESC' && oldField == field) || oldField != field ) ? 'ASC' : 'DESC';
        
        component.set('v.sortField',field);   
        component.set('v.sortOrder',sortOrder);
        component.set("v.recordSelected", false);
        
        helper.getLawyersList(component,event);         
	},
    check:function(component, event, helper) {
        helper.check(component, event);
    },
    sendToSelected: function(component, event, helper) {
        let success = true;
        success = helper.validateEmailRecipient(component);
        if(!success)	return;
        helper.sendToSelected(component);
    },
    sendToIndividual: function(component, event, helper) {
        let success = true;
        success = helper.validateEmailRecipient(component);
        if(!success)	return;
        helper.sendToIndividual(component, event);
    },
    downloadAttachment: function(component, event, helper) {
        let attachmentId = event.currentTarget.dataset.attachment;
        window.open('/servlet/servlet.FileDownload?file=' + attachmentId + '');
    },
    generateForSelected: function(component, event, helper) {
        helper.generateForSelected(component);
    },
    generateBalanceForSelected: function(component, event, helper) {
        helper.generateBalanceForSelected(component);
    },
    hideLookupInput: function(component, event, helper)
    {
        
    },
    openLinkReport : function(component, event, helper){
        
        let lawfirmid = event.currentTarget.dataset.lawfirmid;
        let newWin;
        let url = '/lightning/r/Report/00O3J000000O7gCUAS/view';
        let businessUnitFilter = component.get("v.selectedBusinessUnitFilter");
        try{                       
            newWin = window.open(url + '?fv3=' + lawfirmid.substring(0,15) + '&fv4=' + businessUnitFilter);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    }
})