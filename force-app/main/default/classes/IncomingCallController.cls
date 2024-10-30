public class IncomingCallController {
    
    @AuraEnabled(cacheable=true)
    public static List<List<sObject>> getAccountsContactsByPhone(String searchString, String searchField) {
        return search.query(
            'FIND :searchString ' +
            'IN ' + searchField + ' ' + 
            'RETURNING Account(Id, Name, Phone, BillingAddress,  RecordType.Name), ' + 
                	  'Contact(Id, Name, Account.Name, Phone WHERE IsPersonAccount = false)');
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getBusinessRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'Business_Account' AND sObjectType = 'Account' LIMIT 1].Id;
    }    
}