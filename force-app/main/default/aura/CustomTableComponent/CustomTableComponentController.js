({
    doInit : function(component, event, helper) {
    },
    reset: function(component, event, helper) {
        var resetClickedEvent = component.getEvent("resetClickedEvent");
		resetClickedEvent.fire();
    },
    save: function(component, event, helper) {
        var data = component.get("v.data");
        var changedRecordIdsMap = component.get("v.changedRecordIdsMap");
        var changedRecords = [];        
        for (var i = 0; i < data.length; i++){
            var row = data[i];
            if (changedRecordIdsMap[row.id]){
                changedRecords.push(row);
            }
        }
        var saveClickedEvent = component.getEvent("saveClickedEvent");
        saveClickedEvent.setParams({"columns": component.get("v.columns"), "changedRecords": changedRecords});
		saveClickedEvent.fire();        
    },   
    handleCustomCellChanged: function(component, event, helper) {
        var recordId = event.getParam("recordId");        
        var changedRecordIdsMap = component.get("v.changedRecordIdsMap");
        changedRecordIdsMap[recordId] = recordId;
        component.set("v.changedRecordIdsMap", changedRecordIdsMap);
    },      
})