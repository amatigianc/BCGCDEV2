@isTest
public with sharing class SubscriptionSupportPackageUpdateTest {
  @TestSetup
  static void createDataSet() {
    List<String> supportNames = new List<String>{
      'Silver Support',
      'Gold Support',
      'Platinum Support',
      'Platinum Plus Support'
    };

    List<String> liveEventSupportNames = new List<String>{
      'Live Streaming Special Event Support',
      'Live Event Support Hours'
    };

    List<Account> accounts = AccountTestFactory.getCustomers(
      supportNames.size()
    );
    for (Account account : accounts) {
      account.Total_Live_Event_Support_Hours_Sold__c = 0;
      account.Support_Package__c = '';
      account.Account_Stage__c = 'Customer';
      account.Sales_Division__c = 'EMEA';
    }
    insert accounts;

    List<Contract> contractlist = new List<Contract>();

    for (Account account : accounts) {
      Contract contract = new Contract();
      contract.AccountId = account.Id;
      contract.StartDate = System.today();
      contract.ContractTerm = 12;
      contract.Name = 'Test contract';
      contract.SBQQ__RenewalForecast__c = false;
      contractlist.add(contract);
    }
    insert contractlist;

    List<Product2> prodList = new List<Product2>();
    for (String supportProduct : supportNames) {
      prodList.add(new Product2(Name = supportProduct, Family = 'Support'));
    }

    for (String liveProduct : liveEventSupportNames) {
      prodList.add(new Product2(Name = liveProduct, Family = 'Live'));
    }

    insert prodList;
    SBQQ.TriggerControl.disable();
  }

  @isTest
  static void createSubscriptions() {
    List<Account> accounts = [
      SELECT
        Id,
        Sales_Division__c,
        (SELECT Id FROM Contracts WHERE Name = 'Test contract' LIMIT 1)
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    List<Product2> products = [
      SELECT Id, Name, Family
      FROM Product2
      WHERE Family IN ('Support', 'Live')
      ORDER BY FAMILY DESC
    ];

    Test.startTest();

    List<SBQQ__Subscription__c> subscriptions = new List<SBQQ__Subscription__c>();
    for (Integer i = 0; i < accounts.size(); i++) {
      subscriptions.add(
        new SBQQ__Subscription__c(
          SBQQ__Account__c = accounts[i].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__Product__c = products[i].Id,
          SBQQ__Contract__c = accounts[i].Contracts[0].Id
        )
      );
    }

    subscriptions.add(
      new SBQQ__Subscription__c(
        SBQQ__Account__c = accounts[3].Id,
        SBQQ__Quantity__c = 10,
        SBQQ__Product__c = products[4].Id,
        SBQQ__Contract__c = accounts[3].Contracts[0].Id
      )
    );

    SBQQ.TriggerControl.disable();
    insert subscriptions;

    Test.stopTest();

    accounts = [
      SELECT
        Id,
        Support_package__c,
        Total_Live_Event_Support_hours_sold__c,
        (
          SELECT Id, SBQQ__Quantity__c
          FROM SBQQ__Subscriptions__r
          WHERE
            SBQQ__ProductName__c IN (
              'Live Streaming Special Event Support',
              'Live Event Support Hours'
            )
        )
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    for (Account account : accounts) {
      System.assert(
        account.Support_Package__c != '',
        'Account Support Package not initialised correctly'
      );

      String supportPackage = account.Support_Package__c.split(' ')[0];

      switch on supportPackage {
        when 'Gold', 'Platinum', 'Platinum+' {
          System.assert(
            account.Total_Live_Event_Support_Hours_Sold__c > 0,
            'Default Live hours NOT assigned correctly for Gold, Platinum, Platinum+'
          );
        }
        when else {
          Decimal expected = 0;
          if (!account.SBQQ__Subscriptions__r.isEmpty()) {
            for (
              SBQQ__Subscription__c subscription : account.SBQQ__Subscriptions__r
            ) {
              expected += subscription.SBQQ__Quantity__c;
            }
          }
          System.assertEquals(
            expected,
            account.Total_Live_Event_Support_Hours_Sold__c,
            'Default Live hours NOT assigned correctly for ' + supportPackage
          );
        }
      }
    }
  }
}