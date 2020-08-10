public class PaymentInstructionCtlr {
	@AuraEnabled
    public static void emailBookkeeper(String subject, String message){
        Bookkeeper__mdt bookkeeper = [select Email__c from Bookkeeper__mdt where DeveloperName='Bookkeeper_Email'];
        System.debug(bookkeeper.Email__c);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'info@easylegal.ca'];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if ( owea.size() > 0 ) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        String[] sendingTo = new String[]{bookkeeper.Email__c};
        email.setToAddresses(sendingTo);
        email.setSubject(subject);
        email.setHtmlBody(message);        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
	}
}