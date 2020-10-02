({
	updateCell : function(component, recordId, cellItem) {
        var data = component.get("v.data");
        for (var i = 0; i < data.length; i++){
            var row = data[i];
            if (row.id == recordId){
                console.log('row found');
                if ( row.items){
                    for (var j = 0; j < row.items.length; j++){
                        var cell = row.items[j];
                        console.log(cell.itemName);
                        if (cell.itemName == cellItem.itemName){
                            row.items[j] = cellItem;
                            console.log('found');
                            break;
                        }                                
                    }
                }
            }
        }
        component.set("v.data", data);		
	},
    removeRow : function(component, rowIndex){
        var data = component.get("v.data");
        data.splice(rowIndex, 1);
        component.set("v.data", data);		        
    }
})