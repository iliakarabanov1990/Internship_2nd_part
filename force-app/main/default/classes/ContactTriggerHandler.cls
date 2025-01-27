public with sharing class ContactTriggerHandler extends TriggerHandler{
   
    public override void afterUpdate() { updateAccountRollUp(Trigger.new, true); } 
    public override void afterInsert() { updateAccountRollUp(Trigger.new, false); createContactsOnReqres(Trigger.new); }
    public override void afterUndelete() { updateAccountRollUp(Trigger.new, false); }
    public override void afterDelete() { updateAccountRollUp(Trigger.old, false); }
    

    private void createContactsOnReqres(List<sObject> conts) {

        if(!Schema.SObjectType.Account.fields.name.isAccessible() || conts.size() == 0) { return; }

        List<String> names = new List<String>();

        for(sObject con : conts) { names.add((String)con.get('LastName')); }
        
        System.enqueueJob(new QueueableRequstService(names));
    }

	private void updateAccountRollUp(List<sObject> conts, Boolean checkAccountChange) {

        Map<Id, Account> accounts = new Map<Id, Account>();
        
        for(sObject contObj : conts) { 
            Contact cont = (Contact)contObj;
            Id accId = cont.AccountId;
            
            //don't update account, whene update contact and AccountId isn't changed or account == null
            Id oldAccountId = checkAccountChange ? ((Contact)Trigger.oldMap.get(cont.Id)).AccountId : null;
            if(accId == oldAccountId) { continue; }

            if(oldAccountId != null) { accounts.put(oldAccountId, new Account(Id = oldAccountId)); }
            if(accId != null) { accounts.put(accId, new Account(Id = accId)); }         
        }    

        for(AggregateResult row : [SELECT Count(Id) contCount, AccountId FROM Contact WHERE AccountId = :accounts.keySet() WITH USER_MODE GROUP BY AccountId ]) {
            accounts.get((Id)row.get('AccountId')).Contacts_Count__c = (Decimal)row.get('contCount');
        }

        try { Database.update(accounts.values(), true, AccessLevel.USER_MODE); } 
        catch (Exception e) { throw new ContactTriggerHandlerException(e); }     
    }

    public with sharing class ContactTriggerHandlerException extends Exception {}
}