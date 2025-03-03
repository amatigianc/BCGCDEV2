@isTest(isparallel=true)
public with sharing class AccountStamperTest {
  @TestSetup
  static void makeData() {
    List<Account> accounts = new List<Account>();
    List<String> stages = new List<String>{
      'Awareness',
      'Consideration',
      'Decision',
      'Purchase',
      ''
    };
    for (String stage : stages) {
      accounts.add(AccountTestFactory.getCustomer());
      for (Account account : accounts) {
        account.X6sense_Account_Buying_Stage__c = stage;
      }
    }
    insert accounts;
  }

  @isTest
  private static void testStamp() {
    List<String> stages = new List<String>{
      'Awareness',
      'Consideration',
      'Decision',
      'Purchase',
      ''
    };
    List<Account> accounts = [
      SELECT Id, X6QA__c, Name
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    accounts[4].X6QA__c = true;
    update accounts;

    accounts = [
      SELECT
        Id,
        X6QA__c,
        X6sense_Account_6QA_Start_Date__c,
        X6sense_Account_6QA_End_Date__c,
        X6sense_Account_Buying_Stage__c,
        X6sense_Stage_Awareness__c,
        X6sense_Stage_Consideration__c,
        X6sense_Stage_Decision__c,
        X6sense_Stage_Purchase__c
      FROM Account
      WHERE Id IN :accounts
    ];

    for (Account account : accounts) {
      switch on account.X6sense_Account_Buying_Stage__c {
        when 'Awareness' {
          System.assertEquals(
            Date.today(),
            account.X6sense_Stage_Awareness__c,
            'Date of Stage Awareness not correctly set.'
          );
        }
        when 'Consideration' {
          System.assertEquals(
            Date.today(),
            account.X6sense_Stage_Consideration__c,
            'Date of Stage Consideration not correctly set.'
          );
        }
        when 'Decision' {
          System.assertEquals(
            Date.today(),
            account.X6sense_Stage_Decision__c,
            'Date of Stage Decision not correctly set.'
          );
        }
        when 'Purchase' {
          System.assertEquals(
            Date.today(),
            account.X6sense_Stage_Purchase__c,
            'Date of Stage Purchase not correctly set.'
          );
        }
        when else {
          System.assertEquals(
            null,
            account.X6sense_Stage_Awareness__c,
            'Date of Stage Awareness not correctly set.'
          );
          System.assertEquals(
            null,
            account.X6sense_Stage_Consideration__c,
            'Date of Stage Consideration not correctly set.'
          );
          System.assertEquals(
            null,
            account.X6sense_Stage_Decision__c,
            'Date of Stage Decision not correctly set.'
          );
          System.assertEquals(
            null,
            account.X6sense_Stage_Purchase__c,
            'Date of Stage Purchase not correctly set.'
          );
        }
      }

      if (account.X6QA__c) {
        System.assertEquals(
          Date.today(),
          account.X6sense_Account_6QA_Start_Date__c,
          '6QA Start Date not set for 6QA Account.'
        );
      }
    }

    stages = new List<String>{
      '',
      'Awareness',
      'Consideration',
      'Decision',
      'Purchase'
    };
    for (Integer i = 0; i < stages.size(); i++) {
      accounts[i].X6QA__c = accounts[i].X6QA__c ? false : true;
      accounts[i].X6sense_Account_Buying_Stage__c = stages[i];
    }

    update accounts;

    accounts = [
      SELECT
        Id,
        X6QA__c,
        X6sense_Account_6QA_Start_Date__c,
        X6sense_Account_6QA_End_Date__c,
        X6sense_Account_Buying_Stage__c,
        X6sense_Stage_Awareness__c,
        X6sense_Stage_Consideration__c,
        X6sense_Stage_Decision__c,
        X6sense_Stage_Purchase__c
      FROM Account
      WHERE Id IN :accounts
    ];

    for (Account account : accounts) {
      switch on account.X6sense_Account_Buying_Stage__c {
        when 'Awareness' {
          System.assertEquals(
            account.X6sense_Stage_Awareness__c,
            Date.today(),
            'Date of Stage Awareness not correctly set.'
          );
        }
        when 'Consideration' {
          System.assertEquals(
            account.X6sense_Stage_Consideration__c,
            Date.today(),
            'Date of Stage Consideration not correctly set.'
          );
        }
        when 'Decision' {
          System.assertEquals(
            account.X6sense_Stage_Decision__c,
            Date.today(),
            'Date of Stage Decision not correctly set.'
          );
        }
        when 'Purchase' {
          System.assertEquals(
            account.X6sense_Stage_Purchase__c,
            Date.today(),
            'Date of Stage Purchase not correctly set.'
          );
        }
      }

      if (account.X6QA__c) {
        System.assertEquals(
          Date.today(),
          account.X6sense_Account_6QA_Start_Date__c,
          '6QA Start Date not set for 6QA Account.'
        );
      } else {
        System.assertEquals(
          Date.today(),
          account.X6sense_Account_6QA_End_Date__c,
          '6QA Start Date not set for 6QA Account.'
        );
      }
    }
  }
}