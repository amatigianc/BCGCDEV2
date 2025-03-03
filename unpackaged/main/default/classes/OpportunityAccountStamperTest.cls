@isTest
public with sharing class OpportunityAccountStamperTest {
  @TestSetup
  static void makeData() {
    Account account = AccountTestFactory.getCustomer();
    account.Name = 'OpportunityAccountStamperTest';
    account.X6sense_Account_6QA_End_Date__c = Date.today().addDays(-1);
    account.X6sense_Account_6QA_Start_Date__c = Date.today().addDays(-2);
    account.X6sense_Account_Buying_Stage__c = 'Definitely buying';
    account.X6sense_Account_Intent_Score__c = 123;
    account.X6sense_Account_Profile_Fit__c = 'Nice fit';
    account.X6sense_Account_Reach_Score__c = '456';
    account.X6Sense_Segment_Name__c = 'Nice segment my friend';
    account.X6sense_Stage_Awareness__c = Date.today().addDays(-4);
    account.X6sense_Stage_Consideration__c = Date.today().addDays(-3);
    account.X6sense_Stage_Decision__c = Date.today().addDays(-2);
    account.X6sense_Stage_Purchase__c = Date.today().addDays(-1);
    account.Named_Account__c = true;
    account.Named_Account_Tier__c = 'Tier 1';

    insert account;
  }

  @isTest
  static void testStageZeroOppCreation() {
    Account account = [
      SELECT Id, X6QA__c
      FROM Account
      WHERE Name = 'OpportunityAccountStamperTest'
    ];
    account.X6QA__c = true;
    Id accountId = account.Id;

    Test.startTest();
    update account;
    Test.stopTest();

    List<String> fields = new List<String>{
      'X6sense_Account_6QA_End_Date__c',
      'X6sense_Account_6QA_Start_Date__c',
      'X6sense_Account_Buying_Stage__c',
      'X6sense_Account_Intent_Score__c',
      'X6sense_Account_Profile_Fit__c',
      'X6sense_Account_Reach_Score__c',
      'X6Sense_Segment_Name__c',
      'X6sense_Stage_Awareness__c',
      'X6sense_Stage_Consideration__c',
      'X6sense_Stage_Decision__c',
      'X6sense_Stage_Purchase__c',
      'Named_Account__c',
      'Named_Account_Tier__c'
    };

    List<Opportunity> opps = Database.query(
      'SELECT Id, Account_Stage_at_Creation__c, X6sense_6QA__c, ' +
        String.join(fields, ', ') +
        ' FROM Opportunity WHERE AccountId = :accountId AND RecordType.Name =\'Lead\''
    );

    System.assertEquals(
      1,
      opps.size(),
      'Incorrect number of Opportunity records created.'
    );

    account = (Account) Database.query(
      'SELECT Id, Account_Stage__c, X6QA__c, ' +
        String.join(fields, ', ') +
        ' FROM Account WHERE Id = :accountId'
    );

    System.assertEquals(
      account.Account_Stage__c,
      opps[0].Account_Stage_at_Creation__c,
      'Account Stage at Creation not correctly set on Opportunity'
    );

    System.assertEquals(
      account.X6QA__c,
      opps[0].X6sense_6QA__c,
      '6Sense at Creation not correctly set on Opportunity'
    );
    for (String field : fields) {
      Object expected = account.get(field);
      Object actual = opps[0].get(field);
      System.assertEquals(
        expected,
        actual,
        'Incorrect value set on Opportunity for field: ' + field
      );
    }
  }

  @isTest
  static void testStageOneOpp() {
    Account account = [
      SELECT Id, X6QA__c
      FROM Account
      WHERE Name = 'OpportunityAccountStamperTest'
    ];
    account.X6QA__c = true;
    Id accountId = account.Id;

    update account;

    Test.startTest();

    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    insert opp;

    Test.stopTest();

    List<String> fields = new List<String>{
      'X6sense_Account_6QA_End_Date__c',
      'X6sense_Account_6QA_Start_Date__c',
      'X6sense_Account_Buying_Stage__c',
      'X6sense_Account_Intent_Score__c',
      'X6sense_Account_Profile_Fit__c',
      'X6sense_Account_Reach_Score__c',
      'X6Sense_Segment_Name__c',
      'X6sense_Stage_Awareness__c',
      'X6sense_Stage_Consideration__c',
      'X6sense_Stage_Decision__c',
      'X6sense_Stage_Purchase__c',
      'Named_Account__c',
      'Named_Account_Tier__c'
    };

    account = (Account) Database.query(
      'SELECT Id, Account_Stage__c, X6QA__c, ' +
        String.join(fields, ', ') +
        ' FROM Account WHERE Name = \'OpportunityAccountStamperTest\''
    );

    opp = (Opportunity) Database.query(
      'SELECT Id, Account_Stage_at_Creation__c, X6sense_6QA__c, ' +
        String.join(fields, ', ') +
        ' FROM Opportunity WHERE AccountId = :accountId AND RecordType.Name =\'New Business\''
    );

    System.assertEquals(
      account.Account_Stage__c,
      opp.Account_Stage_at_Creation__c,
      'Account Stage at Creation not correctly set on Opportunity'
    );

    System.assertEquals(
      account.X6QA__c,
      opp.X6sense_6QA__c,
      '6Sense at Creation not correctly set on Opportunity'
    );

    for (String field : fields) {
      Object expected = account.get(field);
      Object actual = opp.get(field);
      System.assertEquals(
        expected,
        actual,
        'Incorrect value set on Opportunity for field: ' + field
      );
    }
  }
}