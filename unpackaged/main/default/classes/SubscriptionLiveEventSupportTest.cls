@isTest
public with sharing class SubscriptionLiveEventSupportTest {
  @TestSetup
  static void createData() {
    List<Account> accounts = AccountTestFactory.getCustomers(3);

    for (Account account : accounts) {
      account.Total_Live_Event_Support_hours_sold__c = 0;
      account.Live_Event_Support_hours_available__c = 0;
      account.Support_package__c = '';
      account.Account_Stage__c = 'Customer';
      account.Sales_Division__c = 'EMEA';
    }
    insert accounts;

    List<Contract> contractlist = new List<Contract>();

    for (Account accountRec : accounts) {
      Contract contractRec = new Contract();
      contractRec.AccountId = accountRec.Id;
      contractRec.StartDate = system.today();
      contractRec.ContractTerm = 12;

      contractlist.add(contractRec);
    }
    insert contractlist;

    Product2 supportProd = new Product2();
    supportProd.Name = 'Live Streaming Special Event Support';
    supportProd.Family = 'Support';

    insert supportProd;
  }
  @isTest
  static void createSubscriptions() {
    List<Account> accounts = [
      SELECT Id, Sales_Division__c
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    List<Contract> contracts = [
      SELECT Id, StartDate, EndDate, AccountId
      FROM Contract
      WHERE AccountId IN :accounts
    ];

    List<Product2> productList = [
      SELECT Id, Name
      FROM Product2
      WHERE Name = 'Live Streaming Special Event Support'
    ];

    List<SBQQ__Subscription__c> subscriptions = new List<SBQQ__Subscription__c>();

    Test.startTest();
    Integer i = 0;
    for (Account accountRec : accounts) {
      SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
      subscription.SBQQ__Account__c = accountRec.Id;
      subscription.SBQQ__Contract__c = contracts[i].Id;
      subscription.SBQQ__Quantity__c = 1;
      subscription.SBQQ__Product__c = productList[0].Id;
      i++;
      subscriptions.add(subscription);
    }
    SBQQ.TriggerControl.disable();
    insert subscriptions;
    Test.stopTest();

    List<Account> accountAfter = [
      SELECT Id, Sales_Division__c, Total_Live_Event_Support_hours_sold__c
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    for (Account acc : accountAfter) {
      system.assertEquals(
        1,
        acc.Total_Live_Event_Support_hours_sold__c,
        'Live Event hours not assigned correctly'
      );
    }
  }
}