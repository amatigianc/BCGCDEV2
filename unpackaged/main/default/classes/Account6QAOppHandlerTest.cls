@isTest
public with sharing class Account6QAOppHandlerTest {
  @TestSetup
  static void makeData() {
    List<Account> accounts = AccountTestFactory.getCustomers(7);

    accounts[0].Account_Stage__c = 'Customer';

    accounts[1].Named_Account_Tier__c = 'Tier 1';
    accounts[1].Named_Account__c = true;
    accounts[1].Account_Stage__c = 'Prospect';

    accounts[2].Named_Account_Tier__c = 'Tier 2';
    accounts[2].Named_Account__c = true;
    accounts[2].Account_Stage__c = 'Prospect';

    accounts[3].Named_Account_Tier__c = 'Tier 3';
    accounts[3].Named_Account__c = true;
    accounts[3].Account_Stage__c = 'Prospect';
    accounts[3].Account_Business_Unit__c = 'Media';
    accounts[3].Sales_Division__c = 'Americas';

    accounts[4].Named_Account__c = true;
    accounts[4].Named_Account_Tier__c = 'Tier 1';
    accounts[4].Account_Stage__c = 'Former';

    accounts[5].Named_Account__c = true;
    accounts[5].Named_Account_Tier__c = 'Tier 2';
    accounts[5].Account_Stage__c = 'Former';

    accounts[6].Named_Account__c = true;
    accounts[6].Named_Account_Tier__c = 'Tier 3';
    accounts[6].Account_Stage__c = 'Former';
    accounts[6].Account_Business_Unit__c = 'Media';
    accounts[6].Sales_Division__c = 'Americas';

    insert accounts;
  }

  @isTest
  static void testOppCreation() {
    List<Account> accounts = [
      SELECT Id, X6QA__c, Name
      FROM Account
      WHERE
        X6QA__C = FALSE
        AND RecordType.Name = 'Customer'
        AND Named_Account__c = TRUE
        AND Name LIKE 'AccountTestFactory%'
    ];

    System.assertEquals(6, accounts.size());

    for (Account account : accounts) {
      account.X6QA__c = true;
    }

    String defaultOwnerUserName = Label.Default_Lead_Opp_Owner + '%';
    Id defaultOwnerId = [
      SELECT Id
      FROM User
      WHERE UserName LIKE :defaultOwnerUserName
    ]
    .Id;

    Test.startTest();
    update accounts;
    Test.stopTest();

    List<Opportunity> opps = [
      SELECT
        Id,
        AccountId,
        Account.Name,
        X6QA__c,
        Account.Account_Stage__c,
        StageName,
        RecordType.Name,
        CloseDate,
        LeadSource,
        OwnerId,
        Deal_Type__c,
        Contract_Type__c
      FROM Opportunity
      WHERE AccountId IN :accounts
    ];

    System.assertEquals(
      accounts.size(),
      opps.size(),
      'Incorrect number of Opportunity records were created after the Accounts were marked as 6QA.'
    );

    for (Opportunity opp : opps) {
      System.assertEquals(
        '0 - Meeting Pending',
        opp.StageName,
        'Opportunity Stage not correctly set.'
      );
      System.assertEquals(
        'Lead',
        opp.RecordType.Name,
        'Opportunity Record Type not correctly set.'
      );
      System.assertEquals(
        Date.today().addDays(30),
        opp.CloseDate,
        'Opportunity Close Date not correctly set.'
      );
      System.assertEquals(
        'QA',
        opp.LeadSource,
        'Opportunity Lead Source was not correctly set.'
      );
      System.assertEquals(
        opp.Account.Account_Stage__c == 'Customer' ? 'Add-On' : 'New Business',
        opp.Deal_Type__c,
        'Opportunity Deal Type not correctly set.'
      );
      System.assertEquals(
        true,
        opp.X6QA__c,
        'Opportunity record was not marked with 6QA.'
      );
      System.assertEquals(
        defaultOwnerId,
        opp.OwnerId,
        'Incorrect Owner assigned.'
      );
      System.assertEquals(
        'Standard Term Contract',
        opp.Contract_Type__c,
        'Contract Type not marked with Standard Term Contract'
      );
    }
  }

  @isTest
  static void negativeTest() {
    List<Account> accounts = AccountTestFactory.createCustomers(1);

    accounts[0].Account_Stage__c = 'Customer';

    update accounts;

    insert new Opportunity(
      RecordTypeId = RecordTypeUtility.getId(
        Opportunity.getSObjectType(),
        'Renewal'
      ),
      CloseDate = Date.today().addDays(10),
      AccountId = accounts[accounts.size() - 1].Id,
      StageName = '1 - Discovery'
    );

    for (Account account : accounts) {
      account.X6QA__c = true;
    }

    Test.startTest();
    List<Opportunity> o = [
      SELECT Id, RecordType.Name, CloseDate
      FROM Opportunity
      WHERE
        AccountId = :accounts[0].Id
        AND RecordType.Name IN ('Add-On', 'Lead', 'Renewal')
        AND CloseDate <= :Date.today().addDays(90)
    ];
    System.assert(!o.isEmpty());

    update accounts;
    Test.stopTest();

    List<Opportunity> opps = [
      SELECT Id, Account.Name
      FROM Opportunity
      WHERE AccountId IN :accounts AND RecordType.Name = 'Lead'
    ];

    System.assert(
      opps.isEmpty(),
      'Opportunity records were incorrectly created from non-qualified Account'
    );
  }
}