@isTest
public class OpportunityStageAccountHandlerTest {
  @testSetup
  static void createDataSet() {
    TestUserProvisioner provisioner = new TestUserProvisioner(
      UserInfo.getUserId()
    );
    provisioner.setPermission('Bypass_Validation_Rules');
    provisioner.assignPermissions();

    AccountTestFactory.createCustomer();
  }

  @isTest
  static void testClosedWonOpportunities() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    Opportunity opp = OpportunityTestFactory.getStage4Opp(
      account.Id,
      RecordTypeUtility.getId(Opportunity.getSObjectType(), 'New Business')
    );
    update opp;

    opp = [
      SELECT Id, StageName, AccountId
      FROM Opportunity
      WHERE Account.Name LIKE 'AccountTestFactory%' AND IsClosed = FALSE
      LIMIT 1
    ];

    List<Id> accountIds = new List<Id>();
    OpportunityTestFactory.closeWin(opp);
    accountIds.add(opp.AccountId);

    SBQQ.TriggerControl.disable();
    Test.startTest();

    update opp;

    Test.stopTest();
    SBQQ.TriggerControl.enable();

    //Let's check the accounts.
    account = [
      SELECT Id, Account_Stage__c
      FROM Account
      WHERE Id = :account.Id
    ];

    System.assertEquals(
      'Customer',
      account.Account_Stage__c,
      'The account stage was not correctly updated from Prospect to Customer.'
    );
  }
}