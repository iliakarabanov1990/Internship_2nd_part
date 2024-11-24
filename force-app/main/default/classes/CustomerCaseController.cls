public without sharing class CustomerCaseController {
  
    @AuraEnabled()
    public static List<Contact> getContact(String firstName, String lastName, String email){
        return [SELECT Id FROM Contact WHERE FirstName = :firstName AND LastName = :lastName AND Email = :email];
    }

    @AuraEnabled
    public static Id createContact(String firstName, String lastName, String email, String phone){    
        Contact cont = new Contact(FirstName = firstName, LastName = lastName, Email = email, Phone = phone);      
        insert cont;
        return cont.Id; 
    }

    @AuraEnabled
    public static Id createCase(String subject, String suppliedPhone, String suppliedEmail, Id contactId){    

        Case cas = new Case(Status= 'New', Origin = 'Web', Subject = subject, SuppliedPhone = suppliedPhone, SuppliedEmail = suppliedEmail, ContactId = contactId);
        Database.DmlOptions dmlOptions = new Database.DmlOptions();
        dmlOptions.assignmentRuleHeader.UseDefaultRule = true;
        Database.insert(cas, dmlOptions);
        return cas.Id; 
    }
}