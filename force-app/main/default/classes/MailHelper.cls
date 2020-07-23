public class MailHelper {
    public static void sendSingleMessage(String addressFrom, List<String> addressesTo, String subject, String message, Boolean isPlainText){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :addressFrom];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if ( owea.size() > 0 ) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        email.setToAddresses(addressesTo);
        email.setSubject(subject);
        if (isPlainText)
        	email.setPlainTextBody(message);        
        else
            email.setHtmlBody(message);        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: '
                         + results[0].errors[0].message);
        }
    }
}