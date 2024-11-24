public without sharing class IncomingCallController {
    
    @AuraEnabled(cacheable=true)
    public static List<List<sObject>> getAccountsContacts(String searchString, String searchField) {
        return search.query(
            'FIND :searchString ' +
            'IN ' + String.escapeSingleQuotes(searchField) + ' ' + 
            'RETURNING Account(Id, Name, Phone, BillingCountry, BillingCity, BillingState, BillingStreet, BillingPostalCode, RecordType.Name), ' + 
                	  'Contact(Id, Name, Account.Name, Phone WHERE IsPersonAccount = false)');
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getBusinessRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'Business_Account' AND sObjectType = 'Account' LIMIT 1].Id;
    }    
}