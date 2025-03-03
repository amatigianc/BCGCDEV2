@IsTest
public with sharing class SubscriptionAmendedRenewalHandlerTest {
  @TestSetup
  static void setupData() {
    Product2 customProd = new Product2(
      Name = 'Custom Amend Product',
      ProductCode = 'CUSTOM-PRODUCT',
      Custom_Amend__c = true
    );

    Product2 regularProd = new Product2(
      Name = 'Regular Amend Product',
      ProductCode = 'STANDARD-PRODUCT',
      Custom_Amend__c = false
    );

    insert new List<Product2>{ customProd, regularProd };

    Id standardPricebookId = Test.getStandardPricebookId();

    //need references to these for later
    PricebookEntry customPbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = customProd.Id,
      UnitPrice = 100,
      CurrencyIsoCode = 'USD',
      IsActive = true
    );

    PricebookEntry regularPbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = regularProd.Id,
      UnitPrice = 100,
      CurrencyIsoCode = 'USD',
      IsActive = true
    );

    insert new List<PricebookEntry>{ customPbe, regularPbe };

    Account standardAccount = AccountTestFactory.getCustomer();
    standardAccount.Name = 'AmendedStandardSubscriptionTester';
    insert standardAccount;

    Account customAccount = AccountTestFactory.getCustomer();
    customAccount.Name = 'CustomSubscriptionTester';
    insert customAccount;

    SBQQ__Subscription__c originalSubscription = new SBQQ__Subscription__c(
      SBQQ__Product__c = regularProd.Id,
      SBQQ__Quantity__c = 1,
      SBQQ__ProrateMultiplier__c = 1.00,
      SBQQ__ListPrice__c = 100,
      SBQQ__SpecialPrice__c = 100,
      SBQQ__CustomerPrice__c = 80,
      SBQQ__RegularPrice__c = 100,
      SBQQ__NetPrice__c = 80,
      SBQQ__RenewalPrice__c = 80,
      SBQQ__Account__c = standardAccount.Id
    );

    SBQQ__Subscription__c originalCustomSubscription = new SBQQ__Subscription__c(
      SBQQ__Product__c = customProd.Id,
      Number_of_Plays__c = 100,
      SBQQ__Quantity__c = 1,
      SBQQ__ProrateMultiplier__c = 1.00,
      SBQQ__ListPrice__c = 100,
      SBQQ__SpecialPrice__c = 100,
      SBQQ__CustomerPrice__c = 80,
      SBQQ__RegularPrice__c = 100,
      SBQQ__NetPrice__c = 80,
      SBQQ__RenewalPrice__c = 80,
      SBQQ__Account__c = customAccount.Id
    );

    insert new List<SBQQ__Subscription__c>{
      originalSubscription,
      originalCustomSubscription
    };

    Id renewalRecordTypeId = RecordTypeUtility.getId(
      Opportunity.getSObjectType(),
      'Renewal'
    );

    Opportunity renewalOpp = OpportunityTestFactory.getStage1Opp(
      standardAccount.Id,
      renewalRecordTypeId
    );
    renewalOpp.Pricebook2Id = standardPricebookId;

    Opportunity renewalCustomOpp = OpportunityTestFactory.getStage1Opp(
      customAccount.Id,
      renewalRecordTypeId
    );
    renewalCustomOpp.Pricebook2Id = standardPricebookId;
    insert new List<Opportunity>{ renewalOpp, renewalCustomOpp };

    SBQQ__Quote__c renewalQuote = QuoteTestFactory.getPrimaryQuote(
      renewalOpp.Id
    );
    renewalQuote.SBQQ__Account__c = standardAccount.Id;
    renewalQuote.SBQQ__PricebookId__c = standardPricebookId;
    renewalQuote.SBQQ__BillingFrequency__c = 'Annual';
    renewalQuote.SBQQ__PaymentTerms__c = 'Net 30';
    renewalQuote.SBQQ__RenewalTerm__c = 12;

    SBQQ__Quote__c renewalCustomQuote = QuoteTestFactory.getPrimaryQuote(
      renewalCustomOpp.Id
    );
    renewalCustomQuote.SBQQ__Account__c = customAccount.Id;
    renewalCustomQuote.SBQQ__PricebookId__c = standardPricebookId;
    renewalCustomQuote.SBQQ__BillingFrequency__c = 'Annual';
    renewalCustomQuote.SBQQ__PaymentTerms__c = 'Net 30';
    renewalCustomQuote.SBQQ__RenewalTerm__c = 12;

    insert new List<SBQQ__Quote__c>{ renewalQuote, renewalCustomQuote };

    SBQQ__QuoteLine__c renewalQuoteLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = renewalQuote.Id,
      SBQQ__Product__c = regularProd.Id,
      SBQQ__PricebookEntryId__c = regularPbe.Id,
      SBQQ__Quantity__c = 1,
      SBQQ__ListPrice__c = 100,
      SBQQ__Number__c = 1,
      SBQQ__Renewal__c = true,
      SBQQ__RenewedSubscription__c = originalSubscription.Id
    );

    SBQQ__QuoteLine__c renewalCustomQuoteLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = renewalCustomQuote.Id,
      SBQQ__Product__c = customProd.Id,
      SBQQ__PricebookEntryId__c = customPbe.Id,
      Number_of_Plays__c = 200,
      SBQQ__Quantity__c = 1,
      SBQQ__ListPrice__c = 100,
      SBQQ__Number__c = 1,
      SBQQ__Renewal__c = true,
      SBQQ__RenewedSubscription__c = originalCustomSubscription.Id
    );

    insert new List<SBQQ__QuoteLine__c>{
      renewalQuoteLine,
      renewalCustomQuoteLine
    };
  }

  @IsTest
  public static void testAmendedStandardRenewal() {
    SBQQ__Quote__c renewalQuote = [
      SELECT
        Id,
        SBQQ__Account__c,
        (
          SELECT
            Id,
            SBQQ__Quantity__c,
            SBQQ__ListPrice__c,
            SBQQ__RenewedSubscription__c,
            SBQQ__Product__c
          FROM SBQQ__LineItems__r
        )
      FROM SBQQ__Quote__c
      WHERE
        SBQQ__Account__r.Name = 'AmendedStandardSubscriptionTester'
        AND SBQQ__Opportunity2__r.RecordType.DeveloperName = 'Renewal'
      LIMIT 1
    ];

    Id originalSubscriptionId;
    Id originalProductId;
    Double originalQuantity;

    for (SBQQ__QuoteLine__c quoteLine : renewalQuote.SBQQ__LineItems__r) {
      originalSubscriptionId = quoteLine.SBQQ__RenewedSubscription__c;
      originalProductId = quoteLine.SBQQ__Product__c;
      originalQuantity = quoteLine.SBQQ__Quantity__c;
    }

    SBQQ__Subscription__c amendedSubscription = new SBQQ__Subscription__c(
      SBQQ__Product__c = originalProductId,
      SBQQ__ProrateMultiplier__c = 0.75,
      SBQQ__Quantity__c = 2.0,
      SBQQ__ListPrice__c = 200,
      SBQQ__SpecialPrice__c = 200,
      SBQQ__CustomerPrice__c = 160,
      SBQQ__RegularPrice__c = 200,
      SBQQ__NetPrice__c = 160,
      SBQQ__RenewalPrice__c = 160,
      SBQQ__Account__c = renewalQuote.SBQQ__Account__c,
      SBQQ__RevisedSubscription__c = originalSubscriptionId
    );

    Test.startTest();

    insert amendedSubscription;

    Test.stopTest();

    renewalQuote = [
      SELECT
        Id,
        SBQQ__Account__c,
        (
          SELECT Id, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__Product__c
          FROM SBQQ__LineItems__r
        )
      FROM SBQQ__Quote__c
      WHERE
        SBQQ__Account__r.Name = 'AmendedStandardSubscriptionTester'
        AND SBQQ__Opportunity2__r.RecordType.DeveloperName = 'Renewal'
      LIMIT 1
    ];

    for (SBQQ__QuoteLine__c quoteLine : renewalQuote.SBQQ__LineItems__r) {
      if (quoteLine.SBQQ__Product__c == originalProductId) {
        System.assertEquals(
          originalQuantity + 2.0,
          quoteLine.SBQQ__Quantity__c,
          'Quantity doesn\'t match excpected'
        );
      }
    }
  }

  @IsTest
  public static void testAmendedCustomRenewal() {
    SBQQ__Quote__c renewalQuote = [
      SELECT
        Id,
        SBQQ__Account__c,
        (
          SELECT
            Id,
            Number_of_Plays__c,
            SBQQ__RenewedSubscription__c,
            SBQQ__Product__c
          FROM SBQQ__LineItems__r
        )
      FROM SBQQ__Quote__c
      WHERE
        SBQQ__Account__r.Name = 'CustomSubscriptionTester'
        AND SBQQ__Opportunity2__r.RecordType.DeveloperName = 'Renewal'
      LIMIT 1
    ];

    Id originalSubscriptionId;
    Id originalProductId;
    Double originalNumberOfPlays;

    for (SBQQ__QuoteLine__c quoteLine : renewalQuote.SBQQ__LineItems__r) {
      originalSubscriptionId = quoteLine.SBQQ__RenewedSubscription__c;
      originalProductId = quoteLine.SBQQ__Product__c;
      originalNumberOfPlays = quoteLine.Number_of_Plays__c;
    }

    SBQQ__Subscription__c amendedSubscription = new SBQQ__Subscription__c(
      SBQQ__Product__c = originalProductId,
      Number_of_Plays__c = 500,
      SBQQ__ProrateMultiplier__c = 0.75,
      SBQQ__Quantity__c = 1.0,
      SBQQ__ListPrice__c = 200,
      SBQQ__SpecialPrice__c = 200,
      SBQQ__CustomerPrice__c = 160,
      SBQQ__RegularPrice__c = 200,
      SBQQ__NetPrice__c = 160,
      SBQQ__RenewalPrice__c = 160,
      SBQQ__Account__c = renewalQuote.SBQQ__Account__c,
      SBQQ__RevisedSubscription__c = originalSubscriptionId
    );

    Test.startTest();

    insert amendedSubscription;

    Test.stopTest();

    renewalQuote = [
      SELECT
        Id,
        SBQQ__Account__c,
        (
          SELECT Id, Number_of_Plays__c, SBQQ__ListPrice__c, SBQQ__Product__c
          FROM SBQQ__LineItems__r
        )
      FROM SBQQ__Quote__c
      WHERE
        SBQQ__Account__r.Name = 'CustomSubscriptionTester'
        AND SBQQ__Opportunity2__r.RecordType.DeveloperName = 'Renewal'
      LIMIT 1
    ];

    for (SBQQ__QuoteLine__c quoteLine : renewalQuote.SBQQ__LineItems__r) {
      if (quoteLine.SBQQ__Product__c == originalProductId) {
        System.assertEquals(
          500,
          quoteLine.Number_of_Plays__c,
          'Quantity doesn\'t match excpected'
        );
      }
    }

    //query original renewal quote line
    //insert amended subscription
    //query renewal quote line
    //verify changes
  }
}