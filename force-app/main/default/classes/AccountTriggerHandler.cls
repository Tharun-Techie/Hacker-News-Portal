public class AccountTriggerHandler {
    
    public static void createOpportunity(List<Account> accList){
        List<Opportunity> oppList = new List<Opportunity>();
        
        for(Account acc: accList){
            Opportunity opp = new Opportunity(
            	Name = acc.Name + 'Opportunity',
            	StageName = 'Prospecting',
            	CloseDate = System.today().addDays(30),
                AccountId = acc.Id
                );
            
            oppList.add(opp);
        }
        if(!oppList.isEmpty()){
            insert oppList;
        }
        
    }

    
    public static void handleEmailChange(List<Account> newAccounts, Map<Id,Account> oldMap){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Account acc: newAccounts){
            Account oldAcc = oldMap.get(acc.Id);

            if(oldAcc != null){

                if (acc.Email__c != oldAcc.Email__c && String.isNotBlank(oldAcc.Email__c)){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                    mail.setToAddresses(new List<String>{ oldAcc.Email__c});

                    mail.setSubject('Email Address Updated');

                    String EMAIL_BODY = 
                        'Hello,\n\n' +
                        'This is to inform you that the email address associated with Account "' +
                        acc.Name +
                        '" has been changed.\n\n' +
                        'Previous Email: ' + oldAcc.Email__c + '\n' +
                        'New Email: ' + acc.Email__c + '\n\n' +
                        'This email is sent for your information.';

                    mail.setPlainTextBody(EMAIL_BODY);

                    emails.add(mail);
                }
            }
        }

        if(!emails.isEmpty()){
            Messaging.sendEmail(emails);
        }

    }

    
    public static void preventAccountDeleteWhenAccNumGenereted(List<Account> oldAccList){
        
        for(Account acc: oldAccList){  
                if(acc.AccountNumber != null){
                    acc.addError('Account number is already generated, you cannot delete this record');
                }
            }
    	}
    
    public static void preventAccountWhenNameSLAisPresent(List<Account> oldAccList){
        
        for(Account acc: oldAccList){
            system.debug(oldAccList);
            if(acc.Name !=null && acc.SLA__c != null){
                acc.addError('Deleting Account is Ristricted');
            }
        }
    }
    
    
    
    public static void checkDublicateNames(List<Account> accList){
        
        
        
    }
}