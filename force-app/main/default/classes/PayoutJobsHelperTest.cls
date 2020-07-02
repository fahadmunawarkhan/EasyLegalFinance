@isTest
public class PayoutJobsHelperTest {
    public static testMethod void testGetCurrentPayoutJobs(){
        List<AsyncApexJob> currentJobs = PayoutJobsHelper.getCurrentPayoutJobs();        
    }
    public static testMethod void testCheckJobsEmptyList(){
        PayoutJobsHelper.checkJobs(new List<AsyncApexJob>());
    }
    public static testMethod void testCheckJobs(){
        List<AsyncApexJob> currentJobs = new List<AsyncApexJob>();
        Integer exceptionsCount = 0;
        try{
        	currentJobs.add(new AsyncApexJob());            
        	PayoutJobsHelper.checkJobs(currentJobs);
        }
        catch(AuraHandledException ex){
            exceptionsCount += 1;
        }
        System.assertEquals(1, exceptionsCount);
    }
}