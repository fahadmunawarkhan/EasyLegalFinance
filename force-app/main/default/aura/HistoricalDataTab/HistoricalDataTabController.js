({
    doInit : function(cmp, event, helper) {
        helper.getHistoricalData(cmp, event, helper);
    },
    onload: function(cmp, event, helper) {

    },
    onerror: function(cmp, event, helper) {
   
    },
    onsubmit: function(cmp, event, helper) {

        
    },
    onsuccess: function(cmp, event, helper) {
        var payload = event.getParams();
        console.log(JSON.stringify(payload));
    },
    
    
    
})