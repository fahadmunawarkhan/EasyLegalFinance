@isTest
public class UtilsTest {
    public static testmethod void testFormatDate(){
        System.assertEquals('Dec 28, 2019', Utils.formatDate(Date.newInstance(2019, 12, 28), 'MMM dd, yyyy'));
    }
    
    public static testmethod void testFormatCurrency(){
        System.assertEquals('10,000.50', Utils.formatCurrency(10000.5));
    }    
}