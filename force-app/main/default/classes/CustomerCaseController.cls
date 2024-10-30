public without sharing class CustomerCaseController {
  
    @AuraEnabled(cacheable=true)
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

    /*public static Map<String, Object> createContact(String firstName, String lastName, String email, String phone){
        Database.SaveResult saveResult = Database.insert(new Contact(FirstName = firstName, LastName = lastName, Email = email, Phone = phone));
        return opperateInsertResult(saveResult); 
    }

    public static Map<String, Object> createCase(String subject, String contactPhone, Id contactId){
        Database.SaveResult saveResult = Database.insert(new Case(Subject = subject, ContactPhone = contactPhone, ContactId = contactId));
        return opperateInsertResult(saveResult); 
    }

    private Map<String, Object> opperateInsertResult(Database.SaveResult saveResult){
        Map<String, Object> result = new Map<String, Object>();
        String message = '';
        Boolean isSuccess = saveResult.isSuccess();

        if(isSuccess){
            message = 'Created successfully';
        }
        else{
            message = 'The following errors have occurred:';
            for(Database.Error err : saveResult.getErrors()) {
                message += '\r\n' + err.getMessage();                    
            }
        }

        result.put('message', message);
        result.put('isSuccess', isSuccess);

        return result;
    }*/
}