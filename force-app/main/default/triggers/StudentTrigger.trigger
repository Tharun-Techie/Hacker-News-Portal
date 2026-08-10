trigger StudentTrigger on Student__c (before insert) {
    
    if(Trigger.isInsert){
        
            for(Student__c st: Trigger.New){
                if(st.Date_of_Birth__c == null){
                    st.addError('Date of birth is mandatory');
                }
            }
    
    }

}