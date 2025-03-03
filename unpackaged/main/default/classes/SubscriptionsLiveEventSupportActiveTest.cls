@isTest
public class SubscriptionsLiveEventSupportActiveTest {
  @TestSetup
  static void makeData() {
    Map<String, String> supportPackagesProdCode = new Map<String, String>{
      'Silver Support' => 'SP-SILVER',
      'Gold Support' => 'SP-GOLD',
      'Platinum Support' => 'SP-PLAT',
      'Platinum Plus Support' => '100-125',
      'Platinum Plus Support Upgrade' => 'SP-PLATPLUS-UPG'
    };

    List<Product2> productList = new List<Product2>();
    for (String productName : supportPackagesProdCode.keySet()) {
      Product2 supportProd = new Product2(
        Name = productName,
        ProductCode = supportPackagesProdCode.get(productName)
      );
      productList.add(supportProd);
    }

    productList.add(
      new Product2(
        Name = 'Live Streaming Special Event Support',
        ProductCode = 'SP-LIVE-SPCEVENT',
        IsActive = true
      )
    );
    productList.add(
      new Product2(
        Name = 'Live Event Support Hours',
        ProductCode = '8-48',
        IsActive = true
      )
    );
    insert productList;

    List<Product2> liveEventProducts = [
      SELECT Id, Name
      FROM Product2
      WHERE
        Name IN (
          'Live Streaming Special Event Support',
          'Live Event Support Hours'
        )
    ];
    List<Product2> supportProducts = [
      SELECT Id, Name
      FROM Product2
      WHERE Name IN :supportPackagesProdCode.keySet()
      ORDER BY Name DESC
    ];

    List<Account> accounts = new List<Account>();
    List<Contract> contracts = new List<Contract>();

    for (Product2 supportpackage : supportProducts) {
      Account accRecord = AccountTestFactory.getCustomer();
      accRecord.Account_Stage__c = 'Customer';

      accounts.add(accRecord);
    }

    insert accounts;

    SBQQ.TriggerControl.disable();

    for (Account account : accounts) {
      Contract testContract = new Contract(
        AccountId = account.Id,
        StartDate = Date.today(),
        ContractTerm = 12,
        Status = 'Draft',
        SBQQ__RenewalForecast__c = false
      );
      contracts.add(testContract);
    }
    insert contracts;

    List<SBQQ__Subscription__c> subscriptions = new List<SBQQ__Subscription__c>();

    Integer i = 0;
    for (Account account : accounts) {
      SBQQ__Subscription__c supportPackageSubscription = new SBQQ__Subscription__c(
        SBQQ__Product__c = supportProducts[i].Id,
        SBQQ__Quantity__c = 1,
        SBQQ__ProrateMultiplier__c = 1.00,
        SBQQ__ListPrice__c = 100,
        SBQQ__SpecialPrice__c = 100,
        SBQQ__CustomerPrice__c = 80,
        SBQQ__RegularPrice__c = 100,
        SBQQ__NetPrice__c = 80,
        SBQQ__RenewalPrice__c = 80,
        SBQQ__Account__c = account.Id,
        SBQQ__Contract__c = contracts[i].Id
      );
      subscriptions.add(supportPackageSubscription);
      i++;
    }

    SBQQ__Subscription__c subLiveEventSuppportHoursSilver = new SBQQ__Subscription__c(
      SBQQ__Product__c = liveEventProducts[1].Id,
      SBQQ__Quantity__c = 52,
      SBQQ__ProrateMultiplier__c = 1.00,
      SBQQ__ListPrice__c = 100,
      SBQQ__SpecialPrice__c = 100,
      SBQQ__CustomerPrice__c = 80,
      SBQQ__RegularPrice__c = 100,
      SBQQ__NetPrice__c = 80,
      SBQQ__RenewalPrice__c = 80,
      SBQQ__Account__c = accounts[0].Id,
      SBQQ__Contract__c = contracts[0].Id
    );

    subscriptions.add(subLiveEventSuppportHoursSilver);
    SBQQ__Subscription__c subLiveEventSuppportHoursGold = new SBQQ__Subscription__c(
      SBQQ__Product__c = liveEventProducts[1].Id,
      SBQQ__Quantity__c = 10,
      SBQQ__ProrateMultiplier__c = 1.00,
      SBQQ__ListPrice__c = 100,
      SBQQ__SpecialPrice__c = 100,
      SBQQ__CustomerPrice__c = 80,
      SBQQ__RegularPrice__c = 100,
      SBQQ__NetPrice__c = 80,
      SBQQ__RenewalPrice__c = 80,
      SBQQ__Account__c = accounts[1].Id,
      SBQQ__Contract__c = contracts[1].Id
    );

    subscriptions.add(subLiveEventSuppportHoursGold);
    SBQQ__Subscription__c subLiveEventSuppportHoursPlat = new SBQQ__Subscription__c(
      SBQQ__Product__c = liveEventProducts[0].Id,
      SBQQ__Quantity__c = 105,
      SBQQ__ProrateMultiplier__c = 1.00,
      SBQQ__ListPrice__c = 100,
      SBQQ__SpecialPrice__c = 100,
      SBQQ__CustomerPrice__c = 80,
      SBQQ__RegularPrice__c = 100,
      SBQQ__NetPrice__c = 80,
      SBQQ__RenewalPrice__c = 80,
      SBQQ__Account__c = accounts[2].Id,
      SBQQ__Contract__c = contracts[2].Id
    );

    subscriptions.add(subLiveEventSuppportHoursPlat);
    SBQQ__Subscription__c subLiveEventSuppportHoursPlatPlus = new SBQQ__Subscription__c(
      SBQQ__Product__c = liveEventProducts[0].Id,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__Quantity__c = 10,
      SBQQ__ProrateMultiplier__c = 1.00,
      SBQQ__ListPrice__c = 100,
      SBQQ__SpecialPrice__c = 100,
      SBQQ__CustomerPrice__c = 80,
      SBQQ__RegularPrice__c = 100,
      SBQQ__NetPrice__c = 80,
      SBQQ__RenewalPrice__c = 80,
      SBQQ__Account__c = accounts[3].Id,
      SBQQ__Contract__c = contracts[3].Id
    );

    subscriptions.add(subLiveEventSuppportHoursPlatPlus);

    insert subscriptions;

    for (Contract contract : contracts) {
      contract.Status = 'Activated';
    }

    Database.update(contracts, false);

    update subscriptions;
  }

