@isTest(isparallel=true)
public with sharing class AccountCreatedDateMergeQueueableTest {
  @TestSetup
  static void setup() {
    List<Account> accounts = AccountTestFactory.getCustomers(2);

    accounts[0].Name = 'AccountCreatedDateMergeQueueableTest 1';
    accounts[0].GUID__c = '123456';
    accounts[1].Name = 'AccountCreatedDateMergeQueueableTest 2';
    accounts[1].GUID__c = '123456';

    insert accounts;
  }

  @isTest
  static void testMerge() {
    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE GUID__c = '123456'
      ORDER BY Id
    ];
    System.assertEquals(2, accounts.size());

    Test.startTest();
    System.enqueueJob(new AccountCreatedDateMergeQueueable());
    Test.stopTest();

    accounts = [
      SELECT Id, Name
      FROM Account
      WHERE GUID__c = '123456'
      ORDER BY Id
    ];
    System.assertEquals(1, accounts.size());
    System.assertEquals(
      'AccountCreatedDateMergeQueueableTest 2',
      accounts[0].Name
    );
  }
}