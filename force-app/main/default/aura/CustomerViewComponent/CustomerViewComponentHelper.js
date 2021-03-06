({
    getAccountInfo: function(component) {
        // ********************* GET ACCOUNT LABEL VALUES ********************* //
        var fieldsMapAction = component.get('c.getAccountLabelsMap');
        component.set("v.spinner", true);
        fieldsMapAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set('v.fieldLabels', response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(fieldsMapAction);

        // ********************* GET ACCOUNT RECORD DETAILS ********************* //
        var recordId = component.get("v.recordId");
        var action = component.get('c.getAccountInfo');
        component.set("v.spinner", true);
        action.setParams({ accountId: recordId })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.accountObj", response.getReturnValue());
                component.set("v.selectedReasonForLTV", response.getReturnValue().Reason_for_LTV__c);
                this.setReasonForLTVOptions(component);

                component.set("v.selectedLookUpAccOwner.Id", component.get("v.accountObj").OwnerId);
                component.set("v.selectedLookUpAccOwner.Name", (component.get("v.accountObj").Owner.Name ?
                    component.get("v.accountObj").Owner.Name : ''));


            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },
    getCriticalDatesList: function(component) {
        let promise = new Promise($A.getCallback(function(resolve, reject) {

            let action = component.get('c.getCriticalDatesList');
            action.setParams({ accountId: component.get("v.recordId") });

            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    component.set("v.criticalDateList", response.getReturnValue());
                    resolve(true);
                } else if (state === 'ERROR') {
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));

        return promise;
    },
    saveCriticalDates: function(component) {

        let promise = new Promise($A.getCallback(function(resolve, reject) {
            let criticalDates = component.get('v.criticalDateList');
            let action = component.get('c.saveCriticalDateList');
            action.setParams({ criticalDateList: criticalDates });

            action.setCallback(this, function(response) {
                let state = response.getState();

                if (state === 'SUCCESS') {
                    component.set("v.spinner", false);
                    resolve('Your changes were successfully saved!');
                } else if (state === 'ERROR') {
                    component.set("v.spinner", false);
                    let errors = response.getError();
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
        }));

        return promise;
    },
    addNewCriticalDate: function(component) {
        component.set("v.spinner", true);

        let todayDate = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        let criticalDateList = component.get('v.criticalDateList');
        criticalDateList.push({ 'sobjectType': 'Critical_Date__c', 'Id': null, 'Date__c': todayDate, 'Account__c': component.get("v.recordId") });

        component.set("v.criticalDateList", criticalDateList);
        component.set("v.spinner", false);
    },
    deleteCriticalDateItem: function(component, itemIndex) {
        component.set("v.spinner", true);
        let promise = new Promise($A.getCallback(
            (resolve, reject) => {
                let criticalDateList = component.get('v.criticalDateList');
                if (criticalDateList[itemIndex].Id != null) {
                    let action = component.get('c.deleteCriticalDate');
                    action.setParams({ recordId: criticalDateList[itemIndex].Id });
                    action.setCallback(this, function(response) {
                        let state = response.getState();
                        if (state === 'SUCCESS') {

                            criticalDateList.splice(itemIndex, 1);
                            component.set('v.criticalDateList', criticalDateList);
                            component.set("v.spinner", false);
                            resolve("Record is deleted successfully!");

                        } else if (state === 'ERROR') {
                            component.set("v.spinner", false);
                            reject(response.getError());
                        }
                    });
                    $A.enqueueAction(action);

                } else {
                    criticalDateList.splice(itemIndex, 1);
                    component.set('v.criticalDateList', criticalDateList);
                    resolve("Record deleted Successfully!");
                    component.set("v.spinner", false);
                }
            }
        ));
        return promise;
    },

    getOpportunitiesList: function(component) {
        var p = new Promise($A.getCallback(function(resolve, reject) {
            var recordId = component.get("v.recordId");
            var action = component.get('c.getOpportunities');
            action.setParams({ accountId: recordId })

            action.setCallback(this, function(response) {
                var state = response.getState();

                if (state === 'SUCCESS') {

                    component.set("v.oppList", response.getReturnValue());
                    resolve(true);
                } else if (state === 'ERROR') {

                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                    reject(false);
                }
            });
            $A.enqueueAction(action);
            console.log('refreshing now...');
        }));
        console.log('time to exit promise');
        return p;
    },

    runAllOptsPayout: function(component) {
        component.set("v.displayPaymentValidationErrors", false);
        component.set('v.calculatedPaymentAmount', null);
        var sType = component.get("v.paymentSearchTypeSelected");
        console.log(sType);
        var recordId = component.get("v.recordId");
        var paymentDate = component.get("v.paymentDate");
        var action = component.get('c.runPayoutForAllOpps');
        action.setParams({ accountId: recordId, payoutDate: paymentDate })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                var resultsList = response.getReturnValue();
                var oppsList = new Array();
                var closedLoanExist = false;
                for (var i = 0; i < resultsList.length; i++) {
                    console.log(resultsList[i].StageName);
                    if (resultsList[i].StageName == 'Closed With Loan') {
                        oppsList.push(resultsList[i]);
                        var stageStatus = resultsList[i].Stage_Status__c;
                        if (stageStatus == 'Closed - Paid' || stageStatus == 'Closed - Surplus' || stageStatus == 'Closed - Shortfall' || stageStatus == 'Closed - Bad Debt')
                            closedLoanExist = true;
                    }
                }
                component.set("v.oppList", oppsList);
                this.getLoanSummaryInfo(component);
                if (sType == 'Bad Debt Recovery' && !closedLoanExist) {
                    this.showToast('Closed loans not found', 'Bad Debt Recovery can only be applied to  closed loans');
                }
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },
    calculatePayment: function(component) {
        component.set("v.displayPaymentValidationErrors", false);
        var recordId = component.get("v.recordId");
        var paymentAmount = component.get("v.paymentAmount");
        var eft = component.get("v.EFT");
        var chq = component.get("v.CHQ");
        var sType = component.get("v.paymentSearchTypeSelected");

        var action = component.get('c.calculatePayments');
        component.set("v._enableCloseAllPaid", false);
        action.setParams({ accountId: recordId, amount: paymentAmount, eft: eft, chq: chq, searchType: sType })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set('v.calculatedPaymentAmount', paymentAmount);
                var resultsList = response.getReturnValue();
                var oppsList = new Array();
                for (var i = 0; i < resultsList.length; i++) {
                    console.log(resultsList[i].StageNam);
                    if (resultsList[i].StageName == 'Closed With Loan') {
                        oppsList.push(resultsList[i]);
                    }
                }
                component.set("v.oppList", oppsList);

                if (!$A.util.isUndefinedOrNull(response.getReturnValue())) {
                    for (var i = 0; i < response.getReturnValue().length; i++) {
                        if (response.getReturnValue()[i].Temp_Payment_Received__c == response.getReturnValue()[i].Total_Payout__c && response.getReturnValue()[i].Stage_Status__c != 'Paid Off' &&
                            response.getReturnValue()[i].Total_Payout__c > 0) {
                            component.set("v._enableCloseAllPaid", true);
                        }
                    }
                }
                this.getLoanSummaryInfo(component);
                this.showToast('SUCCESS', 'Payment was successfully calculated!', 'SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    applyPartialPayment: function(component, oppId) {
        var accountId = component.get("v.recordId");
        var action = component.get('c.applyPartialPayments');
        console.log('Date is ' + component.get("v.paymentDate"));
        action.setParams({
            oppId: oppId,
            accountId: accountId,
            payoutDate: component.get("v.paymentDate")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.oppList", response.getReturnValue());
                this.showToast('SUCCESS', 'Partial Payment was successfully created!', 'SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    applyFullPayment: function(component, oppId) {
        var accountId = component.get("v.recordId");
        var action = component.get('c.applyFullPayments');
        var sType = component.get("v.paymentSearchTypeSelected");
        action.setParams({
            oppId: oppId,
            accountId: accountId,
            searchType: sType,
            payoutDate: component.get("v.paymentDate")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.oppList", response.getReturnValue());
                this.showToast('SUCCESS', 'Payment was successfully created!', 'SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    closePaidLoans: function(component) {
        var accountId = component.get("v.recordId");
        var action = component.get('c.closeMultipleLoans');
        var sType = component.get("v.paymentSearchTypeSelected");


        action.setParams({
            opportunitiesList: component.get("v.oppList"),
            accountId: accountId,
            searchType: sType,
            payoutDate: component.get("v.paymentDate")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.oppList", response.getReturnValue());
                this.showToast('SUCCESS', 'Payment(s) was successfully created!', 'SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    changeToBadDebt: function(component, oppId) {
        var accountId = component.get("v.recordId");
        var action = component.get('c.changeToBadDebtStage');
        action.setParams({ oppId: oppId, accountId: accountId, payoutDate: component.get("v.paymentDate") });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.oppList", response.getReturnValue());
                this.showToast('SUCCESS', 'Opportunity stage was changed to bad debt!', 'SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    changeToSurplus: function(component, oppId) {
        var accountId = component.get("v.recordId");
        var action = component.get('c.changeToSurplusStage');
        action.setParams({ oppId: oppId, accountId: accountId, payoutDate: component.get("v.paymentDate") });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.oppList", response.getReturnValue());
                this.showToast('SUCCESS', 'Opportunity stage was changed to surplus!', 'SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    changeToShortfall: function(component, oppId) {
        var accountId = component.get("v.recordId");
        var action = component.get('c.changeToShortfallStage');
        action.setParams({ oppId: oppId, accountId: accountId, payoutDate: component.get("v.paymentDate") });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.oppList", response.getReturnValue());
                this.showToast('SUCCESS', 'Opportunity stage was changed to shortfall!', 'SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getTransactionItems: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getTransactions');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.TransactionItems", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getOpportunityTransactions: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getOpptyTransactions');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.OpportunityTransactions", response.getReturnValue());
                var oppTrans = component.get('v.OpportunityTransactions');

                var paymentAmountTotal = 0;
                var advanceTotal = 0;
                var accruedInterestTotal = 0;
                var outstandingBalanceTotal = 0;
                var perDiemTotal = 0;
                for (var op in oppTrans) {
                    var opp = oppTrans[op];
                    paymentAmountTotal += opp.paymentAmountSubtotal;
                    advanceTotal += opp.advanceSubtotal;
                    accruedInterestTotal += opp.accruedInterestSubtotal;
                    outstandingBalanceTotal += opp.outstandingBalanceSubtotal;
                    perDiemTotal += opp.perDiemSubtotal;
                }
                component.set('v.paymentAmountTotal', paymentAmountTotal);
                component.set('v.advanceTotal', advanceTotal);
                component.set('v.accruedInterestTotal', accruedInterestTotal);
                component.set('v.outstandingBalanceTotal', outstandingBalanceTotal);
                component.set('v.perDiemTotal', perDiemTotal);

                component.set("v.spinner", false);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getFirmHistoryList: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getFirmHistory');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.firmHistory", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getContactHistoryList: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getContactHistory');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.contactsHistory", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getAmendmentsList: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getFinancingStatementHistory');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.amendmentList", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getLoanSummaryInfo: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getLoanSummary');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.LoanSummary", response.getReturnValue());
                component.set("v._columns", [{ label: 'Name', fieldName: 'Opportunity_Long_Name__c', type: 'text' },
                    { label: 'Stage', fieldName: 'StageName', type: 'text' },
                    { label: 'Stage Status', fieldName: 'Stage_Status__c', type: 'text' }
                ]);
                var loanSum = component.get("v.LoanSummary");
                if (loanSum.payoutDate) {
                    component.set("v.payoutDateSet", true);
                }
                component.set("v.spinner", false);
                component.set("v.estimatedTotalBalance", null);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    component.set("v.spinner", false);
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    generatePayout: function(component) {
        var recordId = component.get("v.recordId");
        var loan = component.get("v.LoanSummary");
        var pDate = loan.payoutDate;
        var action = component.get('c.generatePayoutBalance');
        action.setParams({ accountId: recordId, payoutDate: pDate })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.LoanSummary", response.getReturnValue());
                component.set("v.payoutDateSet", true);
                this.showToast('SUCCESS', 'Payout was successfully generated!', 'SUCCESS');
                component.set("v.spinner", false);
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getLatestOpportunity: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getRecentOpportunity');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                if (response.getReturnValue().Id == undefined || response.getReturnValue().Id == null) {
                    this.showToast('Error', 'Not a single opportunity found with stage closed with loan.');
                }
                component.set("v.oppObj", response.getReturnValue());

                //setting lookups
                component.set("v.selectedLookUpLawFirm.Id", component.get("v.oppObj").Law_Firm__c);
                component.set("v.selectedLookUpLawFirm.Name", (component.get("v.oppObj").Law_Firm__c ?
                    component.get("v.oppObj").Law_Firm__r.Name : ''));
                component.set("v.selectedLookUpLawFirm.BillingCity", (component.get("v.oppObj").Law_Firm__c ?
                    component.get("v.oppObj").Law_Firm__r.BillingCity : ''));
                component.set("v.selectedLookUpLawFirm.BillingState", (component.get("v.oppObj").Law_Firm__c ?
                    component.get("v.oppObj").Law_Firm__r.BillingState : ''));

                component.set("v.selectedLookUpLawyer.Id", component.get("v.oppObj").Lawyer__c);
                component.set("v.selectedLookUpLawyer.Name", (component.get("v.oppObj").Lawyer__c ?
                    component.get("v.oppObj").Lawyer__r.Name : ''));

                this.getLawyer(component, response.getReturnValue().Lawyer__c);

            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    deleteAccount: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.deleteAccount');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {

            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getLatestContact: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getLastContact');
        action.setParams({ accountId: recordId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.conObj", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    getLawyer: function(component, contactId) {
        //var contactId = component.get("v.oppObj.Lawyer__c");
        console.log('contactId>>> ' + contactId);
        var action = component.get('c.getLawyerInfo');
        action.setParams({ contactId: contactId })

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.lawyerObj", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    saveAccountInfo: function(component) {

        var action = component.get('c.saveAccount');

        //setting lookups
        component.set("v.accountObj.OwnerId", (component.get("v.selectedLookUpAccOwner.Id") ?
            component.get("v.selectedLookUpAccOwner.Id") : ''));

        var accountObj = component.get('v.accountObj');
        console.log("lawfirm: " + component.get("v.accountObj.Law_Firm__c"));
        action.setParams({ account: accountObj });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                console.log(response.getReturnValue());
                component.set("v.spinner", false);
                this.showToast('SUCCESS', 'Your changes were saved!', 'SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                console.log(JSON.stringify(errors));
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    } else {

                        //this.unknownErrorsHandler(JSON.stringify(errors));
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    saveOpp: function(component) {
        var oppObj = component.get('v.oppObj');
        var action = component.get('c.saveOppty');

        if (oppObj.Id != null) {


            //setting lookups
            component.set("v.oppObj.Law_Firm__c", (component.get("v.selectedLookUpLawFirm.Id") ?
                component.get("v.selectedLookUpLawFirm.Id") : ''));
            //setting lookups
            component.set("v.oppObj.Lawyer__c", (component.get("v.selectedLookUpLawyer.Id") ?
                component.get("v.selectedLookUpLawyer.Id") : ''));
            if (!oppObj) return;
            action.setParams({ opp: oppObj });

            action.setCallback(this, function(response) {
                var state = response.getState();

                if (state === 'SUCCESS') {
                    component.set("v.oppObj", this.getLatestOpportunity(component));
                } else if (state === 'ERROR') {
                    component.set("v.spinner", false);
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },

    saveContactInfo: function(component, contact) {
        var action = component.get('c.saveContact');

        action.setParams({ contact: contact });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                console.log(response.getReturnValue());
                component.set("v.spinner", false);
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },

    clearAllTabs: function(component, event) {        
        // this method set all tabs to hide and inactive
        var getAllLI = document.getElementsByClassName("customClassForTab");
        var getAllDiv = document.getElementsByClassName("customClassForTabData");
        for (var i = 0; i < getAllLI.length; i++) {
            getAllLI[i].className = "slds-tabs--scoped__item customClassForTab";
        }
        for (var i = 0; i < getAllDiv.length; i++) {            
            getAllDiv[i].className = "slds-tabs--scoped__content slds-hide customClassForTabData";
        }
        if (component.find('reserveTabLinkId'))
            component.find("reserveTabLinkId").getElement().className = 'slds-tabs_scoped__link reserve-tab-link';
    },

    getPickListValues: function(component, object, field, attributeId) {
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });


        picklistgetter.setCallback(this, function(response) {
            var opts = [];
            if (response.getState() == 'SUCCESS') {
                var allValues = response.getReturnValue();

                if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "--- None ---",
                        value: ""
                    });
                }
                for (var i = 0; i < allValues.length; i++) {
                    if (allValues[i].includes('===SEPERATOR===')) {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i].split('===SEPERATOR===')[0],
                            value: allValues[i].split('===SEPERATOR===')[1]
                        });
                    } else {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i],
                            value: allValues[i]
                        });
                    }
                }
                component.set('v.' + attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },

    errorsHandler: function(errors) {
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },

    unknownErrorsHandler: function() {
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error');
    },
    unknownErrorsHandler: function(msg) {
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error:' + msg);
    },

    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    formatPhone: function(component, event, field, object) {
        var obj = event.getParam("value");
        if (!obj) return;
        if (typeof(obj) === 'object') {
            obj = obj[field];
        }
        if (typeof(obj) === 'string') {
            obj = obj.replace(/[^\d]+/g, '')
                .replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
            component.set("v." + object + "." + field, obj);
        }
    },
    getCalendarMin: function(component) {
        var year = new Date().getFullYear() - 1;
        var min = year + '-01-01';
        component.set("v.calendarMin", min);
    },

    getCalendarMax: function(component) {
        var year = new Date().getFullYear() + 5;
        var max = year + '-12-31';
        component.set("v.calendarMax", max);
    },
    saveAccountOpptyAndContact: function(component) {
        var accountObj = component.get('v.accountObj');
        var contact = component.get('v.conObj');
        var opportunity = component.get('v.oppObj');
        var lawyer = component.get('v.lawyerObj');

        accountObj.BillingStreet = contact.MailingStreet;
        accountObj.BillingCity = contact.MailingCity;
        accountObj.BillingState = contact.MailingState;
        accountObj.BillingPostalCode = contact.MailingPostalCode;

        component.set('v.accountObj', accountObj);

        contact.AccountId = accountObj.Id;
        contact.ELF_File_No__c = accountObj.AccountNumber;
        contact.Existing_Litigation_Loans__c = opportunity.Existing_Litigation_Loans__c;
        contact.Have_you_ever_declared_bankruptcy__c = opportunity.Have_you_ever_declared_bankruptcy__c;
        component.set('v.conObj', contact);

        component.set("v.spinner", true);
        this.saveAccountInfo(component);
        this.saveContactInfo(component, contact);
        this.saveOpp(component);
    },
    getCurrentUser: function(component) {
        var action = component.get('c.getCurrentUserInfo');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                component.set("v.currentUser", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },
    validateCriticalDatesFields: function(component) {
        return new Promise(
            function(resolve, reject) {
                var allValid = component.find('fieldId').reduce(function(validSoFar, inputCmp) {
                    inputCmp.showHelpMessageIfInvalid();
                    return validSoFar && !inputCmp.get('v.validity').valueMissing;
                }, true);
                if (allValid) {
                    resolve(true);
                } else {
                    reject([{ message: 'Please fill missing required fields.' }]);
                }
            }
        );

    },
    parseNavigationHash: function(component) {
        if (window.location.hash) {
            var hash = window.location.hash.split('/');
            if (hash.length > 1) {
                component.set("v._selectedTabId", hash[1]);
                if (hash.length > 2) {
                    component.set("v._selectedSecondaryTabId", hash[2]);
                }
            }
        }
    },
    validatePaymentAction: function(component) {
        var paymentActionsMap = component.get("v.paymentActionsMap");
        var paymentActionsValidationMap = component.get("v.paymentActionsValidationMap");
        var oppList = component.get("v.oppList");
        var error = "";
        var i = 0;
        //console.log(oppList);
        for (var oppIndex in oppList) {
            var opp = oppList[oppIndex];
            //console.log(opp);
            //console.log(opp.Id + ' ' + paymentActionsMap[opp.Id] + ' ' +opp.Temp_Payment_Received__c);
            if ((!paymentActionsValidationMap[opp.Id])) {
                error += "Please select action for Loan " + (oppList.length - i) + ".";
            }
            i += 1;
        }
        if (error != "")
            error = "Unable to submit payment. " + error;
        component.set("v.paymentsError", error);
    },
    createTaskOnPaymentApplyingError: function(component, oppId) {
        var accountId = component.get("v.recordId");
        var actionMethod = component.get('c.createPaymentApplyingErrorTask');
        actionMethod.setParams({
            accountId: accountId,
            oppId: oppId
        });

        actionMethod.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {} else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(actionMethod);
    },
              
    submitPaymentsAsync: function(component) {
        var accountId = component.get("v.recordId");
        var actionMethod = component.get('c.applyPaymentAsync');
        var paymentActionsMap = component.get("v.paymentActionsMap");
        var sType = component.get("v.paymentSearchTypeSelected");
        var eft = component.get("v.EFT");
        var chq = component.get("v.CHQ");
        var wireFee = component.get("v.WireFee");
        var oppsIds = component.get("v.oppIdList");
        if (oppsIds.length > 0) {
            var oppId = oppsIds[oppsIds.length - 1];
            var action = paymentActionsMap[oppId];
            var OppBadDebtsValues = this.getBadReasons(component, oppId);
            
            var paymentInfos = [];            
            for (var i = oppsIds.length - 1; i >= 0; i--){
                var oppId = oppsIds[i];
                var action = paymentActionsMap[oppId];
                paymentInfos.push(
                    {accountId: accountId,
                         payoutDate: component.get("v.paymentDate"),
                         searchType: sType,
                         eft: eft,
                         chq: chq,
                         oppId: oppId,
                         action: action,
                     	 wireFee: wireFee,
                     	 OppBadDebts: (OppBadDebtsValues == "" || OppBadDebtsValues == null) ? '' : OppBadDebtsValues
                    }
                );
                wireFee = null;
            }            
            component.set("v.WireFee", null); 
            actionMethod.setParams({accountId: accountId, paymentInfos: paymentInfos});

            actionMethod.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    component.set("v.spinner", false);
                    component.set("v.accountObj.Is_Async_Processing__c", true);
                    this.showToast('SUCCESS','This loan contains a large number of drawdowns and will be updated in the background. Request has been recorded. You may now leave this page. It will reflect this update when the operation completes.','SUCCESS');                        
                } else if (state === 'ERROR') {
                    component.set("v.spinner", false);
                    var errors = response.getError();
                    console.log(errors);
                    this.postSubmitPayments(component, false);
                    this.createTaskOnPaymentApplyingError(component, oppId);
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                }
            });
            $A.enqueueAction(actionMethod);
        }
    },        
    submitNextPayment: function(component) {
        var accountId = component.get("v.recordId");
        var actionMethod = component.get('c.applyPayment');
        var paymentActionsMap = component.get("v.paymentActionsMap");
        var sType = component.get("v.paymentSearchTypeSelected");
        var eft = component.get("v.EFT");
        var chq = component.get("v.CHQ");
        var wireFee = component.get("v.WireFee");
        var oppsIds = component.get("v.oppIdList");
        if (oppsIds.length > 0) {
            var oppId = oppsIds[oppsIds.length - 1];
            var action = paymentActionsMap[oppId];
            var OppBadDebtsValues = this.getBadReasons(component, oppId);
            console.log('Submit next payment ' + oppId + ' ' + action + ' ' + oppsIds.length);
            actionMethod.setParams({
                accountId: accountId,
                payoutDate: component.get("v.paymentDate"),
                searchType: sType,
                eft: eft,
                chq: chq,
                wireFee: wireFee,
                oppId: oppId,
                action: action,
                isLastPayment: (oppsIds.length == 1),
                OppBadDebts: (OppBadDebtsValues == "" || OppBadDebtsValues == null) ? '' : OppBadDebtsValues
            });

            actionMethod.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var oppsIds = component.get("v.oppIdList");
                    oppsIds.pop();
                    component.set("v.oppIdList", oppsIds);
                    component.set("v.WireFee", null);                     
                    var newPayments = response.getReturnValue();
                    var createdPaymentList = component.get("v.createdPaymentList");
                    if (newPayments){                        
                    	createdPaymentList.push.apply(createdPaymentList, newPayments);
                        component.set("v.createdPaymentList", createdPaymentList);
                    }
                    if (oppsIds.length == 0){                        
                        component.set("v.displayPaymentValidationErrors", false);                                        
                        this.postSubmitPayments(component, true);              
                        var paymentIds = [];
                        for (var i = 0; i < createdPaymentList.length; i++){
                            paymentIds.push(createdPaymentList[i].Id);
                        }
                        if (paymentIds.length > 0){
                            this.linkPayments(component, paymentIds);
                            //this.showPaymentInstructionDialog(component, paymentIds);
                        }
                        this.showToast('SUCCESS','Success!','SUCCESS');                        
                    }
                    else this.submitNextPayment(component);
                    //this.getLoanSummaryInfo(component);
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    console.log(errors);
                    this.postSubmitPayments(component, false);
                    this.createTaskOnPaymentApplyingError(component, oppId);
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                }
            });
            $A.enqueueAction(actionMethod);
        }
    },
    submitPayments: function(component) {
        this.validatePaymentAction(component);
        component.set("v.displayPaymentValidationErrors", true);
        var errorMessage = component.get("v.paymentsError");
        if (errorMessage != "") {
            component.set("v.spinner", false);
            return;
        }
        var paymentActionsMap = component.get("v.paymentActionsMap");
        var oppsList = component.get("v.oppList");
        var oppsIds = new Array();
        for (var oppIndex in oppsList) {
            //console.log(paymentActionsMap[oppsList[oppIndex].Id]);
            if (paymentActionsMap[oppsList[oppIndex].Id]) {
                oppsIds.push(oppsList[oppIndex].Id);
                //console.log(oppsList[oppIndex].Id);
            }
        }
        if (oppsIds.length > 0) {
            component.set("v.oppIdList", oppsIds);
            component.set("v.createdPaymentList", []);
            this.runAction(component, 'c.needAsyncProcessing', {oppIds: oppsIds})
            .then(
                (result) => {                                
                    if (result)
                    	this.submitPaymentsAsync(component);
                    else
                    	this.submitNextPayment(component);
                },
                (errors) => {
                    component.set("v.spinner", false);
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                }
          	)                        
        }
    },
    getBadReasons : function(component, OppId){
        var oppsList = component.get("v.oppList");
        var BadDebtArr = [];
        for (var oppIndex in oppsList){
                BadDebtArr[oppsList[oppIndex].Id] = (!oppsList[oppIndex].Bad_Debt_Reason__c) ? '' : oppsList[oppIndex].Bad_Debt_Reason__c;
        }
        return BadDebtArr[OppId];
    },
    getBadReasons : function(component, OppId){
        var oppsList = component.get("v.oppList");
        var BadDebtArr = [];
        for (var oppIndex in oppsList){
                BadDebtArr[oppsList[oppIndex].Id] = (!oppsList[oppIndex].Bad_Debt_Reason__c) ? '' : oppsList[oppIndex].Bad_Debt_Reason__c;
        }
        return BadDebtArr[OppId];
    },
    estimateTotalBalance: function(component) {
        var opps = component.get("v.oppList");
        //console.log(opps);
        var estTotalBalance = 0.0;
        for (var oppIndex in opps) {
            var opp = opps[oppIndex];
            //  console.log(opp);
            if (opp.Is_Stage_Status_Active__c)
                estTotalBalance += opp.Total_Payout__c;
        }

        component.set("v.estimatedTotalBalance", estTotalBalance);
        /*var calculatedPaymentAmount = component.get('v.calculatedPaymentAmount');
        if (!calculatedPaymentAmount)
            return;
        console.log('calculated ' +calculatedPaymentAmount);
    	var loanSummary = component.get("v.LoanSummary");        
        var totalBalance = loanSummary.balance;
        totalBalance -= calculatedPaymentAmount;
        if (totalBalance < 0.0)
            totalBalance = 0.0;
        component.set("v.estimatedTotalBalance", totalBalance);*/
    },
    postSubmitPayments : function(component, isSuccess){
        var self = this;
        this.getOpportunitiesList(component)
        .then(
            function(result){    
                console.log('postSubmitPayments');
                console.log(result);
                component.set("v.spinner", false);                         
                component.set("v.paymentSearchDisabled", false); 
                self.estimateTotalBalance(component);                                
                if (isSuccess){
                    component.set('v.calculatedPaymentAmount', null);    	
                    component.set('v.paymentAmount', null);
                    component.set('v.EFT', null);
                    component.set('v.CHQ', null);
                }
            },
            function(error){                                
                component.set("v.spinner", false);
            }
        );        
    },
    formatCurrency: function(amount) {
        //https://developer.salesforce.com/index.php?title=Format_Number_as_Currency.js&oldid=9020
        if (isNaN(amount)) { return '0.00'; }
        var s = new String(amount);
        if (s.indexOf('.') < 0) { s += '.00'; }
        if (s.indexOf('.') == (s.length - 2)) { s += '0'; }
        var delimiter = ",";
        var a = s.split('.', 2);
        var d = a[1];
        var n = a[0];
        var a = [];
        while (n.length > 3) {
            var block = n.substr(n.length - 3);
            a.unshift(block);
            n = n.substr(0, n.length - 3);
        }
        if (n.length > 0) { a.unshift(n); }
        n = a.join(delimiter);

        return s = n + '.' + d;
    },
    activeLoanExists: function(component) {
        var sType = component.get("v.paymentSearchTypeSelected");
        var opps = component.get("v.oppList");
        //console.log(opps);
        for (var oppIndex in opps) {
            var opp = opps[oppIndex];
            //  console.log(opp);
            //console.log(sType + ' ' + opp.Stage_Status__c);
            if ( ((sType=='Payout' || sType == 'Payout - Interest First') && opp.Is_Stage_Status_Active__c ) ||
               ( sType=='Bad Debt Recovery' && opp.StageName == 'Closed With Loan' && (opp.Stage_Status__c == 'Closed - Paid' || opp.Stage_Status__c == 'Closed - Surplus' || opp.Stage_Status__c == 'Closed - Shortfall' || opp.Stage_Status__c == 'Closed - Bad Debt') ) ||
               ( sType=='Refund'))
                	return true;
        }
        return false;
    },

    saveAccountPromise: function(component) {
        return new Promise($A.getCallback(
            function(resolve, reject) {
                var action = component.get('c.saveAccount');
                var accountObj = component.get('v.accountObj');

                action.setParams({ account: accountObj });
                action.setCallback(this, function(response) {
                    var state = response.getState();

                    if (state === 'SUCCESS') {
                        resolve(response.getReturnValue());
                    } else if (state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    setReasonForLTVOptions: function(component) {
        let accountObj = component.get("v.accountObj");

        let options = [];
            /*if(accountObj.Projected_Loan_Value__c > 0 && accountObj.Total_Amount_Loaned__c > 0){
                if(accountObj.Total_Amount_Loaned__c/accountObj.Projected_Loan_Value__c == 0){
                    options.push({'label' : 'Lawyer Relationship', 'value' : 'Lawyer Relationship'});
                }
            }else{
                options.push({'label' : 'Lawyer Relationship', 'value' : 'Lawyer Relationship'});
            }*/
            if(accountObj.Total_Amount_Loaned__c > 0 && accountObj.Projected_Loan_Value__c > 0){
                if(accountObj.Total_Amount_Loaned__c / accountObj.Projected_Loan_Value__c <= 0.15){
                    component.set("v.reasonavailability", false);
                }
                if(accountObj.Total_Amount_Loaned__c / accountObj.Projected_Loan_Value__c > 0.15){
                    component.set("v.reasonavailability", true);
                    options.push({'label' : 'Business Development', 'value' : 'Business Development'});
                    options.push({'label' : 'Lawyer Relationship', 'value' : 'Lawyer Relationship'});
                    options.push({'label' : 'Assessment Loan - NA', 'value' : 'Assessment Loan - NA'});
                    options.push({'label' : 'Strong Case', 'value' : 'Strong Case'});
                    options.push({'label' : 'Settled File', 'value' : 'Settled File'});
                }
            }
        let selectedReason = '';
        for (let i = 0; i < options.length; i++) {
            if (options[i].value == accountObj.Reason_for_LTV__c) {
                selectedReason = accountObj.Reason_for_LTV__c;
            }
        }

        component.set("v.selectedReasonForLTV", selectedReason);

        component.set("v.ReasonForLTV", options);
    },
    getApprovalProcessHistoryInfo: function(component) {
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get("c.getApprovalProcessHistoryInfo");
                action.setParams({
                    recordId: component.get("v.recordId")
                });

                action.setCallback(this, function(response) {
                    let state = response.getState();

                    if (state === 'SUCCESS') {
                        resolve(response.getReturnValue());
                    } else if (state === 'ERROR') {
                        reject(response.getError());
                    }

                });
                $A.enqueueAction(action);
            }
        ));
    },
    validateLTV: function(component) {
        return new Promise(
            function(resolve, reject) {
                let accountObj = component.get("v.accountObj");
                let selectedReasonForLTV = component.get("v.selectedReasonForLTV");
                if (accountObj.Projected_Loan_Value__c > 0 && accountObj.Total_Amount_Loaned__c > 0) {
                    if (accountObj.Total_Amount_Loaned__c / accountObj.Projected_Loan_Value__c >= 0.15 && (selectedReasonForLTV == null || selectedReasonForLTV == '')) {
                        resolve(false);
                    } else
                        resolve(true);
                } else
                    resolve(true);
            });
    },
    loadAccountReserveInfo: function(component) {

        var recordId = component.get("v.recordId");
        var action = component.get('c.getAccountReserveInfo');
        component.set("v.spinner", true);
        action.setParams({ accountId: recordId })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                var acc = response.getReturnValue();
                component.set("v.accountObj.Reserved_Loans_Count__c", acc.Reserved_Loans_Count__c);
                component.set("v.accountObj.Is_Reserve_Applied__c", acc.Is_Reserve_Applied__c);
                component.set("v.accountObj.Exclude_from_Payout__c", acc.Exclude_from_Payout__c);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
    },
    populateReserveTableColumns: function(component){
        component.set("v._reserveColumns",[{label:'Reserve',fieldName:'Is_Reserve_Applied__c',type:'boolean', editable: false, align: 'center'},
									{label:'Stop Interest',fieldName:'Stop_Interest__c',type:'boolean', editable: false, align: 'center'},                                           
                                    {label:'Loan',fieldName:'Name',type:'text', align: 'left'}, 
									{label:'Reserve Date',fieldName:'Reserve_Date__c',type:'date-local', editable: true, align: 'right'},                                          
                                    {label:'Principal Advanced to Freeze Date',fieldName:'Principal_Advanced_To_Reserve_Date__c',type:'currency', align: 'right'},
                                    {label:'Accrued Interest to Freeze Date',fieldName:'Interest_Accrued_as_of_Reserve_Date__c',type:'currency', align: 'right'},                                    
                                    {label:'FV at Freeze Date',fieldName:'FV_at_Freeze_Date__c',type:'currency', editable: true, align: 'right'},                                                                                     
                                    {label:'Advances after Freeze Date',fieldName:'Advances_after_Reserve_Date__c',type:'currency', align: 'right'},
                                    {label:'Payments after Freeze Date',fieldName:'Payments_after_Reserve_Date__c',type:'currency', align: 'right'},                                    
                                    //{label:'Principal Advanced',fieldName:'Non_Repaid_Drawdown_Principal_Total__c',type:'currency', align: 'right'},
                                    //{ label: 'Accrued Interest', fieldName: 'Reserve_Non_Repaid_Interest__c', type: 'currency', align: 'right' },
									{label:'FV Before Reserve',fieldName:'Value_At_Reserve_Date__c',type:'currency', editable: true, align: 'right'},                                          
                                    {label:'Reserve Amount',fieldName:'Reserve_Amount__c',type:'currency', editable: true, align: 'right'},
                                    { label: 'Exposure', fieldName: 'Reserve_Exposure__c', type: 'currency', align: 'right' }]);
    },
    populateReserveTableData: function(component){
        var oppsList = component.get("v.oppList");
        var data = [];
        var totalPrincipalAtFreezeDate = 0.0;
        var totalAccruedInterestAtFreezeDate = 0.0;
        var totalPrincipal = 0.0;
        var totalAccruedInterest = 0.0;
        var totalAdvancesAfterFreezeDate = 0.0;        
        var totalPaymentsAfterFreezeDate = 0.0;        
        var fvAtFreezeDate = 0.0;
        var valueAtReserveDate = 0.0;
        var totalReserveAmount = 0.0;
        var totalExposure = 0.0;
        for (var i = 0; i < oppsList.length; i++) {
            var opp = oppsList[i];
            var name = opp.Name;
            var isInterestFrozen = opp.Is_Reserve_Applied__c && opp.Stop_Interest__c;
            if (opp.Loan_Requests__c)
                name += ' - ' + opp.Loan_Requests__c;            
            var items = [{itemName: 'Is_Reserve_Applied__c', value: opp.Is_Reserve_Applied__c, align: 'center', type: 'boolean', editable: true},
                {itemName: 'Stop_Interest__c', value: opp.Stop_Interest__c, align: 'center', type: 'boolean', editable: true},                       
                {itemName: name, value: name, align: 'left', type: 'text', editable: false},
                {itemName: 'Reserve_Date__c', value: isInterestFrozen ? opp.Reserve_Date__c : '-', align: 'right', type: isInterestFrozen ? 'date' : 'text', editable: isInterestFrozen},
                {itemName: 'Principal_Advanced_To_Reserve_Date__c', value: isInterestFrozen ? opp.Principal_Advanced_To_Reserve_Date__c : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false},
                {itemName: 'Interest_Accrued_as_of_Reserve_Date__c', value: isInterestFrozen ? opp.Interest_Accrued_as_of_Reserve_Date__c : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false},                                               
                {itemName: 'FV_at_Freeze_Date__c', value: isInterestFrozen ? opp.FV_at_Freeze_Date__c : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false},                                                                            
                {itemName: 'Advances_after_Reserve_Date__c', value: isInterestFrozen ? opp.Advances_after_Reserve_Date__c : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false},
                {itemName: 'Payments_after_Reserve_Date__c', value: isInterestFrozen ? opp.Payments_after_Reserve_Date__c : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false},                                               
                {itemName: 'Value_At_Reserve_Date__c', value: opp.Value_At_Reserve_Date__c, align: 'right', type: 'currency', editable: false},
                {itemName: 'Reserve_Amount__c', value: opp.Reserve_Amount__c, align: 'right', type: 'currency', editable: true},
                {itemName: 'Reserve_Exposure__c', value: opp.Reserve_Exposure__c, align: 'right', type: 'currency', editable: false }];
            var row = {id: opp.Id, items: items};
            data.push(row);
            if (isInterestFrozen){
                if (opp.Principal_Advanced_To_Reserve_Date__c)
                    totalPrincipalAtFreezeDate += opp.Principal_Advanced_To_Reserve_Date__c;
                if (opp.Interest_Accrued_as_of_Reserve_Date__c)
                    totalAccruedInterestAtFreezeDate += opp.Interest_Accrued_as_of_Reserve_Date__c;
                if (opp.FV_at_Freeze_Date__c)
                    fvAtFreezeDate += opp.FV_at_Freeze_Date__c;            
                if (opp.Advances_after_Reserve_Date__c)
                    totalAdvancesAfterFreezeDate += opp.Advances_after_Reserve_Date__c;                        
                if (opp.Payments_after_Reserve_Date__c)
                    totalPaymentsAfterFreezeDate += opp.Payments_after_Reserve_Date__c;                                    
            }
            if (opp.Value_At_Reserve_Date__c)
                valueAtReserveDate += opp.Value_At_Reserve_Date__c;
            if (opp.Reserve_Amount__c)
                totalReserveAmount += opp.Reserve_Amount__c;
            if (opp.Reserve_Exposure__c)
                totalExposure += opp.Reserve_Exposure__c;            
        }
        var totalItems = [{ value: '', align: 'center', type: 'text', editable: false, bold: true },
            { value: '', align: 'right', type: 'text', editable: false, bold: true },
            { value: 'Total', align: 'right', type: 'text', editable: false, bold: true },
            { value: '', align: 'right', type: 'text', editable: false, bold: true },
                          {value: isInterestFrozen ? totalPrincipalAtFreezeDate : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false, bold: true},
            {value: isInterestFrozen ? totalAccruedInterestAtFreezeDate : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false, bold: true},            
            {value: isInterestFrozen ?  fvAtFreezeDate : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false, bold: true},                          
            {value: isInterestFrozen ?  totalAdvancesAfterFreezeDate : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false, bold: true},
            {value: isInterestFrozen ?  totalPaymentsAfterFreezeDate : '-', align: 'right', type: isInterestFrozen ? 'currency' : 'text', editable: false, bold: true},
            {value: valueAtReserveDate, align: 'right', type: 'currency', editable: false, bold: true},                          
            { value: totalReserveAmount, align: 'right', type: 'currency', editable: false, bold: true },
            { value: totalExposure, align: 'right', type: 'currency', editable: false, bold: true }];
        var totalRow = { id: '', items: totalItems };
        data.push(totalRow);
        component.set("v._reserveData", data);
    },
    getReserveInfoMaps: function(component, changedRecords) {
        var records = [];
        var columns = component.get("v._reserveColumns");
        for (var i = 0; i < changedRecords.length; i++) {
            var rec = changedRecords[i];
            var mapToSend = {};
            mapToSend["Id"] = rec.id;
            for (var j = 0; j < rec.items.length; j++) {
                var item = rec.items[j];
                if (item.editable) {
                    var column = columns[j];
                    mapToSend[column.fieldName] = item.value;
                }
            }
            records.push(mapToSend);
        }

        return records;
    },
    saveReserveTable: function(component, changedRecords) {
        var records = this.getReserveInfoMaps(component, changedRecords);
        console.log(records);
        var self = this;
        return new Promise($A.getCallback(
            function(resolve, reject){
                for (var i = 0; i < records.length; i++) {
                    console.log(records[i]);
                    if (records[i]["Is_Reserve_Applied__c"] && records[i]["Stop_Interest__c"] && !records[i]["Reserve_Date__c"]) {
                        reject('Reserve Date cannot be empty');
                        return;
                    }
                }
                var action = component.get('c.applyReserve');
                action.setParams({ reserveInfos: records });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    console.log(state);
                    if (state === 'SUCCESS') {
                        resolve(response.getReturnValue());
                    } else if (state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    reloadReserveTable: function(component) {
        component.set("v.spinner", true);
        this.getOpportunitiesList(component)
            .then(
                (result) => {
                    component.set("v.spinner", false);
                    this.populateReserveTableColumns(component);
                    this.populateReserveTableData(component);
                },
                (error) => {
                    component.set("v.spinner", false);
                }
            );
    },
    getPaymentInfo : function(component){
        var recordId = component.get("v.recordId");
        var action = component.get('c.getPaymentSummaryItem'); 
        var self = this;
        return new Promise($A.getCallback(
            function(resolve, reject){        
                //action.setParams({ accountId : recordId})                        
                action.setCallback(this, function (response) {
                    var state = response.getState();                                
                    if (state === 'SUCCESS') {                
                        resolve(response.getReturnValue()); 
                    } else if (state === 'ERROR') {                        
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action); 
            }
        ));
    },
    showPaymentInstructionDialog: function(component, paymentIds){
		console.log('showPaymentInstructionDialog' + paymentIds);
        this.getLastPaymentsSummary(component, paymentIds)
        .then(
            $A.getCallback(function(result) {  
                console.log(result);
                var paymentSummaryItems = result;
                $A.createComponent(
                    "c:PaymentInstructionSummaryComponent",
                    {
                        paymentSummaryItems: paymentSummaryItems
                    }
                    ,
                    function(formComponent, status, errorMessage){
                        if (status === "SUCCESS") {
                            let modalPromise = component.find("overlayLib").showCustomModal({
                                body: formComponent,
                                cssClass: "cCustomerViewComponent payment-instruction-modal",
                                //cssClass: "slds-modal_small",
                                showCloseButton: true,
                                closeCallback: function() {}
                            });
                            component.set("v.paymentInstructionModalPromise", modalPromise);                    
                        } else {
                            console.error(errorMessage);
                        }
                    }
                );   
            }),
            $A.getCallback(function(errors) {
                if (errors[0] && errors[0].message) {
                    helper.errorsHandler(errors)
                }else {
                    helper.unknownErrorsHandler();
                }                
            })
        );
    },
    getPaymentSummary: function(component, loadPayments){        
        var recordId = component.get("v.recordId");
        return this.runAction(component, loadPayments ? 'c.getPaymentItems' : 'c.getPaymentSummaryItems', { accountId : recordId});
    },
    getPaymentSummary: function(component, loadPayments){        
        var recordId = component.get("v.recordId");
        return this.runAction(component, loadPayments ? 'c.getPaymentItems' : 'c.getPaymentSummaryItems', { accountId : recordId});
    },
    getLastPaymentsSummary: function(component, paymentIds){        
        var recordId = component.get("v.recordId");
        return this.runAction(component, 'c.getLastPaymentSummaryItems', { accountId : recordId, paymentIds : paymentIds});
    },                
	getLastPaymentsSummary: function(component, paymentIds){        
        var recordId = component.get("v.recordId");        
        return this.runAction(component, 'c.getLastPaymentSummaryItems', { accountId : recordId, paymentIds : paymentIds});
    },    
    linkPayments : function(component, paymentIds){
        var recordId = component.get("v.recordId"); 
        var balance = component.get("v.LoanSummary.balance");
        console.log();
        return this.runAction(component, 'c.linkPayments', { accountId : recordId, drawdownIds : paymentIds, balance : balance});             
    },                
	loadPaymentSummaryTab: function(component){                
        this.getPaymentSummary(component, false)
        .then(
            (result) => {                                
                console.log(result);
                component.set("v.PaymentSummaryItems", result);
                return this.getPaymentSummary(component, true)
            },
            (error) => {
                component.set("v.spinner", false);
            }
        )
        .then(
            (result) => {                
                component.set("v.spinner", false);
                console.log(result);
                component.set("v.paymentDetailsItems", result);
            },
            (error) => {
                component.set("v.spinner", false);
            }
        )
    },
	excludeFromLawyerStatements : function(component){
        let accountObj = component.get("v.accountObj");

        var recordId = component.get("v.recordId");
        var action = component.get('c.excludeFromLawyerStmts');
        var self = this;
        return new Promise($A.getCallback(
            function(resolve, reject) {
                action.setParams({ accountId: recordId, needExclude: accountObj.Exclude_from_Payout__c })
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        resolve('SUCCESS');
                    } else if (state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    handleErrors: function(errors) {
        if (errors) {
            if (errors[0] && errors[0].message) {
                this.errorsHandler(errors)
            }
        } else {
            this.unknownErrorsHandler();
        }
    },
    isAvailableCreditApplicable: function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.isAvailableCreditApplicable');
        var self = this;
        return new Promise($A.getCallback(
            function(resolve, reject) {
                action.setParams({ accountId: recordId })
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        resolve(response.getReturnValue());
                    } else if (state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
	handleCustomCellChanged: function(component, recordId, cellItem) {                
        if (cellItem && cellItem.itemName == 'Stop_Interest__c'){
            var tableComp = component.find('reservetable');
            var isInterestFrozen = (cellItem.value == true);
            var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
            var updatedCellItem = {itemName: 'Reserve_Date__c', value: isInterestFrozen ? today : '-', align: 'right', type: isInterestFrozen ? 'date' : 'text', editable: isInterestFrozen};
            tableComp.updateCell(recordId, updatedCellItem);
        }        
    },
    runAction: function(component, actionName, params){ 
        console.log('runAction ' + params);
        var action = component.get(actionName); 
        var self = this;
        return new Promise($A.getCallback(
            function(resolve, reject){        
                action.setParams(params)                        
                action.setCallback(this, function (response) {
                    var state = response.getState();                                
                    if (state === 'SUCCESS') {                
                        resolve(response.getReturnValue()); 
                    } else if (state === 'ERROR') {                        
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action); 
            }
        ));
    },  	
})
