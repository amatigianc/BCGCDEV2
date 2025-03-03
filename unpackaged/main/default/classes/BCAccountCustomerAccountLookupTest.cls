@isTest(isparallel=true)
public with sharing class BCAccountCustomerAccountLookupTest {
  @TestSetup
  static void makeData() {
    Account account = AccountTestFactory.getCustomer();
    account.Name = 'BCAccountCustomerAccountLookupTest';
    account.Email_Domain_Name__c = 'BCAccountCustomerAccountLookupTest.com';
    insert account;
  }

  @isTest
  static void testLookup() {
    Account expectedAccount = [
      SELECT Id
      FROM Account
      WHERE Email_Domain_Name__C = 'BCAccountCustomerAccountLookupTest.com'
      LIMIT 1
    ];
    Brightcove_Account__c brightcoveAccount = new Brightcove_Account__c(
      Brightcove_Account_Id__c = '12345',
      Email_Address__c = 'mhigel@bcAccountCustomerAccountLookupTest.com'
    );
    insert brightcoveAccount;

    brightcoveAccount = [
      SELECT Id, Account__c, Account__r.Email_Domain_Name__c, Email_Domain__c
      FROM Brightcove_Account__c
      WHERE Id = :brightcoveAccount.Id
    ];

    System.assertEquals(
      expectedAccount.Id,
      brightcoveAccount.Account__c,
      'Brightcove Account not correctly related to Salesforce Account.'
    );
  }
}