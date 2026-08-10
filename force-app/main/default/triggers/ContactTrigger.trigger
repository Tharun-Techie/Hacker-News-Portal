trigger ContactTrigger on Contact (before update, after update) {
    List<Contact> oldConList = Trigger.old;
    List<Contact> newConList = Trigger.new;
    

}