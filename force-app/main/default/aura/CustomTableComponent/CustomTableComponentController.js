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
    updateCell: function(component, event, helper) {
        var params = event.getParam('arguments');
        if (params) {
            var recordId = params.recordId;
            var cellItem = params.cellItem;
            console.log(recordId + ' ' + cellItem.itemName  + ' '+ cellItem.type + ' ' +  cellItem.editable + ' ' +  cellItem.value);
            helper.updateCell(component, recordId, cellItem);
        }
    },   
    removeRow: function(component, event, helper) {
        var params = event.getParam('arguments');
        if (params) {
            var rowIndex = params.rowIndex;
        	helper.removeRow(component, rowIndex);
        }
    },
    getData: function(component, event, helper){
        var data = component.get("v.data");
        return data;
	},
    setData: function(component, event, helper){
        var params = event.getParam('arguments');
        if (params) {
            var data = params.data;
            component.set("v.data", data);
        }
	}
})