  @isTest
  static void customerActiveSubscriptionTest() {
    List<String> liveEventProducts = new List<String>{
      'Live Streaming Special Event Support',
      'Live Event Support Hours'
    };

    List<String> supportPackagesProducts = new List<String>{
      'Silver Support',
      'Silver Support Package',
      'Gold Support',
      'Gold Support Package',
      'Platinum Support',
      'Platinum Support Package',
      'Platinum Plus Support',
      'Platinum Plus Support Package',
      'Platinum Plus Support Upgrade',
      'Platinum Plus Support Package Upgrade'
    };

    List<Account> accountList = [
      SELECT
        Id,
        Total_Live_Event_Support_hours_sold__c,
        Live_Event_Support_hours_Active__c,
        (
          SELECT
            Id,
            SBQQ__ProductName__c,
            SBQQ__Quantity__c,
            SBQQ__EndDate__c,
            SBQQ__SubscriptionEndDate__c
          FROM SBQQ__Subscriptions__r
          WHERE
            (SBQQ__Product__r.Name IN :liveEventProducts
            OR SBQQ__Product__r.Name IN :supportPackagesProducts)
            AND SBQQ__StartDate__c <= TODAY
            AND SBQQ__EndDate__c >= TODAY
            AND SBQQ__Quantity__c > 0
        )
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    Map<Id, SBQQ__Subscription__c> subscriptionsToUpdate = new Map<Id, SBQQ__Subscription__c>();
    for (Account accountRec : accountList) {
      for (
        SBQQ__Subscription__c subscription : accountRec.SBQQ__Subscriptions__r
      ) {
        if (
          subscription.SBQQ__ProductName__c ==
          'Live Streaming Special Event Support' ||
          subscription.SBQQ__ProductName__c == 'Live Event Support Hours'
        ) {
          subscription.SBQQ__SubscriptionEndDate__c = System.today()
            .addDays(-1);
          subscriptionsToUpdate.put(accountRec.Id, subscription);
        }
      }
    }

    update subscriptionsToUpdate.values();

    Test.startTest();
    launchApexJob();
    Test.stopTest();

    List<Account> accountListAfter = [
      SELECT
        Id,
        Total_Live_Event_Support_hours_sold__c,
        Live_Event_Support_hours_Active__c
      FROM Account
      WHERE
        Name LIKE 'AccountTestFactory%'
        AND Id IN :subscriptionsToUpdate.keySet()
    ];

    for (Account account : accountListAfter) {
      System.assertEquals(
        account.Live_Event_Support_hours_Active__c,
        account.Total_Live_Event_Support_hours_sold__c -
        subscriptionsToUpdate.get(account.Id).SBQQ__Quantity__c,
        'Live Event Support Hours Active Calculation is wrong'
      );
    }
  }

  static void launchApexJob() {
    String CRON_EXP = '0 0 0 3 9 ? 2042';

    String jobId = System.schedule(
      'SubscriptionsLiveEventSupportHoursActiveTest',
      CRON_EXP,
      new SubscriptionsLiveEventSupportHoursActive()
    );

    CronTrigger ct = [
      SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger
      WHERE Id = :jobId
    ];

    System.assertEquals(
      CRON_EXP,
      ct.CronExpression,
      'CRON and TimesTriggerd are not the same'
    );
  }
}