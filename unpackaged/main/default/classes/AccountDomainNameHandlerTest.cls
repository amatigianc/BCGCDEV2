@isTest(isparallel=true)
public with sharing class AccountDomainNameHandlerTest {
  @TestSetup
  private static void makeData() {
    insert new Brightcove_Account__c(
      Brightcove_Account_Id__c = '12345',
      Email_Address__c = 'bcAccount@example.com',
      Account_Profile__c = 'Trial'
    );
  }

  @isTest
  private static void testOnInsert() {
    List<Brightcove_Account__c> bcAccounts = [
      SELECT Id, Account__c, Email_Domain__c
      FROM Brightcove_Account__c
      WHERE Email_Domain__c = 'example.com' AND Account__c = NULL
      LIMIT 1
    ];
    System.assert(
      !bcAccounts.isEmpty(),
      'No qualifying Brightcove Accounts were initialized.'
    );

    Account account = AccountTestFactory.createCustomer();

    account.Email_Domain_Name__c = 'example.com';

    Test.startTest();
    update account;
    Test.stopTest();

    bcAccounts = [
      SELECT Id, Account__c
      FROM Brightcove_Account__c
      WHERE Id IN :bcAccounts
    ];
    for (Brightcove_Account__C bcAccount : bcAccounts) {
      System.assertEquals(
        account.Id,
        bcAccount.Account__c,
        'Salesforce Account was not correctly related to the Brightcove Account.'
      );
    }
  }

  @isTest
  private static void testOnUpdate() {
    List<Brightcove_Account__c> bcAccounts = [
      SELECT Id, Account__c, Email_Domain__c
      FROM Brightcove_Account__c
      WHERE Email_Domain__c = 'example.com' AND Account__c = NULL
      LIMIT 1
    ];
    System.assert(
      !bcAccounts.isEmpty(),
      'No qualifying Brightcove Accounts were initialized.'
    );

    Account account = AccountTestFactory.createCustomer();

    account.Email_Domain_Name__c = 'example.com';

    Test.startTest();
    update account;
    Test.stopTest();

    bcAccounts = [
      SELECT Id, Account__c
      FROM Brightcove_Account__c
      WHERE Id IN :bcAccounts
    ];
    for (Brightcove_Account__C bcAccount : bcAccounts) {
      System.assertEquals(
        account.Id,
        bcAccount.Account__c,
        'Salesforce Account was not correctly related to the Brightcove Account.'
      );
    }
  }
}