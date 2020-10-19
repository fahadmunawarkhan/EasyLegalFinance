({
    doInit : function(component, event, helper) {      
        helper.loadVariableFeeInfo(component);
    },
	handleDeleteRow: function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");        
        console.log(rowIndex);
        helper.removeRow(component, rowIndex);
    }, 
	handleAddRow: function(component, event, helper) {                        
        helper.addRow(component);
    },  
    handleCustomCellChanged: function(component, event, helper) {
        var recordId = event.getParam("recordId");        
        var rowIndex = event.getParam("rowIndex");
        var cellItem = event.getParam("cellItem");
        console.log('handleCustomCellChanged ' + cellItem.value);
        console.log(rowIndex + ' ' + cellItem.value);
        if (cellItem.value=='%' || cellItem.value=='$')
            helper.changeRateType(component, rowIndex, cellItem.value);
        //helper.handleCustomCellChanged(component, recordId, cellItem);
    },
    reset: function(component, event, helper){
        helper.loadVariableFeeInfo(component);
    },
    save: function(component, event, helper){
        var params = event.getParam('arguments');
        var callback;
        if (params) {
            callback = params.callback;
        }
		helper.save(component, callback);        
    }    
})