public class LeadsPerMonthReportPrintController {
    public List<LeadsPerMonthReportCtlr.wrapperClass> data{get; private set;}
    public Actual_Sales_by_Month_Report__c LFSR{get;set;}
    public integer Count{get;set;}
    
    public integer ConvertedCount{get;set;}
    
    public double Amount{get;set;}
	public LeadsPerMonthReportPrintController()
    {
        LFSR = Actual_Sales_by_Month_Report__c.getOrgDefaults();
        data = LeadsPerMonthReportCtlr.getLeadsByMonth(LFSR.start_Date__c+'',LFSR.End_Date__c+'',LFSR.Business_Unit__c);
        
        Count = 0;
        ConvertedCount = 0;
        Amount = 0;
        
        for(LeadsPerMonthReportCtlr.wrapperClass d: data)
        {
            Count += d.RecordCount;            
            ConvertedCount += d.SumofConvertedLeads;            
            Amount += d.SumofAmountPaidtoClient;
        }
    }
}