@isTest
public class CustomerCaseControllerTest {
    
    @TestSetup
	static void testSetup() {    
        
        List<Contact> conts = new List<Contact>();
 		conts.add(new Contact(FirstName = 'FName1', LastName = 'LName1', Email = 'Email1@Email1.com'));
       	conts.add(new Contact(FirstName = 'FName2', LastName = 'LName2', Email = 'Email2@Email2.com'));
        insert conts;
  	}  
    
    @isTest
    static void testGetContact(){

    	Test.startTest();
           List<Contact> conts = CustomerCaseController.getContact('FName1', 'LName1', 'Email1@Email1.com');
    	Test.stopTest();
    
    	Assert.areEqual(1, conts.size(), 'wrong size of returning contacts');
    }
                  
    @isTest
    static void testCreateContact(){

    	Test.startTest();
           CustomerCaseController.createContact('FName3', 'LName3', 'Email3@Email3.com', 'Phone3');
    	Test.stopTest();
    
        Assert.areEqual(3, [SELECT Id FROM Contact].size(), 'wrong size of returning contacts');
    }
                  
    @isTest
    static void testCreateCase(){

        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
    	Test.startTest();
           CustomerCaseController.createCase('Subject', 'Phobe', 'Email4@Email4.com', con.Id);
    	Test.stopTest();
    
        Assert.areEqual(1, [SELECT Id FROM Case].size(), 'wrong size of returning cases');
    }
}