@isTest(isparallel=true)
public with sharing class AccountMergerQueueableTest {
  @TestSetup
  private static void makeData() {
    List<Account> accounts = AccountTestFactory.getCustomers(2);
    for (Account account : accounts) {
      account.D_U_N_S_Number__c = '123456';
      account.Account_Stage__c = 'Prospect';
      account.Pending_Hierarchy_Review__c = false;
    }
    accounts[0].Account_Stage__c = 'Customer';
    insert accounts;
  }

  @isTest
  private static void testMerge() {
    Account expectedAccount = [
      SELECT Id, D_U_N_S_Number__c
      FROM Account
      WHERE Account_Stage__c = 'Customer'
      LIMIT 1
    ];

    Test.startTest();
    System.enqueueJob(new AccountMergerQueueable());
    Test.stopTest();

    List<Account> accounts = [
      SELECT Id, D_U_N_S_Number__c, Account_Stage__c
      FROM Account
      WHERE D_U_N_S_Number__c = :expectedAccount.D_U_N_S_Number__c
    ];
    System.assertEquals(
      1,
      accounts.size(),
      'Accounts were not correctly merged.'
    );
    System.assertEquals(
      'Customer',
      accounts[0].Account_Stage__c,
      'The Customer record was not designated as the Primary.'
    );

    System.enqueueJob(new AccountMergerQueueable());

    accounts = [
      SELECT Id, D_U_N_S_Number__c, Account_Stage__c
      FROM Account
      WHERE D_U_N_S_Number__c = :expectedAccount.D_U_N_S_Number__c
    ];
    System.assertEquals(
      1,
      accounts.size(),
      'Accounts were not correctly merged.'
    );
    System.assertEquals(
      'Customer',
      accounts[0].Account_Stage__c,
      'The Customer record was not designated as the Primary.'
    );
  }

  @isTest
  private static void testMultipleCustomers() {
    Account secondCustomer = [
      SELECT Id, Account_Stage__c, D_U_N_S_Number__c
      FROM Account
      WHERE Account_Stage__c = 'Prospect'
      LIMIT 1
    ];
    secondCustomer.Account_Stage__c = 'Customer';
    update secondCustomer;

    Test.startTest();
    System.enqueueJob(new AccountMergerQueueable());
    Test.stopTest();

    List<Account> accounts = [
      SELECT Id, Pending_Merge_Review__c
      FROM Account
      WHERE D_U_N_S_Number__c = :secondCustomer.D_U_N_S_Number__c
    ];

    for (Account account : accounts) {
      System.assertEquals(
        true,
        account.Pending_Merge_Review__c,
        'Duplicate Accounts with multiple active customers were not flagged for review.'
      );
    }
  }
}