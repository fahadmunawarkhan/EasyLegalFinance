({
    doInit : function(component, event, helper) {
        var cellItem = component.get("v.cellItem");
        if (cellItem){
            cellItem.editMode = false;
            component.set("v.cellItem", cellItem);
        }
    },
    inlineEdit: function(component, event, helper) {        
        var cellItem = component.get("v.cellItem");
        if (cellItem.editable && cellItem.type != 'boolean' && cellItem.type != 'radiogroup'){
            cellItem.editMode = true;
            component.set("v.cellItem", cellItem);
             setTimeout(function(){ 
                var input = component.find("inputId");                 
                 if (input) input.focus();
                 component.set("v.needCloseEditBox", false);
            }, 100);
        }
    },
    inlineDelete: function(component, event, helper) {
        var deleteCustomTableRowEvent = component.getEvent("deleteCustomTableRowEvent");
        var rowIndex = component.get("v.rowIndex");        
        deleteCustomTableRowEvent.setParams({"rowIndex" : rowIndex});
		deleteCustomTableRowEvent.fire();
    },        
    onValueChange: function(component, event, helper) {
        component.set("v.isChanged", true);
        var cellItem = component.get("v.cellItem");
        if (cellItem.type=='radiogroup' || cellItem.type=='boolean'){
            var cellChangedEvent = component.getEvent("cellChangedEvent");
            var recordId = component.get("v.recordId");
            var rowIndex = component.get("v.rowIndex");
            var cellItem = component.get("v.cellItem");
            cellChangedEvent.setParams({"recordId" : recordId, "cellItem" : cellItem, "rowIndex" : rowIndex});
            cellChangedEvent.fire();                
        }
    },
    onFocus: function(component, event, helper) {         
        component.set("v.needCloseEditBox", false);
    },
    closeEditBox: function(component, event, helper) {
		console.log('onBlur');
        component.set("v.needCloseEditBox", true);        
        setTimeout(function(){             
            if (component.get("v.needCloseEditBox")){
                console.log(component.get("v.needCloseEditBox"));
                var cellItem = component.get("v.cellItem");
                cellItem.editMode = false;
                component.set("v.cellItem", cellItem);
                var cellChangedEvent = component.getEvent("cellChangedEvent");
                var recordId = component.get("v.recordId");
                var rowIndex = component.get("v.rowIndex");
                var cellItem = component.get("v.cellItem");
                cellChangedEvent.setParams({"recordId" : recordId, "cellItem" : cellItem, "rowIndex" : rowIndex});
                cellChangedEvent.fire();                
            }
        }, 500);
    },
    keyCheck : function(component, event, helper){
        if (event.which == 13){
            $A.enqueueAction(component.get('c.closeEditBox'));            
    	}
	},
    handleLinkClick : function(component, event, helper){
        var cellItem = component.get("v.cellItem");
        if (cellItem.isAddRowLink == true){
            var addCustomTableRowEvent = component.getEvent("addCustomTableRowEvent");                        
            addCustomTableRowEvent.fire();            
        }
	},
	onBlur: function(component, event, helper) {    
        console.log('onblur');
    },   
})