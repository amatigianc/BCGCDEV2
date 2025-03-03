@isTest
public with sharing class QuoteBillingAddressHandlerTest {
  @TestSetup
  static void makeData() {
    AccountTestFactory.createCustomer();
  }

  @isTest
  static void testSetBillToAddress() {
    Account customer = [
      SELECT
        Id,
        Name,
        BillingCity,
        BillingState,
        BillingCountry,
        BillingStreet,
        BillingPostalCode
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    SBQQ__Quote__c quote = QuoteTestFactory.getBaseQuote();
    quote.SBQQ__Account__c = customer.Id;

    insert quote;

    quote = [
      SELECT
        Id,
        SBQQ__BillingCity__c,
        SBQQ__BillingStreet__c,
        SBQQ__BillingState__c,
        SBQQ__BillingCountry__C,
        SBQQ__BillingPostalCode__c
      FROM SBQQ__Quote__c
      WHERE Id = :quote.Id
    ];

    Map<SObjectField, SObjectField> billingAddressMap = new Map<SObjectField, SObjectField>{
      Account.BillingCity => SBQQ__Quote__c.SBQQ__BillingCity__c,
      Account.BillingCountry => SBQQ__Quote__c.SBQQ__BillingCountry__c,
      Account.BillingPostalCode => SBQQ__Quote__c.SBQQ__BillingPostalCode__c,
      Account.BillingState => SBQQ__Quote__c.SBQQ__BillingState__c,
      Account.BillingStreet => SBQQ__Quote__c.SBQQ__BillingStreet__c
    };

    for (SObjectField accountField : billingAddressMap.keySet()) {
      String expected = (String) customer.get(accountField);
      String actual = (String) quote.get(billingAddressMap.get(accountField));
      System.assertEquals(
        expected,
        actual,
        accountField.getDescribe().getName() + ' not set on Quote.'
      );
    }
  }
}