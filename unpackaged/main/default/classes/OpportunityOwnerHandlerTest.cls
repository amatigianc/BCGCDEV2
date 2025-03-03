@isTest
public with sharing class OpportunityOwnerHandlerTest {
  @TestSetup
  static void makeData() {
    User user = TestUserProvisioner.getNewUser();

    insert user;

    System.runAs(user) {
      AccountTestFactory.createCustomer();
    }
  }

  @isTest
  static void testOppOwner() {
    Account account = [
      SELECT Id, OwnerId
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];

    Test.startTest();

    Opportunity opp = OpportunityTestFactory.getStage1Opp(
      account.Id,
      RecordTypeUtility.getId(Opportunity.getSObjectType(), 'Add-On')
    );

    insert opp;

    Test.stopTest();

    opp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :opp.Id];

    System.assertEquals(
      account.OwnerId,
      opp.OwnerId,
      'Account owner was not set as new Add-On Opportunity Owner'
    );
  }
}