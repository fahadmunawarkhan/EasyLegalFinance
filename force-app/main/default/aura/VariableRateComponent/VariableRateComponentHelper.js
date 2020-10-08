({
    populateVariableRateTableColumns: function(component){
        component.set("v._variableRateColumns", [
            {label: 'Period', type: 'text', editable: true, align: 'left'},
            {label: 'Interest Rate', type: 'currency', editable: true, align: 'right'},
            {label: '', type: 'text', false: true, align: 'left'},
        ]);
    },
	runAction: function(component, actionName, params){                
        var action = component.get(actionName); 
        var self = this;
        return new Promise($A.getCallback(
            function(resolve, reject){        
                action.setParams(params)                        
                action.setCallback(this, function (response) {
                    var state = response.getState();                                
                    if (state === 'SUCCESS') {                
                        resolve(response.getReturnValue()); 
                    } else if (state === 'ERROR') {                        
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action); 
            }
        ));
    },             
    loadVariableRateData: function(component){              
        var recordId = component.get("v.recordId");            
        var accountId = component.get("v.accountId");                      
        return this.runAction(component, 'c.getVariableRateInfo', { oppId: recordId, accountId: accountId});            
	},
    populateVariableRateTableData: function(component){            
        var data = [];
		this.loadVariableRateData(component)
        .then(
            (result) => {
                for (var i = 0; i < result.length; i++){
                	var variableRate = result[i];
                	var period = 'Months ' + variableRate.periodStart;
                	if (variableRate.periodEnd){
                		console.log(variableRate.periodEnd);
                		period += '-' + variableRate.periodEnd;
            		}
            		else if (i == result.length - 1)
            			period += '+';
                	var items = [
                        { value: 'Months ', align: 'left', type: 'period', editable: true, bold: false, hideEditButton: true, periodStart: variableRate.periodStart, periodEnd: variableRate.periodEnd, label: 'End Month' },
                        { value: variableRate.rate, align: 'right', type: 'percentage', editable: true, bold: false, hideEditButton: true, label: 'Interest Rate' },
                        { value: '', align: 'left', type: 'none', editable: false, hideEditButton: true, hideDeleteButton: (i == result.length - 1 ? false : true)}
            		];
            		var row = {id: variableRate.Id, items: items};
            		data.push(row);
				}
				data.push({id: '', items: [{type: 'link', editMode: false, align: 'left', linklabel: 'Add Row', linkname: 'addRow', isAddRowLink: true},
                                           {editMode: false, type: 'none'}, {editMode: false, type: 'none'}]});
        		component.set("v._variableRateData", data);
            },
            (errors) => {
                this.handleErrors(errors);
            }
        );
    },
    loadVariableRateInfo : function(component){
        var recordId = component.get("v.recordId");
    	this.populateVariableRateTableColumns(component);
        this.populateVariableRateTableData(component);
        console.log(component.get("v._variableRateData"));
	},
    removeRow : function(component, rowIndex){                    
        var tableComp = component.find('variableratetable');
        var data = tableComp.getData();
        data.splice(rowIndex, 1);
        for (var i = 0; i < data.length; i++){
            if (i == data.length - 2){
                var columnCount = data[i].items.length;
                if (columnCount > 0)                    
                    data[i].items[columnCount - 1].hideDeleteButton = false;
            }
        }		
        tableComp.setData(data);    
    },
    addRow : function(component){                    
        var tableComp = component.find('variableratetable');
        var data = tableComp.getData();
        var periodStart = 1;

        if (data.length > 1){
            var columnCount = data[data.length-2].items.length;
            if (columnCount > 0){
                data[data.length-2].items[columnCount - 1].hideDeleteButton = true;
                if (!data[data.length-2].items[0].periodEnd)
                    data[data.length-2].items[0].periodEnd = data[data.length-2].items[0].periodStart;
              	periodStart = Number.parseInt(data[data.length-2].items[0].periodEnd) + 1;
            }
        }
        var items = [
            { value: 'Months ', align: 'left', type: 'period', editable: true, bold: false, hideEditButton: true, label: 'End Month', periodStart: periodStart },
            { value: 0.0, align: 'right', type: 'percentage', editable: true, bold: false, hideEditButton: true, label: 'Interest Rate' },
            { value: '', align: 'left', type: 'none', editable: false, hideEditButton: true, hideDeleteButton: false}
        ];
        var row = {id: '', items: items};
        data.splice(data.length-1, 0, row);
        tableComp.setData(data);    
    },   
	handleCellChanged : function(component, event){ 
        console.log('handleCellChanged');
        let tableComp = component.find('variableratetable');
        let data = tableComp.getData();
        let rowIndex = event.getParam("rowIndex");         
        if (data.length > 1 && rowIndex < data.length - 1){
            if (data[rowIndex].items[0].periodEnd){
                let newPeriodEnd = Number.parseInt(data[rowIndex].items[0].periodEnd);
                let i = rowIndex + 1;
                let rowsToDelete = 0;
                for (let i = rowIndex + 1; i < data.length; i++){
                    if (data[i].items[0].periodEnd){
                        let periodEnd = Number.parseInt(data[i].items[0].periodEnd);
                        console.log(periodEnd + ' '  + newPeriodEnd);
                        if (periodEnd <= newPeriodEnd)
                            rowsToDelete += 1;
                        else break;
                    }
                    else break;
                }
                console.log(rowsToDelete);
                if (rowsToDelete > 0)
                    data.splice(rowIndex + 1, rowsToDelete);
                if (rowIndex < data.length - 1){                
                    if (data[rowIndex+1].items[0].periodStart != newPeriodEnd + 1)
                        data[rowIndex+1].items[0].periodStart = newPeriodEnd + 1;
                }
            }
            else
                data.splice(rowIndex + 1, data.length - rowIndex - 2);
        }
        tableComp.setData(data); 
    },
    save : function(component){                    
        var recordId = component.get("v.recordId");
        var accountId = component.get("v.accountId");
        var action = component.get('c.getVariableRateInfo');
        var data = component.get('v._variableRateData');        
        var vrInfos = [];
        for (let i = 0; i < data.length-1;i++){
            var info = {};
            var items = data[i].items;                  
            info.id = '';
            if (typeof(items[0].periodStart)=='string' && items[0].periodStart=='')
                info.periodStart = null;
            else
            	info.periodStart = items[0].periodStart;
            if (typeof(items[0].periodEnd)=='string' && items[0].periodEnd=='')
                info.periodEnd = null;
            else
            	info.periodEnd = items[0].periodEnd;
            if (typeof(items[1].value)=='string' && items[1].value=='')
                info.rate = null;
            else
            	info.rate = items[1].value;            
            vrInfos.push(info);            
        }        
        if (vrInfos.length > 0){
            console.log(vrInfos);
            this.runAction(component, 'c.saveVariableRates', { oppId: recordId, vrInfos: vrInfos})
            .then(
                (result) => {                    
                    this.showToast('SUCCESS','SUCCESS','SUCCESS');
                    this.populateVariableRateTableData(component);
                },
                (errors) => {
                    console.log(errors);                    
                    if (errors) {
                    	if (errors[0] && errors[0].message) {
                    		this.errorsHandler(errors)
                		}
                	} else {
                    	this.unknownErrorsHandler();
                	}                
                }
           );
        }                
    },
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    handleErrors : function(errors){
        if (errors) {
            if (errors[0] && errors[0].message) {
                this.errorsHandler(errors)
    	}
        } else {
            this.unknownErrorsHandler();
        }
	},    
    unknownErrorsHandler : function(){
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error'); 
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