@isTest
private class TestOrderTrigger {

  @TestSetup
  static void setData() {
      
    Id standardPriceBookId = Test.getStandardPricebookId();
      
   	Account acct = new Account(Name='tAccount');
    insert acct;
    
    Contract ct = new Contract();
    ct.AccountId = acct.Id;
    ct.Status = 'Draft';
    ct.StartDate = Date.Today();
    ct.ContractTerm = 12;
    insert ct;
    
    ct.Status = 'Activated';
    update ct;
    
    List<Order> ords = new List<Order>();
    ords.add(new Order(Name = 'test1',
             AccountId = acct.Id,
             EffectiveDate = Date.Today(),
             ContractId = ct.Id,
             Status = 'Draft',
             Pricebook2Id=standardPriceBookId));
    ords.add(new Order(Name = 'test2',
             AccountId = acct.Id,
             EffectiveDate = Date.Today(),
             ContractId = ct.Id,
             Status = 'Draft',
             ShippingCountry = 'USA',
             Pricebook2Id=standardPriceBookId));
    insert ords; 
  }
    
    @isTest
    static void TestUndeleteOrder(){
        
        Integer countInit = [SELECT Count() FROM Order];
        List<Order> ords = [SELECT Id FROM Order];
        
        Test.startTest();
        	delete ords;
        	undelete ords;
        	Integer countAfterUndelete = [SELECT Count() FROM Order];
       	Test.StopTest();
        
        Assert.areEqual(2, countInit, 'wrong orders count'); 
        Assert.areEqual(2, countAfterUndelete, 'wrong orders count after undelete');
        Assert.areEqual(1, [SELECT OrderCount__c FROM Account LIMIT 1].OrderCount__c, 'wrong orders count in account after undelete');
    }    
    
    @isTest
    static void TestDeleteOrder(){
        
        Integer countInit = [SELECT Count() FROM Order];
        List<Order> ords = [SELECT Id FROM Order];
        
        Test.startTest();
        	delete ords;
        	Integer countAfterDelete = [SELECT Count() FROM Order];
       	Test.StopTest();
        
        Assert.areEqual(2, countInit, 'wrong orders count'); 
        Assert.areEqual(0, countAfterDelete, 'wrong orders count after delete');
        Assert.areEqual(0, [SELECT OrderCount__c FROM Account LIMIT 1].OrderCount__c, 'wrong orders count in account after delete');
    }
    
}