public class PayoutJobsHelper {
    public static List<AsyncApexJob> getCurrentPayoutJobs(){
        List <Payout_Bath_Job__mdt> payoutJobs = [SELECT MasterLabel, DeveloperName FROM Payout_Bath_Job__mdt];
        Map<String, Payout_Bath_Job__mdt> devNameToPayoutJobsMap = new Map<String, Payout_Bath_Job__mdt>();
        for(Payout_Bath_Job__mdt pJob : payoutJobs){
            devNameToPayoutJobsMap.put(pJob.DeveloperName, pJob);
        }
        
        
        List<AsyncApexJob> currentJobs = [SELECT Id ,Status, ApexClass.Name, CreatedBy.Name, CreatedDate
                                          FROM AsyncApexJob
                                          WHERE Status!='Aborted'
                                          AND ApexClass.Name IN :devNameToPayoutJobsMap.keySet()
                                          AND Status!='Completed'
                                          AND Status!='Failed'
                                          ORDER BY CreatedDate DESC];
        return currentJobs;
    }
    
    @TestVisible
    private static void checkJobs(List<AsyncApexJob> currentJobs){        
        if(!currentJobs.isEmpty()){
            String m = 'Cannot execute this job because ' + currentJobs[0].CreatedBy.Name + ' ran a similar job at ' + currentJobs[0].CreatedDate + '.';
            m += '\nPlease try again later.';
            
            AuraHandledException e = new AuraHandledException(m);
            e.setMessage(m);
            throw e;
        }
    }
    
    public static void checkJobs(){        
        checkJobs(getCurrentPayoutJobs());
    }
}