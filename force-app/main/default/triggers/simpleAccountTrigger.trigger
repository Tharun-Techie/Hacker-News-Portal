trigger simpleAccountTrigger on Account(before insert, after insert, before update,after update, before delete, after delete){
    List<Account> oldAccList = Trigger.old;
    List<Account> newAccList = Trigger.new;
    system.debug(oldAccList);
    Map<Id,Account> oldAccMap = Trigger.oldMap;
    Map<Id,Account> newAccMap = Trigger.newMap;
    	
 /*
    
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            for(Account acc: newAccList){
                if(acc.Name == null){
                    acc.addError('Name cannot be null bruh!!!');
                }
            }
        }
        
    }
*/
    
   /* 
    if(Trigger.isDelete){
        
        if(Trigger.isBefore){
            AccountTriggerHandler.preventAccountDeleteWhenAccNumGenereted(oldAccList);

        }
    }
    */
    
    /*
    switch on Trigger.operationType{
        when BEFORE_INSERT{
            
            for(Account acc: newAccList){
                if(acc.Name == null || acc.Phone == null){
                    acc.addError('Account cannot be created with Name or Phone No be empty');
                }
            }
            
        }
        
        when AFTER_INSERT{
            
        }
        
        
        When BEFORE_DELETE{
            //AccountTriggerHandler.preventAccountDeleteWhenAccNumGenereted(oldAccList); 
            //AccountTriggerHandler.preventAccountWhenNameSLAisPresent(oldAccList);
            
        }
    }
       
    
	*/
    
    

    
    
system.debug(Trigger.size);                                            

    
System.debug('Trigger.operationType: '+ Trigger.operationType);    
                                            
                                            
                                            
                                            
                                        
                                        
}