({
    doInit: function(component, event, helper) {
        helper.getAccountInfo(component);
        helper.getOpportunitiesList(component);
        helper.getLatestOpportunity(component);
        helper.getLatestContact(component);
        helper.getAmendmentsList(component);
        helper.getContactHistoryList(component);
        helper.getFirmHistoryList(component);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.isAvailableCreditApplicable(component).then(
            function(result) {
                console.log("availableCreditApplicable " + result);
                component.set("v.availableCreditApplicable", result);
            }
        ).catch(
            function(errors) {
                console.log(errors);
                helper.errorsHandler(errors);
            }
        );

        helper.getApprovalProcessHistoryInfo(component).then(
            function(result) {
                component.set("v.approvalHistory", result);
                console.log("v.approvalHistory " + JSON.stringify(result));
            }
        ).catch(
            function(errors) {
                console.log(errors);
                helper.errorsHandler(errors);
            }
        );

        helper.getCriticalDatesList(component).then(
            $A.getCallback(function(result) {}),
            $A.getCallback(function(errors) {
                if (errors[0] && errors[0].message) {
                    helper.errorsHandler(errors)
                } else {
                    helper.unknownErrorsHandler();
                }

            }));
        helper.getPickListValues(component, 'Critical_Date__c', 'Name__c', 'criticalDateName');

        helper.getPickListValues(component, 'Account', 'Business_Unit__c', 'businessUnitOptions');
        helper.getPickListValues(component, 'Account', 'Account_Type__c', 'accountTypeOptions');
        helper.getPickListValues(component, 'Account', 'ProvinceResidency__c', 'provinceResidencyOptions');
        helper.getPickListValues(component, 'Account', 'Offers_to_Settle__c', 'offersToSettleOptions');

        helper.getPickListValues(component, 'Contact', 'Citizenship_Status__c', 'citizenshipStatusOptions');
        helper.getPickListValues(component, 'Contact', 'Marital_Status__c', 'meritalStatusOptions');
        helper.getPickListValues(component, 'Contact', 'Any_SpousalChild_support_payment__c', 'spousalChildSupportPmtOptions');
        helper.getPickListValues(component, 'Contact', 'Have_you_ever_been_in_arrears_on_payment__c', 'howBeenArrearsOnPmtOptions');
        helper.getPickListValues(component, 'Contact', 'Do_you_have_any_dependants__c', 'haveAnyDependantsOptions');
        helper.getPickListValues(component, 'Contact', 'Have_you_ever_declared_bankruptcy__c', 'everDeclaredBankcrupcyOptions');
        helper.getPickListValues(component, 'Contact', 'Employment_status_at_time_of_accident__c', 'employmentStatusTimeofAccidentOptions');

        helper.getPickListValues(component, 'Opportunity', 'Did_ELF_buyout_the_Loan__c', 'elfiBuyoutLoanOptions');
        helper.getPickListValues(component, 'Opportunity', 'Existing_Litigation_Loans__c', 'existingLitigationLoanOptions');
        
        helper.getPickListValues(component, 'Account', 'Primary_Insurance_Provider__c', 'insuranceProviderOptions');

        helper.getCurrentUser(component);
        helper.getLoanSummaryInfo(component);

        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set('v.paymentDate', today);
        helper.parseNavigationHash(component);
    },
    onLocationChange: function(component, event, helper) {
        helper.parseNavigationHash(component);
    },
    onfocusfirmHistoryTab: function(component, event, helper) {
        helper.getFirmHistoryList(component);
    },
    onfocusApplicantInfoTab: function(component, event, helper) {
        helper.getOpportunitiesList(component);
        helper.getLatestOpportunity(component);
        helper.getLatestContact(component);
    },
    onLoanOverviewTabClick: function(component, event, helper) {
        component.set("v.spinner", true);
        helper.getLoanSummaryInfo(component);
        helper.getLatestOpportunity(component);
        helper.getOpportunityTransactions(component);

        helper.isAvailableCreditApplicable(component).then(
            function(result) {
                component.set("v.availableCreditApplicable", result);
            }
        ).catch(
            function(errors) {
                console.log(errors);
                helper.errorsHandler(errors);
            }
        );

        var currentUser = component.get("v.currentUser");
        if (currentUser && currentUser.Reserve__c)
            helper.reloadReserveTable(component);

        component.set("v.paymentPayoutSearch", false);
        component.set("v.paymentPayoutInterestFirstSearch", false);
        component.set("v.paymentBadDebtRecoverySearch", false);
        component.set("v.paymentRefundSearch", false);
        component.set("v.paymentSearchTypeSelected", "Payout");
        component.set("v.paymentSearchDisabled", false);
    },
    onfocusAccountTab: function(component, event, helper) {
        helper.getAccountInfo(component);
        helper.getLatestContact(component);
        helper.getOpportunitiesList(component);
        helper.getLatestOpportunity(component);
    },
    onfocusOpportunityTab: function(component, event, helper) {
        const setTabId = !component.get('v._selectedSecondaryTabId');
        helper.getOpportunitiesList(component)
            .then(() => {
                const oppList = component.get('v.oppList');
                if (setTabId && oppList && oppList.length) {
                    component.set('v._selectedSecondaryTabId', oppList[0].Id);
                }
            });
        helper.getLatestOpportunity(component);
    },
    onPrimaryTabSelect: function(component, event, helper) {
        window.location.hash = `#/${event.getParams().id}`;
    },
    onSecondaryTabSelect: function(component, event, helper) {
        window.location.hash = `#/${component.get('v._selectedTabId')}/${event.getParams().id}`;
    },

    generatePayout: function(component, event, helper) {
        component.set("v.spinner", true);
        helper.generatePayout(component);
    },

    loanSummaryTab: function(component, event, helper) {
        component.set("v.spinner", true);

        helper.clearAllTabs(component, event);
        helper.getLoanSummaryInfo(component);
        component.find("loanSummaryId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("loanSummaryTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';
    },
    paymentSummaryTab: function(component, event, helper) {
        component.set("v.spinner", true);

        helper.clearAllTabs(component, event);
        helper.loadPaymentSummaryTab(component);
        component.find("paymentSummaryId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("paymentSummaryTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';
    },      
    transactionsTab: function(component, event, helper) {
        component.set("v.spinner", true);

        helper.clearAllTabs(component, event);
        helper.getOpportunityTransactions(component);
        component.find("transactionsId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("transactionsTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';
    },
    paymentsTab: function(component, event, helper) {
        helper.clearAllTabs(component, event);
        component.find("paymentsId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("paymentsTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';
    },
    reserveTab: function(component, event, helper) {
        helper.clearAllTabs(component, event);
        component.find("reserveId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("reserveTabLinkId").getElement().className = 'slds-tabs_scoped__link reserve-tab-link-active';
        component.find("reserveTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';
        helper.reloadReserveTable(component);
    },
    historicalDataTab: function(component, event, helper) {
        helper.clearAllTabs(component, event);
        component.find("historicalDataId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("historicalDataTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';
    },
    showPrintableView: function(component, event, helper) {
        var accObj = component.get('v.accountObj');
        var baseURL = accObj.Conga_Printable_Preview_URL__c;
        //var baseURL = "/apex/RDS_AccountPrintableView?Id="+component.get('v.recordId');
        $A.get("e.force:navigateToURL").setParams({
            "url": baseURL
        }).fire();
    },

    sendPayoutStatement: function(component, event, helper) {

        var dateIsSet = component.get("v.payoutDateSet");
        var oppObj = component.get('v.oppObj');
        if (dateIsSet) {
            var accObj = component.get('v.accountObj');
            let loanOverView = component.get("v.LoanSummary");
            let ofn = "&OFN=" + "Payout+Statement+" + oppObj.Primary_Contact_Name__c.trim().split(" ").join("+") + "+-+" + loanOverView.payoutDate;

            var baseURL = accObj.Conga_Send_Payout_Email_URL__c;
            if (oppObj.Type_of_Loan__c == 'Assessment')
                baseURL = accObj.Conga_Send_Assessment_Payout_Email_URL__c;
            if (oppObj.Type_of_Loan__c == 'Lawyer Loan')
                baseURL = accObj.Conga_Send_Lawyer_Payout_Email_URL__c;
            
            baseURL += "&EmailSubject=Loan+Payout+Statement+-+" + oppObj.Primary_Contact_Name__c.trim().split(" ").join("+");
            baseURL += ofn;
            baseURL += "&Id=" + oppObj.Lawyer__c + "&EmailToId=" + oppObj.Lawyer__c;
            //baseURL += "&EmailCC=" + oppObj.Lawyer__r.Email + "&DS7=2";
            baseURL += "&DS7=2";
            baseURL += "&ReturnPath=/lightning/r/Account/" + accObj.Id + "/view%23/LOAN_OVERVIEW";
            console.log('baseURL');
            console.log(baseURL);


            $A.get("e.force:navigateToURL").setParams({
                "url": baseURL
            }).fire();
        }
    },
    generatePayoutStatement: function(component, event, helper) {
        var dateIsSet = component.get("v.payoutDateSet");
        var oppObj = component.get('v.oppObj');
        if (dateIsSet) {
            var accObj = component.get('v.accountObj');
            let loanOverView = component.get("v.LoanSummary");
            let ofn = "&OFN=" + "Payout+Statement+" + oppObj.Primary_Contact_Name__c.trim().split(" ").join("+") + "+-+" + loanOverView.payoutDate;

            var baseURL = accObj.Conga_Payouts_URL__c;
            if (oppObj.Type_of_Loan__c == 'Assessment')
                baseURL = accObj.Conga_Assessmnet_Payouts_URL__c;
            if (oppObj.Type_of_Loan__c == 'Lawyer Loan')
                baseURL = accObj.Conga_Lawyer_Loan_Payout_URL__c;

            baseURL += ofn;
            $A.get("e.force:navigateToURL").setParams({
                "url": baseURL
            }).fire();
        } else {
            helper.showToast('Error', 'Payout date is not set!');
        }
    },
    pdfApplicationDocument: function(component, event, helper) {
        var oppObj = component.get('v.oppObj');
        var BaseUrl = "/apex/APXTConga4__Conga_Composer?id=" + oppObj.Id + "&TemplateID=" + component.get('v.accountObj.CM_Application_Template_Id__c') + "&DS7=3&DefaultPDF=1&ReturnPath=" + component.get('v.recordId');
        $A.get("e.force:navigateToURL").setParams({
            "url": BaseUrl
        }).fire();
    },
    sendApplicationDocument: function(component, event, helper) {
        let account = component.get('v.accountObj');
        let brandingParam = '&DocuSignBrandName=' + account.Business_Unit__c + 'Signing';
        var oppObj = component.get('v.oppObj');
        //Define the Conga URL and its parameters   
        //var BaseUrl = '/apex/APXTConga4__Conga_Composer?id={!oppSObj.id}&DS7=17&DocuSignVisible=1&QueryStringField=Docusign_Parameters_Loan_App__c&DocuSignRelatedAccountId={!oppSObj.AccountId}&DocuSignR1Id={!oppSObj.Primary_Contact__c}&DocuSignR1Type=Signer&DocuSignR1Role=Signer+1&DocuSignR1RoutingOrder=1&TemplateID={!accSObj.CM_Application_Template_Id__c}';
        var BaseUrl = '/apex/APXTConga4__Conga_Composer?SolMgr=1&id=' + oppObj.Id + '&DocuSignVisible=1&QueryStringField=Docusign_Parameters_Loan_App__c&DocuSignR1Id=' + oppObj.Primary_Contact__c + '&DocuSignR1Type=Signer&DocuSignR1Role=Signer+1&TemplateID=' + component.get('v.accountObj.CM_Application_Template_Id__c') + '&DocuSignEndPoint=NA3&DocuSignR1RoutingOrder=1&DS7=17' + brandingParam; //&ReturnPath='+component.get('v.recordId');
        console.log(BaseUrl);
        $A.get("e.force:navigateToURL").setParams({
            "url": BaseUrl
        }).fire();
    },
    sendApplicationDocumentCongaSign: function(component, event, helper) {
        let account = component.get('v.accountObj');
        let brandingParam = '&DocuSignBrandName=' + account.Business_Unit__c + 'Signing';
        var oppObj = component.get('v.oppObj');
        var BaseUrl = '/apex/APXTConga4__Conga_Composer?SolMgr=1&id=' + oppObj.Id + '&CSVisible=1&QueryStringField=Conga_Sign_Parameters_Loan_App__c&CSRecipient1=' + oppObj.Primary_Contact__c + '&DocuSignR1Type=Signer&csRole1=SIGNER&TemplateID=' + component.get('v.accountObj.CM_Application_Template_Id__c') + '&CSBusinessUnit='+component.get("v.accountObj.Business_Unit__c")+'&CSRoutingType=SERIAL&DS7=1142' + brandingParam;
        console.log(BaseUrl);
        $A.get("e.force:navigateToURL").setParams({
            "url": BaseUrl
        }).fire();
	},
    saveAll: function(component, event, helper) {
            let businessUnit = component.get("v.accountObj.Business_Unit__c");

            if (businessUnit != '' && businessUnit != null) {

                helper.saveAccountOpptyAndContact(component);
                helper.getAccountInfo(component);
                helper.getLatestContact(component);

                helper.getApprovalProcessHistoryInfo(component).then(
                    function(result) {
                        component.set("v.approvalHistory", result);
                    }
                ).catch(
                    function(errors) {
                        console.log(errors);
                        helper.errorsHandler(errors);
                    }
                );
            }


        /*
        var contact = component.get('v.conObj');
        var lawyer = component.get('v.lawyerObj');
        
        component.set("v.spinner", true);
        helper.saveAccountInfo(component);
        helper.saveContactInfo(component,contact);
        helper.saveOpp(component);*/
    },

    redirectToStandardView: function(component, event, helper) {
        // Redirect to the default Lead Lightning Page
        //var url = "/"+component.get("v.accountObj").Id+"?nooverride=1";
        //window.location.href = url;
        $A.get("e.force:navigateToURL").setParams({
            "url": "/lightning/r/" + component.get("v.accountObj").Id + "/view?nooverride=1"
        }).fire();
    },

    doCancel: function(component, event, helper) {
        window.location.reload();
    },

    doDelete: function(component, event, helper) {
        component.set("v.spinner", true);

        if (confirm('Are you sure?')) {
            helper.deleteAccount(component);

            // Redirect to Account home
            var url = "/lightning/o/Account/home"
            window.location.href = url;
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    inlineEditName: function(component, event, helper) {
        var clickSource = event.currentTarget.dataset.source;
        // show the name edit field popup 

        component.set("v.clickSource", clickSource);
        if (clickSource == 'Law_Firm__c') {
            component.set('v.selectedLookUpLawFirm.Id', '');
            component.set('v.selectedLookUpLawFirm.Name', '');

            component.set('v.selectedLookUpLawyer.Id', '');
            component.set('v.selectedLookUpLawyer.Name', '');
        } else if (clickSource == 'Lawyer__c') {
            component.set('v.selectedLookUpLawyer.Id', '');
            component.set('v.selectedLookUpLawyer.Name', '');
        }
        // after the 100 millisecond set focus to input field   
        setTimeout(function() {
            try {
                component.find(clickSource).focus();
                component.find(clickSource).click();
            } catch (e) {}
        }, 100);
    },
    hideLookupInput: function(component, event, helper) {
        component.set("v.clickSource", "none");
        helper.saveAccountInfo(component);
        helper.saveOpp(component);
        helper.getAccountInfo(component);
    },
    printReport: function(cmp, evt, hpr) {
        var acc = cmp.get('v.accountObj');
        var BaseUrl = acc.Conga_Transaction_Printable_Preview__c + '&DefaultPDF=1';
        $A.get("e.force:navigateToURL").setParams({
            "url": BaseUrl
        }).fire();
    },
    exportToExcel: function(cmp, evt, hpr) {
        var acc = cmp.get('v.accountObj');
        var BaseUrl = acc.Conga_Transaction_Printable_Preview__c;
        $A.get("e.force:navigateToURL").setParams({
            "url": BaseUrl
        }).fire();
    },
    accountNotesPrintView: function(component, event, helper) {

        var acc = component.get('v.accountObj');
        var BaseUrl = acc.Conga_Account_Notes_URL__c;
        $A.get("e.force:navigateToURL").setParams({
            "url": BaseUrl
        }).fire();
    },
    newOppty: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        component.find("oppTabs").set("v.selectedTabId", "NEW");

    },
    formatPhone: function(component, event, helper) {
        helper.formatPhone(component, event, 'Phone', 'conObj');
    },
    formatOtherPhone: function(component, event, helper) {
        helper.formatPhone(component, event, 'OtherPhone', 'conObj');
    },
    formatLawPhone: function(component, event, helper) {
        helper.formatPhone(component, event, 'Phone', 'oppObj.Lawyer__r');
    },
    refreshOpportunityList: function(component, event, helper) {

        helper.getOpportunitiesList(component)
            .then(function(result) {
                console.log('then is called immediately');

                var oppList = component.get('v.oppList');
                console.log('oppties: ' + JSON.stringify(oppList));
                if (oppList != null) {
                    component.find("oppTabs").set("v.selectedTabId", (oppList.length > 0 ? oppList[0].Id : 'NEW'));
                }

            });
        /*
            setTimeout(function(){
                
                var oppList = component.get('v.oppList');
                console.log('oppties: '+JSON.stringify(oppList));
                component.find("oppTabs").set("v.selectedTabId",oppList[0].Id);
            },500);
            */
    },
    refreshOptTab: function(component, event, helper) {

        var tab = event.getSource();
        var allComponents = component.find("oppIdx");

        console.log("--------------All components--------------");
        console.log(allComponents);

        if (allComponents) {
            if (allComponents.length) {
                allComponents.forEach(function(oppViewComp) {
                    if (oppViewComp.get('v.recordId') == tab.get('v.id')) {
                        oppViewComp.OnTabActive();
                    }
                });
            } else {
                allComponents.OnTabActive();
            }
        }
    },
    SaveApplicantInfo: function(component, event, helper) {
        var opportunity = component.get('v.oppObj');
        if (opportunity.Id != null) {
            helper.saveAccountOpptyAndContact(component);
        } else {
            helper.showToast('Error', 'Unable to save information. Please create an opportunity first.', 'Info');
        }
        component.set("v.applicantInfoEditMode", false);
    },
    editApplicantInfo: function(component, event, helper) {
        component.set("v.applicantInfoEditMode", true);
    },
    runAllOptsPayout: function(component, event, helper) {
        component.set("v.spinner", true);
        var searchType = component.get("v.paymentSearchTypeSelected")
        var paymentDate = component.get("v.paymentDate");
        component.set("v.paymentAmount", null);

        component.set("v.paymentBadDebtRecoverySearch", false);
        component.set("v.paymentPayoutSearch", false);
        component.set("v.paymentPayoutInterestFirstSearch", false);
        component.set("v.paymentRefundSearch", false);
        if (paymentDate != null) {
            if (searchType != null) {
                if (searchType == 'Payout') {
                    component.set("v.paymentPayoutSearch", true);
                } else if (searchType == 'Payout - Interest First') {
                    component.set("v.paymentPayoutInterestFirstSearch", true);
                } else if (searchType == 'Bad Debt Recovery') {
                    component.set("v.paymentBadDebtRecoverySearch", true);
                } else if (searchType == 'Refund') {
                    component.set("v.paymentRefundSearch", true);
                }
                helper.runAllOptsPayout(component);
            } else {
                helper.showToast('Error', 'Search type needs to be populated');
                component.set("v.spinner", false);
            }
        } else {
            helper.showToast('Error', 'Date of payment needs to be populated');
            component.set("v.spinner", false);
        }
    },
    calculatePayment: function(component, event, helper) {
        if (!helper.activeLoanExists(component)) {
            helper.showToast('Error', 'Payment allocation failed. Only Active loans can receive payments');
            return;
        }
        component.set("v.spinner", true);
        helper.calculatePayment(component);
    },
    applyPartialPayment: function(component, event, helper) {
        component.set("v.spinner", true);
        var oppId = event.target.getElementsByClassName('opportunity-partial-id')[0].value;

        if (confirm('Are you sure?')) {
            helper.applyPartialPayment(component, oppId);
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    applyFullPayment: function(component, event, helper) {
        component.set("v.spinner", true);
        var oppId = event.target.getElementsByClassName('opportunity-close-id')[0].value;

        if (confirm('Are you sure?')) {
            helper.applyFullPayment(component, oppId);
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    closeAllPaidLoans: function(component, event, helper) {
        component.set("v.spinner", true);

        if (confirm('Are you sure?')) {
            helper.closePaidLoans(component);
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    changeToBadDebt: function(component, event, helper) {
        component.set("v.spinner", true);
        var oppId = event.target.getElementsByClassName('opportunity-debt-id')[0].value;

        if (confirm('Are you sure?')) {
            helper.changeToBadDebt(component, oppId);
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    changeToSurplus: function(component, event, helper) {
        component.set("v.spinner", true);
        var oppId = event.target.getElementsByClassName('opportunity-surplus-id')[0].value;

        if (confirm('Are you sure?')) {
            helper.changeToSurplus(component, oppId);
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    changeToShortfall: function(component, event, helper) {
        component.set("v.spinner", true);
        var oppId = event.target.getElementsByClassName('opportunity-shortfall-id')[0].value;

        if (confirm('Are you sure?')) {
            helper.changeToShortfall(component, oppId);
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    saveCriticalDates: function(component, event, helper) {
        component.set("v.spinner", true);
        helper.validateCriticalDatesFields(component).then(
            (success) => {
                return helper.saveCriticalDates(component);
            }

        ).then(
            (result) => {
                helper.showToast('SUCCESS', result, 'SUCCESS');
                component.set("v.spinner", false);
                return helper.getCriticalDatesList(component, helper);
            }
        ).catch(
            (errors) => {
                if (errors[0] && errors[0].message) {

                    helper.errorsHandler(errors)
                } else {
                    helper.unknownErrorsHandler();
                }
                component.set("v.spinner", false);
            }
        );
        /*helper.saveCriticalDates(component).then($A.getCallback(
            (result) => {
                helper.showToast('SUCCESS',result,'SUCCESS');
                component.set("v.spinner", false);
                return helper.getCriticalDatesList(component, helper);
            }
        )).catch(
                (errors) => {
                    if (errors[0] && errors[0].message) {
                        helper.errorsHandler(errors)
                    }else {
                        helper.unknownErrorsHandler();
                    }
                	component.set("v.spinner", false);
                }
                );*/


    },
    addNewCriticalDate: function(component, event, helper) {
        try {
            component.set("v.spinner", true);
            helper.addNewCriticalDate(component);
            component.set("v.spinner", false);
        } catch (e) {
            component.set("v.spinner", false);
        }
    },
    deleteCriticalDateItem: function(component, event, helper) {
        component.set("v.spinner", true);
        let itemIndex = event.target.getElementsByClassName('criticalDate-item-index')[0].value;

        if (confirm('Are you sure?')) {
            try {
                helper.deleteCriticalDateItem(component, itemIndex).then($A.getCallback(
                    (result) => {
                        helper.showToast('SUCCESS', result, 'SUCCESS');
                        //return helper.getCriticalDatesList(component);
                    }
                )).catch((errors) => {
                    component.set("v.spinner", false);
                    if (errors[0] && errors[0].message) {
                        helper.errorsHandler(errors)
                    } else {
                        helper.unknownErrorsHandler();
                    }
                });
            } catch (e) {

            }

        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    openBankAccountsList: function(component, event, helper) {
        helper.viewBankAccountsList(component, event);
    },
    generateReplacementCounselDocuments: function(component, event, helper) {
        window.open(component.get('v.oppObj').Replacement_Counsel_Document_Generate__c, "_parent", "width=650,height=250,menubar=0");
    },
    sendReplacementCounselDocuments: function(component, event, helper) {
        window.open(component.get('v.oppObj').Replacement_Counsel_Document_Send__c, "_parent", "width=650,height=250,menubar=0");
    },
    handlePaymentActionSelected: function(component, event, helper) {
        var oppId = event.getParam("oppId");
        var action = event.getParam("action");
        var paymentActionsMap = component.get("v.paymentActionsMap");
        console.log('Action ' + action);
        /*var actions = new Array();
        actions.push(action);*/
        paymentActionsMap[oppId] = action;
        console.log(paymentActionsMap);
        //alert(event.getParam("oppId"));
        //component.set("v.appContacts", event.getParam("contacts"));
    },
    handlePaymentActionValidated: function(component, event, helper) {
        var oppId = event.getParam("oppId");
        var result = event.getParam("result");
        var paymentActionsValidationMap = component.get("v.paymentActionsValidationMap");
        paymentActionsValidationMap[oppId] = result;
        helper.validatePaymentAction(component);
    },
    submitPayments: function(component, event, helper) {
        if (!helper.activeLoanExists(component)) {
            helper.showToast('Error', 'Payment allocation failed. Only Active loans can receive payments');
            return;
        }
        var paymentActionsMap = component.get("v.paymentActionsMap");
        component.set("v.spinner", true);
        var calculatedPaymentAmount = component.get("v.calculatedPaymentAmount");
        var message = 'Proceed with updating loan(s)?';
        if (calculatedPaymentAmount)
            message = 'Ready to proceed applying the payment of $' + helper.formatCurrency(calculatedPaymentAmount) + '?';
        if (confirm(message)) {
            helper.submitPayments(component);
        } else {
            component.set("v.spinner", false);
            return false;
        }

    },
    cancel: function(component, event, helper) {
        if (!helper.activeLoanExists(component)) {
            helper.showToast('Error', 'Payment allocation failed. Only Active loans can receive payments');
            return;
        }
        component.set("v.paymentAmount", 0.0);
        component.set("v.spinner", true);
        helper.calculatePayment(component, event, helper);
    },
    handlePaymentFieldsChange: function(component, event, helper) {
        var paymentAmount = component.get("v.paymentAmount");
        var eft = component.get("v.EFT");
        var chq = component.get("v.CHQ");
        var wireFee = component.get("v.WireFee");
        if (paymentAmount != null || eft != null || chq != null || wireFee != null) {
            component.set("v.paymentSearchDisabled", true);
        }
        /*else{
             component.set("v.paymentSearchDisabled", false);     
        }*/
    },
    projectedLoanValueChanged: function(component, event, helper) {
        helper.setReasonForLTVOptions(component);
    },
    handleReserveLoan: function(component, event, helper) {
        console.log('reserveLoan');
        helper.loadAccountReserveInfo(component);
    },
    handleCustomTableResetClicked: function(component, event, helper) {
        console.log('handleCustomTableResetClicked');
        helper.reloadReserveTable(component);
    },
    handleCustomTableSaveClicked: function(component, event, helper) {
        console.log('handleCustomTableSaveClicked');
        component.set("v.spinner", true);
        var changedRecords = event.getParam('changedRecords');
        console.log(changedRecords);
        helper.saveReserveTable(component, changedRecords)
            .then(
                (result) => {
                    helper.showToast('SUCCESS', 'Your changes were successfully saved!', 'SUCCESS');
                    return helper.getOpportunitiesList(component);
                },
                (errors) => {
                    component.set("v.spinner", false);
                    if (errors && typeof errors == 'string')
                        helper.showToast('ERROR', errors, 'ERROR');
                    else
                        helper.handleErrors(errors);
                }
            )
            .then(
                (result) => {
                    component.set("v.spinner", false);
                    helper.populateReserveTableColumns(component);
                    helper.populateReserveTableData(component);
                    helper.loadAccountReserveInfo(component);
                },
                (error) => {
                    component.set("v.spinner", false);
                }
            );
    },
    excludeFromLawyerStatementsChanged: function(component, event, helper) {
        component.set("v.spinner", true);
        helper.excludeFromLawyerStatements(component)
            .then(
                (result) => {
                    component.set("v.spinner", false);
                    helper.showToast('SUCCESS', 'Your changes were successfully saved!', 'SUCCESS');
                },
                (errors) => {
                    component.set("v.spinner", false);
                    helper.handleErrors(errors);
                    helper.loadAccountReserveInfo(component);
                }
            )
    },
    handleCustomCellChanged: function(component, event, helper) {
        var recordId = event.getParam("recordId");        
        var cellItem = event.getParam("cellItem");
        console.log('handleCustomCellChanged ' + recordId);
        console.log(cellItem.itemName + ' ' + cellItem.value);
        helper.handleCustomCellChanged(component, recordId, cellItem);
    },
    openUnderwriterEvaluationModal : function(component, event, helper) {
        component.set("v.showUnderwriterEvaluationModal", true);
    },
    closeUnderwriterEvaluationModal: function(component, event, helper) {
        component.set("v.showUnderwriterEvaluationModal", false);
        component.set("v.spinner", true);
        helper.getAccountInfo(component);
    },
    saveUnderwriterEvaluationModal : function(component, event, helper) {
        component.set("v.showUnderwriterEvaluationModal", false);
        component.set("v.spinner", true);
        component.set("v.updatehistoy", "true");
        helper.validateLTV(component).then(
            function(isValid) {
                if (isValid) {
                    let accountObj = component.get("v.accountObj");
                    accountObj.Reason_for_LTV__c = component.get("v.selectedReasonForLTV");
                    accountObj.Underwriter_Notes__c = component.get("v.underwriterNotes");
                    component.set("v.underwriterNotes", "");
                    component.set("v.accountObj", accountObj);

                    helper.saveAccountPromise(component).then($A.getCallback(
                        function(result){
                            helper.showToast('SUCCESS', 'Your changes were successfully saved!', 'SUCCESS');
                            return helper.getApprovalProcessHistoryInfo(component);
                        }
                    )).then(
                        function(result) {
                            component.set("v.spinner", false);
                            component.set("v.updatehistoy", "false");
                            component.set("v.approvalHistory", result);
                            helper.getAccountInfo(component);
                        }
                    ).catch(
                        function(errors){
                            console.log(errors);
                            component.set("v.spinner", false);
                            helper.handleErrors(errors);
                        }
                    );
                } else {
                    component.set("v.spinner", false);
                    helper.showToast('ERROR', 'Please select a reason for LTV.', 'Error');
                }
            }
        );
    }                  
})