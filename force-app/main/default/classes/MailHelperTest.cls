@isTest
public class MailHelperTest {
	public static testmethod void testGetPaymentSummaryItem(){
        test.startTest();
        MailHelper.sendSingleMessage('from@test.com', new String[]{'to@test.com'}, 'Subject', 'Message', true);
        test.stopTest();
    }
}