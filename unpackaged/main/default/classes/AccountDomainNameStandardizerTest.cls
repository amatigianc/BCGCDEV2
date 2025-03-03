@isTest(isparallel=true)
public with sharing class AccountDomainNameStandardizerTest {
  @isTest
  static void testStandardization() {
    Account account = AccountTestFactory.getCustomer();

    account.Email_Domain_Name__c = 'AccountDomainNameStandardizerTest.com';

    insert account;

    account = [
      SELECT Id, Email_Domain_Name__c
      FROM Account
      WHERE Id = :account.Id
    ];
    System.assertEquals(
      'AccountDomainNameStandardizerTest.com'.toLowerCase(),
      account.Email_Domain_Name__c,
      'Email Domain Name was not set to all lower case.'
    );

    account.Email_Domain_Name__c = 'UPPERCASE.COM';
    update account;

    account = [
      SELECT Id, Email_Domain_Name__c
      FROM Account
      WHERE Id = :account.Id
    ];
    System.assertEquals(
      'UPPERCASE.COM'.toLowerCase(),
      account.Email_Domain_Name__c,
      'Email Domain Name was not set to all lower case.'
    );
  }
}