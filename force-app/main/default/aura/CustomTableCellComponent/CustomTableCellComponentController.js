({
    doInit : function(component, event, helper) {
        var cellItem = component.get("v.cellItem");
        cellItem.editMode = false;
        component.set("v.cellItem", cellItem);
    },
    inlineEdit: function(component, event, helper) {
        var cellItem = component.get("v.cellItem");
        if (cellItem.editable){
            cellItem.editMode = true;
            component.set("v.cellItem", cellItem);
             setTimeout(function(){ 
                component.find("inputId").focus();
            }, 100);
        }
    },
    onValueChange: function(component, event, helper) {
        component.set("v.isChanged", true);
        var cellChangedEvent = component.getEvent("cellChangedEvent");
        var recordId = component.get("v.recordId");
        var cellItem = component.get("v.cellItem");
        cellChangedEvent.setParams({"recordId" : recordId, "cellItem" : cellItem});
		cellChangedEvent.fire();
    },
    onFocus: function(component, event, helper) {        
        component.set("v.needCloseEditBox", false);
    },
    closeEditBox: function(component, event, helper) {
        component.set("v.needCloseEditBox", true);        
        setTimeout(function(){ 
            if (component.get("v.needCloseEditBox")){
                console.log(component.get("v.needCloseEditBox"));
                var cellItem = component.get("v.cellItem");
                cellItem.editMode = false;
                component.set("v.cellItem", cellItem);
            }
        }, 100);
    },
    keyCheck : function(component, event, helper){
        if (event.which == 13){
            $A.enqueueAction(component.get('c.closeEditBox'));            
    }    
}
})