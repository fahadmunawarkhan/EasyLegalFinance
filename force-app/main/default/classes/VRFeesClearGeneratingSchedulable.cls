global class VRFeesClearGeneratingSchedulable implements Schedulable{
	global void execute(SchedulableContext sc)    
    {
        clear(-30);
    }
	public static void clear(Integer minutesOffset){
        DateTime dt = DateTime.now().addMinutes(minutesOffset);
        List<Opportunity> opps = [select Id, VR_Fees_Generating_In_Progress__c, VR_Fees_Generating_Start_Time__c from Opportunity where VR_Fees_Generating_In_Progress__c = true and VR_Fees_Generating_Start_Time__c < :dt];        
        if (!opps.isEmpty()){
            for (Opportunity opp : opps){
                opp.VR_Fees_Generating_In_Progress__c = false;
                opp.VR_Fees_Generating_Start_Time__c = null;
			}
            Database.update(opps, false);
        }
    }
}