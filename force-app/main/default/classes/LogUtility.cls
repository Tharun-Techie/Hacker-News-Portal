public class LogUtility {
    public static String getCurrentClassName(Exception ex){
        String stackTrace = ex.getStackTraceString().substringAfter('Class.');
        String currentClass = stackTrace.substringBefore('.');
        return currentClass; 
    } 
    
    
    public static void main(){
        try{
            Integer res = 10/0;
        }
        catch(Exception ex){
            System.debug(ex.getStackTraceString());
            System.debug(LogUtility.getCurrentClassName(ex));
        }
        
    }
}