/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-12-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-12-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class LeadsPerMonthReportPrintController {
    public List<LeadsPerMonthReportCtlr.wrapperClass> data{get; private set;}
    public Actual_Sales_by_Month_Report__c LFSR{get;set;}
    public integer Count{get;set;}
    
    public integer ConvertedCount{get;set;}
    
    public double Amount{get;set;}
	public LeadsPerMonthReportPrintController()
    {
        LFSR = Actual_Sales_by_Month_Report__c.getOrgDefaults();
        List<String> businessUnit = new List<String>();
        for(String bu : LFSR.Business_Unit__c.replace('|', ',').split(',')){
            String bunit = bu.replace('\'', '');
            businessUnit.add(bunit);
        }
        data = LeadsPerMonthReportCtlr.getLeadsByMonth(LFSR.start_Date__c+'',LFSR.End_Date__c+'',businessUnit);
        
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