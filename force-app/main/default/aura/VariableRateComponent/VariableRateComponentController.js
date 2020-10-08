({
    doInit : function(component, event, helper) {      
        helper.loadVariableRateInfo(component);
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
        console.log('handleCustomCellChanged');
        helper.handleCellChanged(component, event);
    },    
    reset: function(component, event, helper){
        helper.loadVariableRateInfo(component);
    },
    save: function(component, event, helper){        
        helper.save(component);
    }, 
})