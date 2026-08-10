public class AccountDataHandler {

    public inherited sharing class Inherited {
        public void getAccountRec(){
            List<Account> accList = [SELECT Id, Name From Account];

            System.debug(accList.size());
        }
    }

    public with sharing class WithSharing {
        public void getAccountRec(){
            List<Account> accList = [SELECT Id, Name From Account];

            System.debug(accList.size());
        }
    }

    public without sharing class WithoutSharing {

        public void getAccountRec(){
            List<Account> accList = [SELECT Id, Name From Account];

            System.debug(accList.size());
        }
    }
}