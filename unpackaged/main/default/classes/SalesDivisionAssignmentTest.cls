@isTest(isparallel=true)
public with sharing class SalesDivisionAssignmentTest {
  @isTest
  static void testAssignmentForAccount() {
    Account account = AccountTestFactory.createCustomer();
    String expected = [
      SELECT Sales_Division__c
      FROM Sales_Division__mdt
      WHERE CountryCode__c = :account.BillingCountryCode
      LIMIT 1
    ]
    .Sales_Division__c;

    account = [
      SELECT Sales_Division__c
      FROM Account
      WHERE Id = :account.Id
    ];
    System.assertEquals(
      expected,
      account.Sales_Division__c,
      'Account Sales Division not correctly assigned.'
    );

    Sales_Division__mdt newSalesDivisionMdt = [
      SELECT CountryCode__c, Sales_Division__c
      FROM Sales_Division__mdt
      WHERE Sales_Division__c != :account.Sales_Division__c
      LIMIT 1
    ];
    account.BillingCountryCode = newSalesDivisionMdt.CountryCode__c;
    update account;

    account = [
      SELECT Sales_Division__c
      FROM Account
      WHERE Id = :account.Id
    ];
    System.assertEquals(
      newSalesDivisionMdt.Sales_Division__c,
      account.Sales_Division__c,
      'Account Sales Division not correctly assigned.'
    );
  }

  @isTest
  static void testAssignmentForContact() {
    Contact contact = ContactTestFactory.getContact();
    contact.MailingCountryCode = 'US';
    insert contact;

    String expected = [
      SELECT Sales_Division__c
      FROM Sales_Division__mdt
      WHERE CountryCode__c = :contact.MailingCountryCode
      LIMIT 1
    ]
    .Sales_Division__c;

    contact = [
      SELECT Sales_Division_Contact__c
      FROM Contact
      WHERE Id = :contact.Id
    ];
    System.assertEquals(
      expected,
      contact.Sales_Division_Contact__c,
      'Account Sales Division not correctly assigned.'
    );

    Sales_Division__mdt newSalesDivisionMdt = [
      SELECT CountryCode__c, Sales_Division__c
      FROM Sales_Division__mdt
      WHERE Sales_Division__c != :contact.Sales_Division_Contact__c
      LIMIT 1
    ];
    contact.MailingCountryCode = newSalesDivisionMdt.CountryCode__c;
    update contact;

    contact = [
      SELECT Sales_Division_Contact__c
      FROM Contact
      WHERE Id = :contact.Id
    ];
    System.assertEquals(
      newSalesDivisionMdt.Sales_Division__c,
      contact.Sales_Division_Contact__c,
      'Contact Sales Division not correctly assigned.'
    );
  }

  @isTest
  static void testAssignmentForLead() {
    Lead lead = LeadTestFactory.getLead();
    lead.CountryCode = 'US';
    insert lead;
    String expected = [
      SELECT Sales_Division__c
      FROM Sales_Division__mdt
      WHERE CountryCode__c = :lead.CountryCode
      LIMIT 1
    ]
    .Sales_Division__c;

    lead = [SELECT Sales_Division_Contact__c FROM Lead WHERE Id = :lead.Id];
    System.assertEquals(
      expected,
      lead.Sales_Division_Contact__c,
      'Lead Sales Division not correctly assigned.'
    );

    Sales_Division__mdt newSalesDivisionMdt = [
      SELECT CountryCode__c, Sales_Division__c
      FROM Sales_Division__mdt
      WHERE Sales_Division__c != :lead.Sales_Division_Contact__c
      LIMIT 1
    ];
    lead.CountryCode = newSalesDivisionMdt.CountryCode__c;
    update lead;

    lead = [SELECT Sales_Division_Contact__c FROM Lead WHERE Id = :lead.Id];
    System.assertEquals(
      newSalesDivisionMdt.Sales_Division__c,
      lead.Sales_Division_Contact__c,
      'Lead Sales Division not correctly assigned.'
    );
  }
}