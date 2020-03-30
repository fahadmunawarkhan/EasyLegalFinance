({
	doInit : function(component, event, helper) {
		helper.getCurrentUser(component);
        helper.parseNavigationHash(component);
	},
    onLocationChange: function(component, event, helper) {
        helper.parseNavigationHash(component);
    },
    onPrimaryTabSelect: function(component, event, helper) {
        window.location.hash = `#/${event.getParams().id}`;
    },
    onSecondaryTabSelect: function(component, event, helper) {
        window.location.hash = `#/${component.get('v._selectedTabId')}/${event.getParams().id}`;
    }
})