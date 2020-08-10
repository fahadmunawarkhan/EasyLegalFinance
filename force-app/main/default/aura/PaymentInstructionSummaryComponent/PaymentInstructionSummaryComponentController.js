({
	toggleSection : function(component, event, helper) {
        let sectionAuraIndex = event.currentTarget.getAttribute("data-index");
        let sections = component.find('sections');
        if (sections){
            let sectionsArray = [];
            if (sections.constructor === Array)
                sectionsArray = sections;
            else
                sectionsArray.push(sections);
            let sectionDiv = sectionsArray[sectionAuraIndex].getElement();
            let sectionState = sectionDiv.getAttribute('class').search('slds-is-open'); 
            if(sectionState == -1){
                sectionDiv.setAttribute('class' , 'slds-section slds-is-open');
            }else{
                sectionDiv.setAttribute('class' , 'slds-section slds-is-close');
            }			
        }
    }
})