({
    populateVariableFeeTableColumns: function(component){
        component.set("v._variableFeeColumns", [
            {label: 'Effective At', type: 'combobox', editable: true, align: 'left'},
            {label: 'Month', type: 'number', editable: true, align: 'center'},
            {label: 'Fee Type', type: 'radiogroup', editable: true, align: 'center'},
            {label: 'Amount', type: 'number', editable: true, align: 'right'}            
        ]);
    },
    loadVariableFeeData: function(component){            
        var recordId = component.get("v.recordId");
        var accountId = component.get("v.accountId");
        var  onlyBOM = component.get("v.onlyBOM");        
        return this.runAction(component, 'c.getVariableFeeInfo', { oppId: recordId, accountId: accountId, onlyBOM: onlyBOM});
	},
    getEffectiveAtOptions: function(component){
		var onlyBom = component.get("v.onlyBOM");        
        var effectiveAtOptions = [];
        if (onlyBom){
            effectiveAtOptions.push({label: 'Annual', value: 'Annual'});
            effectiveAtOptions.push({label: 'One Time', value: 'One Time'});
        }
        else{
            effectiveAtOptions.push({label: 'Loan Setup', value: 'Loan Setup'});
            effectiveAtOptions.push({label: 'Annual', value: 'Annual'});
            effectiveAtOptions.push({label: 'One Time', value: 'One Time'});
        }
		return effectiveAtOptions;        
    },
    getFeeTypeOptions: function(){
        return [
                {'label': '%', 'value': '%'},
                {'label': '$', 'value': '$'}];
    },
    populateVariableFeeTableData: function(component){            
        var data = [];
        var feeTypeOptions = this.getFeeTypeOptions();
        var effectiveAtOptions = this.getEffectiveAtOptions(component);
		this.loadVariableFeeData(component)
        .then(
            (result) => {
                for (var i = 0; i < result.length; i++){
                	var variableFee = result[i];
                	var items = [
                		{ value: variableFee.effectiveAt, align: 'left', type: 'combobox', options: effectiveAtOptions, editable: true, bold: false, hideEditButton: true, label: 'Effective At'  },
            			{ value: variableFee.month, align: 'center', type: 'number', editable: true, bold: false, hideEditButton: true, label: 'Month'  },
            			{ value: variableFee.feeType, align: 'center', type: 'radiogroup', editable: true, options: feeTypeOptions, bold: false, hideEditButton: true  },
            			{ value: variableFee.rate, align: 'right', type: variableFee.feeType=='%' ? 'percentage' : 'currency', editable: true, bold: false, hideEditButton: true, label: variableFee.feeType=='%' ? 'Amount %' : 'Amount' },
                        { value: '', align: 'left', type: 'none', editable: false, hideEditButton: true, hideDeleteButton: false}
            		];
            		var row = {id: variableFee.Id, items: items};
            		data.push(row);
				}
				data.push({id: '', items: [{type: 'link', editMode: false, align: 'left', linklabel: 'Add Row', linkname: 'addRow', isAddRowLink: true},
                                           {editMode: false, type: 'none'}, {editMode: false, type: 'none'}, {editMode: false, type: 'none'}, {editMode: false, type: 'none'}]});
        		component.set("v._variableFeeData", data);
            },
            (errors) => {
                this.handleErrors(errors);
            }
        );
    },
    loadVariableFeeInfo : function(component){
        var recordId = component.get("v.recordId");
    	this.populateVariableFeeTableColumns(component);
        this.populateVariableFeeTableData(component);
        console.log(component.get("v._variableFeeData"));
	},
    removeRow : function(component, rowIndex){                    
        var tableComp = component.find('variablefeetable');
        var data = tableComp.getData();
        data.splice(rowIndex, 1);
        tableComp.setData(data);    
    },
    addRow : function(component){                    
        var tableComp = component.find('variablefeetable');
        var data = tableComp.getData();
        var feeTypeOptions = this.getFeeTypeOptions();
        var effectiveAtOptions = this.getEffectiveAtOptions(component);
        var items = [
            { value: effectiveAtOptions[0].value, align: 'left', type: 'combobox', options: effectiveAtOptions, editable: true, bold: false, hideEditButton: true, label: 'Effective At'  },
            { value: '13', align: 'center', type: 'number', editable: true, bold: false, hideEditButton: true, label: 'Month'  },
            { value: feeTypeOptions[0].value, align: 'center', type: 'radiogroup', editable: true, options: feeTypeOptions, bold: false, hideEditButton: true  },
            { value: 0.0, align: 'right', type: feeTypeOptions[0].value=='%' ? 'percentage' : 'currency', editable: true, bold: false, hideEditButton: true, label: feeTypeOptions[0].value=='%' ? 'Amount %' : 'Amount' },
            { value: '', align: 'left', type: 'none', editable: false, hideEditButton: true, hideDeleteButton: false}
        ];
        var row = {id: '', items: items};
        data.splice(data.length-1, 0, row);
        tableComp.setData(data);    
    },  	                
    changeRateType : function(component, rowIndex, feeType){
    	var tableComp = component.find('variablefeetable');
        var data = tableComp.getData();        
        data[rowIndex].items[3].type = feeType == '%' ? 'percentage' : 'currency';        
        data[rowIndex].items[3].label = feeType == '%' ? 'Amount %' : 'Amount';        
        tableComp.setData(data);    
    },
	save: function(component, callback){
        try{
            var recordId = component.get("v.recordId");
            var accountId = component.get("v.accountId");
            var  onlyBOM = component.get("v.onlyBOM");
            var data = component.get('v._variableFeeData');        
            var vfInfos = [];
            for (let i = 0; i < data.length-1;i++){
                var info = {};
                var items = data[i].items;                  
                info.id = '';
                info.effectiveAt = items[0].value;
                if (items[1].value==undefined || (typeof(items[1].value)=='string' && items[1].value==''))
                    info.month = null;
                else
                    info.month = items[1].value;            
                info.feeType = items[2].value;
                if (typeof(items[3].value)=='string' && items[3].value=='')
                    info.rate = null;
                else
                    info.rate = items[3].value;                        
                vfInfos.push(info);            
            }        
           // if (vfInfos.length > 0)
            {
                console.log(vfInfos);
                this.runAction(component, 'c.saveVariableFees', { oppId: recordId, vfInfos: vfInfos, onlyBOM: onlyBOM})
                .then(                                
                    (result) => { 
                        this.populateVariableFeeTableData(component);
                        var msg = onlyBOM ? 'BOM Fees are saved' : 'Variable Fees are saved';
                        this.showToast('SUCCESS',msg,'SUCCESS');                                                        
                        return this.runAction(component, 'c.createFees', { oppId: recordId, onlyBOM: onlyBOM})
                    }
               )
               .then(                                
                    (result) => {                              
                        if (callback)
                        	callback();
                        this.showToast('SUCCESS','SUCCESS','SUCCESS');                                                        
                    }                    
               )
               .catch((errors) => {
                   console.log('errors');
                   if (callback)
                   		callback();
                   this.handleErrors(errors);                                    
               });
            }
           /* else if (callback)
                callback();*/
        }
        catch (e) {
            if (callback)
                callback();
        }
    },
	runAction: function(component, actionName, params){                
        console.log(actionName);
        console.log(params);
        var action = component.get(actionName); 
        var self = this;
        return new Promise($A.getCallback(
            function(resolve, reject){        
                action.setParams(params)                        
                action.setCallback(this, function (response) {
                    console.log(response);
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