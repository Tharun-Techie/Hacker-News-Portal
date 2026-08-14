public class AccountDataHandler {

    public inherited sharing class Inherited {
        public void getAccountRec(){
            // OPTIMIZED: bounded query with LIMIT 50 to avoid 50k row limit / heap
            List<Account> accList = [SELECT Id, Name FROM Account WITH USER_MODE LIMIT 50];
            System.debug(accList.size());
        }
    }

    public with sharing class WithSharing {
        public void getAccountRec(){
            List<Account> accList = [SELECT Id, Name FROM Account WITH USER_MODE LIMIT 50];
            System.debug(accList.size());
        }
    }

    public without sharing class WithoutSharing {
        public void getAccountRec(){
            List<Account> accList = [SELECT Id, Name FROM Account WITH USER_MODE LIMIT 50];
            System.debug(accList.size());
        }
    }
}