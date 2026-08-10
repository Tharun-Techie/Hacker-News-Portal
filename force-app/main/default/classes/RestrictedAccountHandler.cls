public without sharing class RestrictedAccountHandler {
    
    public static List<Account> getMyAccessibleAccounts(){
        
        return [SELECT Id, Name, OwnerId FROM Account LIMIT 50];
    }

}