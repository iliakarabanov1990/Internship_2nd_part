@isTest
private class VisitPlannerControllerTest {

    @TestSetup
    static void makeData(){

        Id profileId = [Select Id From Profile Where Name = 'Karo Pharma CH - Account Manager']?.Id;
        User kKUser = DataFactory.prepareUser('', profileId, 'Amit', 'Singh');

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        List<OpeningHours__c> opHours = new List<OpeningHours__c>();
        List<Account> accs = new List<Account>();
        accs.add(new Account(LastName = 'Test1', RecordTypeId = accRecordTypeId, PersonEmail = 'liakarabanov@gmail.com'));
        accs.add(new Account(LastName = 'Test2', RecordTypeId = accRecordTypeId, PersonEmail = 'liakarabanov@gmail.com'));

        
        insert accs;

        for(Account acc : accs){
            opHours.add(new OpeningHours__c(
                Day_Of_Week__c = 'Monday', 
                Preferred_Time__c = 12,
                Opening_Time__c = Time.newInstance(7,0,0,0),
                Closing_Time__c = Time.newInstance(17,0,0,0),
                Account__c = acc.Id));            
        }
           
        insert opHours;
    }

    @isTest
    static void addEventsTest(){
        List<Id> accIds = new List<Id>(new Map<Id, Account>([SELECT Id FROM Account]).keySet());
        Test.startTest();     
        VisitPlannerController.addEvents(System.today(), accIds);
        Test.stopTest();

        Assert.areEqual(2, [SELECT Count() FROM Event], 'Wrong event creation!');
    }

    @isTest
    static void sendEmailsTest(){
        List<Id> accIds = new List<Id>(new Map<Id, Account>([SELECT Id FROM Account]).keySet());
        List<Id> eventIds = VisitPlannerController.addEvents(System.today(), accIds);
        
        Test.startTest();         
            VisitPlannerController.sendEmails(eventIds, accIds);
        Test.stopTest();
    }
}