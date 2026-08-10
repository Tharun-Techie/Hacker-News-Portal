@IsTest
private class TriggerCoverageTest {

    @IsTest static void testAccountTriggerNameChangeBlocked() {
        Account acc = new Account(Name='TestAccTrigger1', Industry='Technology');
        insert acc;
        // try to change Name - should be blocked
        acc.Name = 'ChangedName';
        Boolean threw = false;
        try { update acc; } catch(DmlException e) { threw = true; System.debug(e.getMessage()); }
        Assert.isTrue(threw, 'Account Name change should be blocked');

        // update without Name change should succeed
        Account acc2 = [SELECT Id, Name FROM Account WHERE Id=:acc.Id];
        acc2.Industry = 'Finance';
        update acc2;
        Assert.areEqual('TestAccTrigger1', [SELECT Name FROM Account WHERE Id=:acc.Id].Name);
    }

    @IsTest static void testStudentTriggerDOBMandatory() {
        // without DOB should fail
        Student__c s1 = new Student__c(Name='TestStudent1');
        Boolean threw = false;
        try { insert s1; } catch(DmlException e) { threw = true; }
        Assert.isTrue(threw, 'Student without DOB should fail');

        // with DOB should succeed
        Student__c s2 = new Student__c(Name='TestStudent2', Date_of_Birth__c=Date.today().addYears(-20));
        insert s2;
        Assert.isNotNull(s2.Id);
    }

    @IsTest static void testContactTrigger() {
        Account acc = new Account(Name='TriggerContactAcc');
        insert acc;
        Contact con = new Contact(FirstName='Trigger', LastName='ContactTest', AccountId=acc.Id, Email='trigger@test.com');
        insert con;
        // update to fire before update + after update (trigger does assignment only)
        con.LastName = 'ContactTest2';
        update con;
        Assert.areEqual('ContactTest2', [SELECT LastName FROM Contact WHERE Id=:con.Id].LastName);
        // also test no-op
        update con;
    }
}
