@isTest
public class IncomingCallControllerTest {
    
    @TestSetup
	static void testSetup() { 
        
        Id businessTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        Id personRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        List<Account> accs = new List<Account>();
 		accs.add(new Account(FirstName = 'FName1', LastName = 'LName1', RecordTypeId = personRecordTypeId, Phone = '111'));
       	accs.add(new Account(Name = 'FName2', RecordTypeId = businessTypeId, Phone = '111'));
        insert accs;
        
        List<Contact> conts = new List<Contact>();
 		conts.add(new Contact(FirstName = 'FName2', LastName = 'LName2', Email = 'Email1@Email2.com', Phone = '111'));
       	conts.add(new Contact(FirstName = 'FName3', LastName = 'LName3', Email = 'Email2@Email3.com', Phone = '111'));
        insert conts;
  	}  
    
    @isTest
    static void testGetAccountsContactsNameFieldsWithoutPersonCont(){
   
        Id [] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = [SELECT Id FROM Account WHERE FirstName = 'FName1' LIMIT 1].Id;
       
        Test.setFixedSearchResults(fixedSearchResults);
        
    	Test.startTest();
           List<List<sObject>> objs = IncomingCallController.getAccountsContacts('LName', 'NAME FIELDS');
    	Test.stopTest();
      
    
    	Assert.areEqual(2, objs.size(), 'wrong size of returning ojects');
        Assert.areEqual(1, objs[0].size(), 'wrong size of returning accounts');
        Assert.areEqual(0, objs[1].size(), 'wrong size of returning contacts');
    }
 
    @isTest
    static void testGetAccountsContactsNameFields(){
        
        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = [SELECT Id FROM Account WHERE Name = 'FName2' LIMIT 1].Id;
        fixedSearchResults[1] = [SELECT Id FROM Contact WHERE FirstName = 'FName2' LIMIT 1].Id;
        Test.setFixedSearchResults(fixedSearchResults);

    	Test.startTest();
           List<List<sObject>> objs = IncomingCallController.getAccountsContacts('FName2', 'NAME FIELDS');
    	Test.stopTest();
    
    	Assert.areEqual(2, objs.size(), 'wrong size of returning ojects');
        Assert.areEqual(1, objs[0].size(), 'wrong size of returning accounts');
        Assert.areEqual(1, objs[1].size(), 'wrong size of returning contacts');
    }
       
    @isTest
    static void testGetAccountsContactsPhoneFields(){
        
        Id [] fixedSearchResults = new Id[4];
        fixedSearchResults[0] = [SELECT Id FROM Account WHERE FirstName = 'FName1' LIMIT 1].Id;
        fixedSearchResults[1] = [SELECT Id FROM Contact WHERE FirstName = 'FName2' LIMIT 1].Id;
        fixedSearchResults[2] = [SELECT Id FROM Account WHERE Name = 'FName2' LIMIT 1].Id;
        fixedSearchResults[3] = [SELECT Id FROM Contact WHERE FirstName = 'FName3' LIMIT 1].Id;
        Test.setFixedSearchResults(fixedSearchResults);

    	Test.startTest();
           List<List<sObject>> objs = IncomingCallController.getAccountsContacts('111', 'PHONE FIELDS');
    	Test.stopTest();
    
    	Assert.areEqual(2, objs.size(), 'wrong size of returning ojects');
        Assert.areEqual(2, objs[0].size(), 'wrong size of returning accounts');
        Assert.areEqual(2, objs[1].size(), 'wrong size of returning contacts');
    }
    
    @isTest
    static void testGetBusinessRecordTypeId(){

    	Test.startTest();
         	Id recordTypeId = IncomingCallController.getBusinessRecordTypeId();
    	Test.stopTest();
    
        Id recordTypeIdCheck = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
    	Assert.areEqual(recordTypeIdCheck, recordTypeId, 'wrong recordType');
    }
}