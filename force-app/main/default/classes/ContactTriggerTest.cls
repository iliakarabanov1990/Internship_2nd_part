@isTest
private class ContactTriggerTest {

    @TestSetup
    static void makeData(){
        List<Account> accts = new List<Account>();
        List<Contact> conts = new List<Contact>();

        accts.add(new Account(Name='Test Account1', AccountSource = 'Other'));
        accts.add(new Account(Name='Test Account2', AccountSource = 'Web'));

        Database.insert(accts, true, AccessLevel.USER_MODE);

        conts.add(new Contact(LastName='Test Account1_1', AccountId = accts[0].Id));
        conts.add(new Contact(LastName='Test Account1_2', AccountId = accts[0].Id));
        conts.add(new Contact(LastName='Test Account2_1', AccountId = accts[1].Id));
        conts.add(new Contact(LastName='Test Account2_2', AccountId = accts[1].Id));
    
        Database.insert(conts, true, AccessLevel.USER_MODE);
    }

    @isTest
    static void TestUpdateContact() {

        List<Contact> conts = [SELECT Id, AccountId FROM Contact LIMIT 1];
        conts[0].Email = 'sc@gmail.com';

        Test.startTest();
            Database.update(conts, true, AccessLevel.USER_MODE);
        Test.stopTest();
        
        System.assertEquals(2, [SELECT Contacts_Count__c FROM Account WHERE Id = :conts[0].AccountId LIMIT 1][0].Contacts_Count__c, 'update test account is failed');     
    }

    @isTest
    static void TestChangeContactsAccount() {

        List<Contact> conts = [SELECT Id, AccountId FROM Contact LIMIT 1];
        List<Account> accs = [SELECT Id FROM Account WHERE Id != :conts[0].AccountId LIMIT 1];
        conts[0].AccountId = accs[0].Id;

        Test.startTest();
            Database.update(conts, true, AccessLevel.USER_MODE);
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Contacts_Count__c FROM Account WHERE Id != :accs[0].Id LIMIT 1][0].Contacts_Count__c, 'change account test is failed in old acc');
        System.assertEquals(3, [SELECT Contacts_Count__c FROM Account WHERE Id = :accs[0].Id LIMIT 1][0].Contacts_Count__c, 'pdate test account is failed in new acc');     
    }

    @isTest
    static void TestInsertContact() {

        List<Contact> conts = [SELECT AccountId FROM Contact LIMIT 1];

        Test.startTest();
            Database.insert(new Contact(LastName='Test Account3', AccountId = conts[0].AccountId), true, AccessLevel.USER_MODE);
        Test.stopTest();
        
        System.assertEquals(3, [SELECT Contacts_Count__c FROM Account WHERE Id = :conts[0].AccountId LIMIT 1][0].Contacts_Count__c, 'insert test account is failed');     
    }

    @isTest
    static void TestDeleteContact() {

        List<Contact> conts = [SELECT AccountId FROM Contact LIMIT 1];
        Id acc = conts[0].AccountId;

        Test.startTest();
            Database.delete(conts, true, AccessLevel.USER_MODE);
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Contacts_Count__c FROM Account WHERE Id = :acc LIMIT 1][0].Contacts_Count__c, 'delete test account is failed');     
    }

    @isTest
    static void TestUndeleteContact() {

        List<Contact> conts = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Id con = conts[0].Id; 
        Id acc = conts[0].AccountId;

        Test.startTest();
            Database.delete(conts, true, AccessLevel.USER_MODE);
            Database.undelete(con, true, AccessLevel.USER_MODE);
        Test.stopTest();
        
        System.assertEquals(2, [SELECT Contacts_Count__c FROM Account WHERE Id = :acc LIMIT 1][0].Contacts_Count__c, 'undelete test account is failed');            
    }
}