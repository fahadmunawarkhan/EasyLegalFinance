public class Utils {
    //https://salesforce.stackexchange.com/questions/318/what-is-a-concise-function-that-formats-a-string-decimal-into-a-currency-forma
    public static String formatCurrency(Decimal i) {
        if (i == null) return '0.00';
        i = Decimal.valueOf(Math.roundToLong(i * 100)) / 100;
        String s = (i.setScale(2) + (i >= 0 ? 0.001 : -0.001)).format();
        return s.substring(0, s.length() - 1);
    }
    
    public static String formatDate(Date d, String format){
        if (d == null)
            return '';
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day());
        return dt.format(format);
    }
}