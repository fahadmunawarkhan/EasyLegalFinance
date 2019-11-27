({
    getAssessmentProviderInfo : function(component){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let action = component.get('c.getAssessmentProviderInfo');
                action.setParams({
                    recordId : component.get('v.recordId')
                });
                
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){                        
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }                   
                });
                $A.enqueueAction(action);
            }
        ));
    },
    createAssessmentSchedules : function(component){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let lawFirm = component.get('v.selectedLookUpLawFirm');
                let lawyer = component.get('v.selectedLookUpLawyer');
                
                let selOption = component.get('v.selectedLookupOption');
                
                let action = selOption == 'lawFirm'? component.get('c.createAssessmentSchedulesbyLawFirm') : component.get('c.createAssessmentSchedules');
                action.setParams({
                    recordId : component.get('v.recordId'),
                    lookupId : selOption == 'lawFirm'? lawFirm.Id : lawyer.Id,
                    discount : component.get('v.discountRate')
                });
                
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){                        
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }                   
                });
                $A.enqueueAction(action);
            }
        ));
    },
	getAssessmentSchedules : function(component) {
		return new Promise($A.getCallback(
            function(resolve, reject){
                let action = component.get('c.getAssessmentSchedules');
                action.setParams({
                    assessmentProviderId : component.get('v.recordId')
                });
                
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        var records =response.getReturnValue();
                        console.log(records);
                        records.forEach(function(record){
                            record.linkName = '/'+record.Id;
                            record.linkLawyer = '/' + record.Lawyer__c;
                            record.LawyerName = record.Lawyer__r.Name;
                            record.Assessment_ProviderName = record.Assessment_Provider__r.Name;
                            record.discount = record.Discount__c / 100;
                            record.LastModifiedByName = record.LastModifiedBy.Name;
                            record.CreatedByName = record.CreatedBy.Name;
                        });
                        console.log(records);
                        resolve(records);
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }                   
                });
                $A.enqueueAction(action);
            }
        ));
	},
    getCurrentUserInfo : function(component){
      return new Promise($A.getCallback(
          function(resolve, reject){
              let action = component.get('c.getCurrentUserInfo');
              
              action.setCallback(this,
                  function(response){
                      let state = response.getState();
                      
                      if(state == 'SUCCESS'){
                          resolve(response.getReturnValue());
                      }else if(state == 'ERROR'){
                          reject(response.getError());
                      }
                  }
              );
              $A.enqueueAction(action);
          }
      ));  
    },
    errorsHandler : function(component, errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast(component, 'Error', errors[0].message);
        }
    },
    
    showToast : function(component, title, message, type) {
        component.find('notifLib').showToast({
            "variant": type,
            "title": title,
            "message": message
        });
    },
    sortData : function(component,fieldName,sortDirection){
        var data = component.get("v.data");
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        
        if(fieldName == "discount"){
            
            data.sort(function(a,b){ 
                var a = key(a);
                var b = key(b);
                return reverse * ((a>b) - (b>a));
            });
            
        } else {
            data.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                var b = key(b) ? key(b).toLowerCase() : '';
                return reverse * ((a>b) - (b>a));
            });
        }
        
        component.set("v.data",data);
    },
    getRowActions: function (component, row, doneCallback) {
        let currentUser = component.get('v.currentUser');
        let disableAccess = !(currentUser.Can_Edit_Assessment_Schedule__c);
        console.log('current user ' + currentUser.Can_Edit_Assessment_Schedule__c);
        console.log(disableAccess);
        var actions = [{
            label: 'Edit',
            iconName: 'utility:edit',
            name: 'edit',
            disabled: disableAccess
        }];
        // simulate a trip to the server
        setTimeout($A.getCallback(function () {
            doneCallback(actions);
        }), 200);
    }
})