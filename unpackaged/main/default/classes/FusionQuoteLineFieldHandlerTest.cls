@isTest
public with sharing class FusionQuoteLineFieldHandlerTest {
  @TestSetup
  static void makeData() {
    Account account = AccountTestFactory.createCustomer();

    OpportunityTestFactory.getStage2Opp(account.Id);

    insert new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'Bundle',
      SBQQ__SubscriptionType__c = 'Renewable',
      Overage_Rate_Precision__c = 4
    );
  }

  @isTest
  static void testSetFusionFields() {
    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__Opportunity2__r.Account.Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];

    Product2 product2 = [
      SELECT Id, Overage_Rate_Precision__c
      FROM Product2
      WHERE Name = 'Support Package'
      LIMIT 1
    ];
    SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = product2.Id,
      SBQQ__ListPrice__c = 0,
      SBQQ__Quantity__c = 1,
      SBQQ__Bundle__c = true,
      Custom_Product_Name__c = 'Test Product',
      Custom_Product_Description__c = 'lol',
      Description_Updated__c = 'lol',
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      Total_Overage_Quantity__c = 10,
      Overage_Rate__c = 20
    );
    insert quoteLine;

    quoteLine = [
      SELECT
        Id,
        Total_Overage_Quantity__c,
        Lower_Limit__c,
        Overage_Rate__c,
        Rate__c
      FROM SBQQ__QuoteLine__c
      WHERE Id = :quoteLine.Id
    ];
    System.assertEquals(
      quoteLine.Total_Overage_Quantity__c,
      quoteLine.Lower_Limit__c,
      'Lower Limit not populated.'
    );
    Integer expectedPrecision = Integer.valueOf(
      product2.Overage_Rate_Precision__c
    );
    System.assertEquals(
      String.valueOf(quoteLine.Overage_Rate__c.setScale(expectedPrecision)),
      quoteLine.Rate__c,
      'Rate not populated.'
    );
    quoteLine.Total_Overage_Quantity__c += 1;

    update quoteLine;

    quoteLine.Overage_Rate__c += 1;

    update quoteLine;

    quoteLine = [
      SELECT
        Id,
        Total_Overage_Quantity__c,
        Lower_Limit__c,
        Overage_Rate__c,
        Rate__c
      FROM SBQQ__QuoteLine__c
      WHERE Id = :quoteLine.Id
    ];
    System.assertEquals(
      quoteLine.Total_Overage_Quantity__c,
      quoteLine.Lower_Limit__c,
      'Lower Limit not populated.'
    );
    expectedPrecision = Integer.valueOf(product2.Overage_Rate_Precision__c);
    System.assertEquals(
      String.valueOf(quoteLine.Overage_Rate__c.setScale(expectedPrecision)),
      quoteLine.Rate__c,
      'Rate not populated.'
    );
  }
}