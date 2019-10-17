@isTest(seeAllData=false)
public class FacilityLoanSchedulingTest {

    @isTest
    static void test_full_process_amount() {
        // Test with no account set on SP
        DateUtil.today = Date.newInstance(2019, 1, 1);
        DateUtil.now = Datetime.newInstance(2019, 1, 1);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(1)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        opp.CloseDate = DateUtil.today();
        update opp;

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date dt = Dateutil.today();
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt.month(), sp.Scheduled_Date__c.month(), 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            dt = dt.addMonths(1);
        }

        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
        }

        sp1 = spList[0];
        System.assertEquals(opp.Id, sp1.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp1.Amount__c, sp1.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp1.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp1.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        dt = DateUtil.today();
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt.month(), sp.Scheduled_Date__c.month(), 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            dt = dt.addMonths(1);
        }
        test.stopTest();
        /*

        Scheduled_Payment__c sp2 = spList[1];
        sp2.Status__c = 'Approved to Send';
        sp2.Banking_Verified__c = true;
        sp2.BIA_PPSA_LL_Verified__c = true;
        sp2.Credit_Verified__c = true;
        sp2.Documents_Verified__c = true;
        update sp2;

        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp2.Id});

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
        }

        sp2 = spList[1];
        System.assertEquals(opp.Id, sp2.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp2.Amount__c, sp2.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp2.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp2.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        dt = DateUtil.today();
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt.month(), sp.Scheduled_Date__c.month(), 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            dt = dt.addMonths(1);
        }
        */

    }

    @isTest
    static void test_full_process_date() {
        // Test with no account set on SP
        DateUtil.today = Date.newInstance(2019, 1, 1);
        DateUtil.now = Datetime.newInstance(2019, 1, 1);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(1)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.End_Date__c = opp.Start_Date__c.addMonths(5);
        opp.Day_of_Month__c = '1st';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        opp.CloseDate = DateUtil.today();
        update opp;

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date dt = Dateutil.today();
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt.month(), sp.Scheduled_Date__c.month(), 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            dt = dt.addMonths(1);
        }

        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
        }

        sp1 = spList[0];
        System.assertEquals(opp.Id, sp1.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp1.Amount__c, sp1.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp1.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp1.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        dt = DateUtil.today();
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt.month(), sp.Scheduled_Date__c.month(), 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            dt = dt.addMonths(1);
        }
        test.stopTest();
    }
}