@isTest
private class VisitPlannerControllerTest {

    @TestSetup
    static void makeData(){

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        List<OpeningHours__c> opHours = new List<OpeningHours__c>();
        List<Account> accs = new List<Account>();
        accs.add(new Account(LastName = 'Test1', RecordTypeId = accRecordTypeId));
        accs.add(new Account(LastName = 'Test2', RecordTypeId = accRecordTypeId));

        insert accs;

        for(Account acc : accs){
            opHours.add(new OpeningHours__c(
                Day_Of_Week__c = 'Monday', 
                Preferred_Time__c = 12,
                Opening_Time__c = Time.newInstance(7,0,0,0),
                Closing_Time__c = Time.newInstance(17,0,0,0),
                Account__c = acc.Id));  

            //conts.add(new Contact(FirstName = 'FName2', LastName = 'LName2', Email = 'iliakarabanov@gmail.com', Phone = '111', AccountId = acc.Id));
            
        }
       
        insert opHours;
        
        List<Contact> conts = [SELECT Id, Email FROM Contact];
        for(Contact con : conts){
            con.Email = 'liakarabanov@gmail.com';//silvia.boehi@karopharma.com.dev
        }

        update conts;
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

        /*EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'name';
        validEmailTemplate.DeveloperName = 'Visit_Email_Template_1733310669865';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();

        insert validEmailTemplate;*/

        List<Id> accIds = new List<Id>(new Map<Id, Account>([SELECT Id FROM Account]).keySet());

        VisitPlannerController.addEvents(System.today(), accIds);
   
        List<Id> eventIds = new List<Id>(new Map<Id, Event>([SELECT Id FROM Event]).keySet());
        
        Test.startTest();
        //VisitPlannerController.sendEmails(eventIds, accIds);
        Test.stopTest();



        //Assert.areEqual(2, [SELECT Count() FROM Event], 'Wrong email creation!');

    }

}