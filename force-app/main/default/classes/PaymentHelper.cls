/**
*    @description : Helper class for payments
**/
public with sharing class PaymentHelper {
    
    /**
    * @description Method to calculate payments for amount mode
    * @param opportunity Opportunity
    * @return List<Scheduled_Payment__c> List of payment schedules
    **/
    public static List<Scheduled_Payment__c> calculatePaymentsForAmount(Opportunity opportunity, Scheduled_Payment__c[] inProcessPayments, Scheduled_Payment__c[] processedPayments){
        // Need to refresh opp in case scheduled payments have been modified
        //opportunity = [SELECT Id, Payment_Scheduled_Allotment_Remaining__c, Start_Date__c, End_Date__c FROM Opportunity WHERE Id = :opportunity.Id];
        List<Scheduled_Payment__c> paymentsList = new List<Scheduled_Payment__c>();

        Decimal inProcessAmount = 0;
        Integer skipPaymentCount = 0;
        if (inProcessPayments != null) {
            skipPaymentCount = inProcessPayments.size();
            inProcessAmount = calculateInProcessAmount(opportunity, inProcessPayments);
        }

        Integer numPayments = 0;
        if (processedPayments != null) {
            skipPaymentCount += processedPayments.size();
        }
        
        // calculate payments
        Decimal amountAvailableToDrawdown = opportunity.Payment_Scheduled_Allotment_Remaining__c - inProcessAmount;
        Scheduled_Payment__c sp;
        if (needsImmediatePayment(opportunity, inProcessPayments, processedPayments) && amountAvailableToDrawdown > 0) {
            sp = new Scheduled_Payment__c(
                    Opportunity_Schedule_Version_Number__c = opportunity.Payment_Schedule_Version_Number__c,
                    Current_Opportunity_Schedule_Version_Val__c = true,
                    Amount__c = amountAvailableToDrawdown > opportunity.Drawdown_Amount__c ? opportunity.Drawdown_Amount__c : amountAvailableToDrawdown,
                    Scheduled_Date__c = DateUtil.today(),
                    Status__c = Constants.PAYMENT_SCHEDULED_STATUS,
                    Payment_Type__c = Constants.PAYMENT_SCHEDULED_TYPE,
                    Opportunity__c=opportunity.Id,
                    Use_Primary_Bank_Account__c=opportunity.Payment_Use_Primary_Bank_Account__c,
                    Account__c=opportunity.AccountId,
                    Bank_Account__c=opportunity.Payment_Default_Bank_Account__c
                );
            if (skipPaymentCount == 0) {
                paymentsList.add(sp);
                amountAvailableToDrawdown -= sp.Amount__c;
            }
            numPayments = 1;
        }

        Integer counter = 0;
        Date currentDate;
        while(amountAvailableToDrawdown > 0) {
            currentDate = getPaymentDate(opportunity, counter);
            if (currentDate != null) {
                numPayments += 1;
                sp = new Scheduled_Payment__c(
                        Opportunity_Schedule_Version_Number__c = opportunity.Payment_Schedule_Version_Number__c,
                        Current_Opportunity_Schedule_Version_Val__c = true,
                        Amount__c = amountAvailableToDrawdown > opportunity.Drawdown_Amount__c ? opportunity.Drawdown_Amount__c : amountAvailableToDrawdown,
                        Scheduled_Date__c = currentDate,
                        Status__c = Constants.PAYMENT_SCHEDULED_STATUS,
                        Payment_Type__c = Constants.PAYMENT_SCHEDULED_TYPE,
                        Opportunity__c=opportunity.Id,
                        Use_Primary_Bank_Account__c=opportunity.Payment_Use_Primary_Bank_Account__c,
                        Account__c=opportunity.AccountId,
                        Bank_Account__c=opportunity.Payment_Default_Bank_Account__c
                    );
                if (numPayments > skipPaymentCount) {
                    paymentsList.add(sp);
                    amountAvailableToDrawdown -= sp.Amount__c;
                }
            }

            counter++;
        } 
        /*
        if (inProcessPayments != null) {
            System.debug(paymentsList);
            for (Integer i = 1; i <= inProcessPayments.size(); i++) {
                if (!paymentsList.isEmpty() && i > skipPaymentCount - processedPayments.size()) {
                    paymentsList.remove(0);
                }
            }
        }
        */
        System.debug(paymentsList);
        return paymentsList;
    }

    public static Decimal calculateInProcessAmount(Opportunity opp, Scheduled_Payment__c[] inProcessPayments){
        Decimal inProcessAmount = 0;
        if (opp.Amount_Available_for_Scheduled_Payments__c < opp.Payment_Schedule_Allotted_Amount__c - opp.Amount_sent_from_current_Schedule__c) {
            // already factored in from formula
        } else if (inProcessPayments != null) {
            for (Scheduled_Payment__c inProcessPayment : inProcessPayments) {
                inProcessAmount += inProcessPayment.Amount__c;
            }
        }
        return inProcessAmount;
    }


    /**
    * @description Method to calculate payments for amount mode
    * @param opportunity Opportunity
    * @return List<Scheduled_Payment__c> List of payment schedules
    **/
    public static Boolean needsImmediatePayment(Opportunity opportunity, Scheduled_Payment__c[] inProcessPayments, Scheduled_Payment__c[] processedPayments){
        if (opportunity.Payment_Schedule_Send_First_Immediately__c) {
            Date proposedDate = getPaymentDate(opportunity, 0);
            return proposedDate == null || !proposedDate.isSameDay(DateUtil.today());
        }
        return false;
        /*
        PaymentHelper.recalculatePayments(new Id[]{'0068A000006JTLFQA4'});
        */
    }

    /**
    * @description
    * @author Seth Boyd | 4/17/2019
    * @param List<Id> opportunityIds
    * @return void
    */
    @InvocableMethod(label='Recalculate Payments' description='Recalculates Facility Payment Schedule')
    public static void recalculatePayments(List<Id> opportunityIds) {

        // Query Opportunities with Scheduled Payments
        
        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>([
            SELECT
                Id,
                Payment_Schedule_Version_Number__c,
                AccountId,
                Payment_Scheduled_Allotment_Remaining__c,
                Day_of_Month__c,
                Start_Date__c,
                End_Date__c,
                Drawdown_Amount__c,
                Payment_Schedule_Mode__c,
                Payment_Use_Primary_Bank_Account__c,
                Payment_Default_Bank_Account__c,
                Payment_Schedule_Send_First_Immediately__c,
                Amount_Available_for_Scheduled_Payments__c,
                Payment_Schedule_Allotted_Amount__c,
                Amount_sent_from_current_Schedule__c,
                (SELECT Id, Amount__c, Scheduled_Date__c, Status__c, Opportunity_Schedule_Version_Number__c, Current_Opportunity_Schedule_Version__c
                    FROM Scheduled_Payments__r
                    WHERE Payment_Type__c = 'Scheduled Facility' AND Drawdown__c != null AND Current_Opportunity_Schedule_Version__c = true
                    ORDER BY Scheduled_Date__c)
                    FROM Opportunity WHERE Id IN: opportunityIds AND Type_of_Loan__c =: Constants.FACILITY_LOAN LIMIT 45000]);

        Map<Id, Opportunity> inProcessOpportunitiesMap = new Map<Id, Opportunity>([
            SELECT
                Id,
                (SELECT Id, Amount__c, Scheduled_Date__c, Status__c, Opportunity_Schedule_Version_Number__c, Current_Opportunity_Schedule_Version__c
                    FROM Scheduled_Payments__r
                    WHERE Payment_Type__c = 'Scheduled Facility' AND Current_Opportunity_Schedule_Version__c = true
                    ORDER BY Scheduled_Date__c)
                    FROM Opportunity WHERE Id IN: opportunityIds AND Type_of_Loan__c =: Constants.FACILITY_LOAN LIMIT 45000]);

        Scheduled_Payment__c[] calculatedPayments;
        List<Scheduled_Payment__c> paymentsToAddAndUpdate = new List<Scheduled_Payment__c>(); 
        List<Scheduled_Payment__c> paymentsToDelete = new List<Scheduled_Payment__c>(); 

        List<Scheduled_Payment__c> modifiablePayments; 
        List<Scheduled_Payment__c> inProcessPayments; 
        List<Scheduled_Payment__c> processedPayments; 

        Integer paymentCount;

        if(!opportunitiesMap.isEmpty()){
            for(Opportunity opportunity : opportunitiesMap.values()){
                modifiablePayments = new List<Scheduled_Payment__c>(); 
                inProcessPayments = new List<Scheduled_Payment__c>(); 
                processedPayments = new List<Scheduled_Payment__c>();

                Opportunity inProcessOpp = inProcessOpportunitiesMap.get(opportunity.Id);
                system.debug(inProcessOpp);

                for (Scheduled_Payment__c sp : inProcessOpp.Scheduled_Payments__r) {
                    system.debug(sp);
                    if (constants.PAYMENT_SCHEDULE_MODIFIABLE_STATUSES.contains(sp.Status__c)) {
                        modifiablePayments.add(sp);
                    } else if (constants.PAYMENT_SCHEDULE_IN_PROCESS_STATUSES.contains(sp.Status__c) && sp.Current_Opportunity_Schedule_Version__c) {
                        inProcessPayments.add(sp);
                    } else if (constants.PAYMENT_SCHEDULE_PROCESSED_STATUSES.contains(sp.Status__c) && sp.Current_Opportunity_Schedule_Version__c) {
                        processedPayments.add(sp);
                    }
                }

                calculatedPayments = null;

                // Calculate payments for opp (returns Scheduled_Payment__c[] sorted by date asc)
                if (opportunity.Payment_Schedule_Mode__c == Constants.PAYMENT_MODE_DATE) {
                    calculatedPayments = calculatePaymentsForDate(opportunity, inProcessPayments, processedPayments);
                } else if (opportunity.Payment_Schedule_Mode__c == Constants.PAYMENT_MODE_AMOUNT){
                    calculatedPayments = calculatePaymentsForAmount(opportunity, inProcessPayments, processedPayments);
                }

                system.debug(calculatedPayments.size());
                system.debug(calculatedPayments);
                system.debug(modifiablePayments);

                // How many payments do we need to iterate?
                for (integer i = 0; i < calculatedPayments.size(); i++) {
                    if (modifiablePayments.size() < i + 1) {
                        // Add new payment
                        paymentsToAddAndUpdate.add(calculatedPayments[i]);
                    } else {
                        // Modify existing payment in place
                        modifiablePayments[i].Amount__c = calculatedPayments[i].Amount__c;
                        if (modifiablePayments[i].Opportunity_Schedule_Version_Number__c != calculatedPayments[i].Opportunity_Schedule_Version_Number__c) {
                            // Update other fields since payment configuration has changed
                            modifiablePayments[i].Scheduled_Date__c = calculatedPayments[i].Scheduled_Date__c;
                            modifiablePayments[i].Send_Cheque__c = calculatedPayments[i].Send_Cheque__c;
                            modifiablePayments[i].Bank_Account__c = calculatedPayments[i].Bank_Account__c;
                            modifiablePayments[i].Opportunity_Schedule_Version_Number__c = calculatedPayments[i].Opportunity_Schedule_Version_Number__c;
                            modifiablePayments[i].Current_Opportunity_Schedule_Version_Val__c = true;
                        }
                        paymentsToAddAndUpdate.add(modifiablePayments[i]);
                    }
                }

                // if number of payments has reduced delete the extra existing payments
                for (integer i = calculatedPayments.size(); i < modifiablePayments.size(); i++) {
                    paymentsToDelete.add(modifiablePayments[i]);
                }
            }
        }

        system.debug(paymentsToAddAndUpdate);
        system.debug(paymentsToAddAndUpdate.size());
        if(!paymentsToAddAndUpdate.isEmpty()){
            upsert paymentsToAddAndUpdate;
        }
        system.debug(paymentsToDelete);
        if(!paymentsToDelete.isEmpty()) delete paymentsToDelete;
    }

    /**
    * @description Method to calculate payments for amount mode
    * @param opportunity Opportunity
    * @return List<Scheduled_Payment__c> List of payment schedules
    public static void recalculatePayments(Opportunity opportunity, List<Scheduled_Payment__c> paymentsList){
        PaymentHelper.recalculatePayments(new Id[]{'0068A000006JTLFQA4'});
        // re-calculate payments
        Decimal amountAvailableToDrawdown = opportunity.Payment_Scheduled_Allotment_Remaining__c;
        for(Integer i=0;i<paymentsList.size();i++){
            if(amountAvailableToDrawdown >= paymentsList[i].Amount__c){
                amountAvailableToDrawdown -= paymentsList[i].Amount__c;
            }else if(amountAvailableToDrawdown < paymentsList[i].Amount__c && amountAvailableToDrawdown > 0){
                paymentsList[i].Amount__c = amountAvailableToDrawdown;
                amountAvailableToDrawdown = 0;
                DrawdownHelper.paymentsToAddAndUpdate.add(paymentsList[i]);
            }else if(amountAvailableToDrawdown == 0){
                DrawdownHelper.paymentsToDelete.add(paymentsList[i]);
            }
        }	
    }
    **/

    /**
    * @description Method to calculate payments for date mode
    * @param opportunity Opportunity
    * @return List<Scheduled_Payment__c> List of payment schedules
    **/
    public static List<Scheduled_Payment__c> calculatePaymentsForDate(Opportunity opportunity, Scheduled_Payment__c[] inProcessPayments, Scheduled_Payment__c[] processedPayments){
        // Need to refresh opp in case scheduled payments have been modified
        //opportunity = [SELECT Id, Payment_Scheduled_Allotment_Remaining__c, Start_Date__c, End_Date__c FROM Opportunity WHERE Id = :opportunity.Id];
        List<Scheduled_Payment__c> paymentsList = new List<Scheduled_Payment__c>();


        // calculate payments
        // Track if a facility payment has been sent on Opportunity
        // If not and Send_First_Payment_Immediately__c is checked
        //      Check to make sure that today isn't the first day in the normal schedule
        //          Change the way amount and numberOfMonths are calculated
        Boolean neededImmediate = false;
        if (needsImmediatePayment(opportunity, inProcessPayments, processedPayments)) {
            neededImmediate = true;
            paymentsList.add(
                new Scheduled_Payment__c(
                    Opportunity_Schedule_Version_Number__c = opportunity.Payment_Schedule_Version_Number__c,
                    Current_Opportunity_Schedule_Version_Val__c = true,
                    //Amount__c = amountAvailableToDrawdown > opportunity.Drawdown_Amount__c ? opportunity.Drawdown_Amount__c : amountAvailableToDrawdown,
                    Scheduled_Date__c = DateUtil.today(),
                    Status__c = Constants.PAYMENT_SCHEDULED_STATUS,
                    Payment_Type__c = Constants.PAYMENT_SCHEDULED_TYPE,
                    Opportunity__c=opportunity.Id,
                    Use_Primary_Bank_Account__c=opportunity.Payment_Use_Primary_Bank_Account__c,
                    Account__c=opportunity.AccountId,
                    Bank_Account__c=opportunity.Payment_Default_Bank_Account__c
                )
            );
        }

        Integer monthCounter = 0;
        if (opportunity.End_Date__c != null && opportunity.End_Date__c < DateUtil.today()) {
            // End Date is less than today, so there will be no payments calculated
            return paymentsList;
        }
        Date currentDate = getPaymentDate(opportunity, monthCounter);
        while(currentDate == null) {
            monthCounter++;
            currentDate = getPaymentDate(opportunity, monthCounter);
        }
        while(currentDate <= opportunity.End_Date__c) {
            paymentsList.add(
                new Scheduled_Payment__c(
                    Opportunity_Schedule_Version_Number__c = opportunity.Payment_Schedule_Version_Number__c,
                    Current_Opportunity_Schedule_Version_Val__c = true,
                    //Amount__c = opportunity.Payment_Scheduled_Allotment_Remaining__c/ numberOfMonths,
                    Scheduled_Date__c = currentDate,
                    Status__c = Constants.PAYMENT_SCHEDULED_STATUS,
                    Payment_Type__c = Constants.PAYMENT_SCHEDULED_TYPE,
                    Opportunity__c=opportunity.Id,
                    Use_Primary_Bank_Account__c=opportunity.Payment_Use_Primary_Bank_Account__c,
                    Account__c=opportunity.AccountId,
                    Bank_Account__c=opportunity.Payment_Default_Bank_Account__c
                )
            );
            monthCounter += 1;
            currentDate = getPaymentDate(opportunity, monthCounter);
        }
        System.debug(paymentsList);
        System.debug(paymentsList.size());
        Boolean removedImmediate = false;
        if (processedPayments != null) {
            for (Scheduled_Payment__c sp : processedPayments) {
                if (paymentsList.size() > 0) {
                    if (opportunity.Payment_Schedule_Send_First_Immediately__c && !removedImmediate) {
                        removedImmediate = true;
                    } else {
                        paymentsList.remove(0);
                    }
                }
            }
        }

        
        Decimal amountRemaining = opportunity.Payment_Scheduled_Allotment_Remaining__c - calculateInProcessAmount(opportunity, inProcessPayments);
        Decimal allotmentRemaining = amountRemaining;

        if (inProcessPayments != null) {
            for (Scheduled_Payment__c sp : inProcessPayments) {
                if (paymentsList.size() > 0) {
                    //amountRemaining -= sp.Amount__c;
                    if (opportunity.Payment_Schedule_Send_First_Immediately__c && !removedImmediate) {
                        removedImmediate = true;
                    } else {
                        paymentsList.remove(0);
                    }
                }
            }
        }

        if (removedImmediate == true && !paymentsList.isEmpty() && neededImmediate) {
            paymentsList.remove(0);
        }

        if (!paymentsList.isEmpty()) {
            Decimal amount = amountRemaining / paymentsList.size();
            amount = amount * 100;
            amount = amount.round();
            amount = amount / 100;
            system.debug(amount);
            // Account for numbers that don't divide into payments nicely. Keep statement split up because of apex not respecting ooo
            Decimal sumAmount = 0;
            if (amount == 0) {
                paymentsList.clear();
            } else {
                for (Scheduled_Payment__c sp : paymentsList) {
                    sp.Amount__c = amount;
                    sumAmount += amount;
                }
                if (sumAmount != allotmentRemaining) {
                    Decimal missingAmount = allotmentRemaining - sumAmount;
                    if (missingAmount > 0) {
                        paymentsList[0].Amount__c += missingAmount;
                    } else {
                        paymentsList[paymentsList.size() - 1].Amount__c += missingAmount;
                    }
                }
            }
        }

        return paymentsList;

    }
    
    /**
    * @description Method to create payments for amount mode
    * @param opportunity Opportunity
    * @return List<Scheduled_Payment__c> List of payment schedules
    **/
    private static Date getPaymentDate(Opportunity opportunity, Integer numberOfMonthsToAdd){
        Date paymentDate = opportunity.Start_Date__c.addMonths(numberOfMonthsToAdd);
        Date proposedDate;
        switch on opportunity.Day_of_Month__c{
            when '1st' {
                proposedDate = Date.newInstance(paymentDate.year(),paymentDate.month(),1);
            }
            when '15th' {
                proposedDate = Date.newInstance(paymentDate.year(),paymentDate.month(),15);
            }
            when 'Last' {
                proposedDate = Date.newInstance(paymentDate.year(),paymentDate.month(),Date.daysInMonth(paymentDate.year(),paymentDate.month()));
            }
        }
        if (proposedDate < DateUtil.today() || proposedDate < opportunity.Start_Date__c) {
            return null;
        }
        return proposedDate;
    }
}