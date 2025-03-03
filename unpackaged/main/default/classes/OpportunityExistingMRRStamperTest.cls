@isTest
public with sharing class OpportunityExistingMRRStamperTest {
  @TestSetup
  static void makeData() {
    AccountTestFactory.createCustomer();
  }
  @isTest
  static void testSetExistingMrr() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];
    account.CurrencyIsoCode = 'GBP';
    update account;
    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    opp.CurrencyIsoCode = 'GBP';
    opp.Legacy_USD_Existing_MRR__c = 100.00;
    insert opp;

    Test.startTest();

    opp = [
      SELECT
        Id,
        CloseDate,
        CurrencyIsoCode,
        Legacy_USD_Existing_MRR__c,
        Existing_MRR__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    DatedConversionRate rate = [
      SELECT ConversionRate
      FROM DatedConversionRate
      WHERE
        IsoCode = :opp.CurrencyIsoCode
        AND StartDate <= :opp.CloseDate
        AND NextStartDate > :opp.CloseDate
      LIMIT 1
    ];

    Double expected = opp.Legacy_USD_Existing_MRR__c * rate.ConversionRate;

    System.assertEquals(
      expected,
      opp.Existing_MRR__c,
      'Existing MRR not calculated correctly.'
    );

    rate = [
      SELECT ConversionRate, IsoCode
      FROM DatedConversionRate
      WHERE
        IsoCode != :opp.CurrencyIsoCode
        AND StartDate <= :opp.CloseDate
        AND NextStartDate > :opp.CloseDate
      LIMIT 1
    ];

    opp.CurrencyIsoCode = rate.IsoCode;
    update opp;

    expected = opp.Legacy_USD_Existing_MRR__c * rate.ConversionRate;

    opp = [
      SELECT
        Id,
        CloseDate,
        CurrencyIsoCode,
        Legacy_USD_Existing_MRR__c,
        Existing_MRR__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    System.assertEquals(
      expected,
      opp.Existing_MRR__c,
      'Existing MRR not calculated correctly.'
    );
  }

  @isTest
  static void testSetFutureExistingMrr() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];
    account.CurrencyIsoCode = 'GBP';
    update account;
    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    opp.CurrencyIsoCode = 'GBP';
    opp.Legacy_USD_Existing_MRR__c = 100.00;
    opp.CloseDate = Date.today().addYears(99);
    insert opp;

    Test.startTest();

    opp = [
      SELECT
        Id,
        CloseDate,
        CurrencyIsoCode,
        Legacy_USD_Existing_MRR__c,
        Existing_MRR__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    DatedConversionRate rate = [
      SELECT ConversionRate, StartDate
      FROM DatedConversionRate
      WHERE IsoCode = :opp.CurrencyIsoCode
      ORDER BY StartDate DESC
      LIMIT 1
    ];

    Double expected = opp.Legacy_USD_Existing_MRR__c * rate.ConversionRate;

    System.assertEquals(
      expected,
      opp.Existing_MRR__c,
      'Existing MRR not calculated correctly.'
    );
  }

  @isTest
  static void testSetUsdExistingMrr() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];
    account.CurrencyIsoCode = 'USD';
    update account;
    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    opp.CurrencyIsoCode = 'USD';
    opp.Legacy_USD_Existing_MRR__c = 100.00;
    insert opp;

    Test.startTest();

    opp = [
      SELECT
        Id,
        CloseDate,
        CurrencyIsoCode,
        Legacy_USD_Existing_MRR__c,
        Existing_MRR__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    Double expected = opp.Legacy_USD_Existing_MRR__c;

    System.assertEquals(
      expected,
      opp.Existing_MRR__c,
      'Existing MRR not calculated correctly.'
    );
  }
}