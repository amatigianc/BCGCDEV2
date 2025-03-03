@isTest
public with sharing class OpportunityStageCaseHandlerTest {
  @TestSetup
  static void createDataSet() {
    TestUserProvisioner provisioner = new TestUserProvisioner(
      UserInfo.getUserId()
    );

    provisioner.setLicenses(
      new List<String>{
        'SalesforceCPQ_CPQStandardPerm',
        'SalesforceCPQ_CPQAAPerm'
      }
    );
    provisioner.setPermissions(
      new List<String>{
        'Approvals_Global',
        'CPQ_Global',
        'Order_Contract_an_Order',
        'Global_Read',
        'SteelBrickCPQUser',
        'AdvancedApprovalsUser',
        'Bypass_Validation_Rule'
      }
    );

    provisioner.assignPermissions();

    AccountTestFactory.createCustomer();
  }

  @isTest
  static void testCaseCreation() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    Id opportunityRecordType = RecordTypeUtility.getId(
      Opportunity.getSObjectType(),
      'New Business'
    );
    Opportunity opp = OpportunityTestFactory.getStage4Opp(account.Id);
    opp.Is_the_Contract_Auto_Renewing__c = 'No';
    opp.RecordTypeId = opportunityRecordType;
    Database.update(opp, false);

    SBQQ.TriggerControl.disable();

    Test.startTest();

    //OpportunityTestFactory.closeWin(opp);
    opp.StageName = 'Closed Won';
    Database.update(opp, true);

    Test.stopTest();

    List<Case> cases = [
      SELECT Id, Origin, Type
      FROM Case
      WHERE AccountId = :opp.AccountId
    ];

    System.assertEquals(1, cases.size(), 'Incorrect number of cases created.');

    for (Case c : cases) {
      System.assertEquals(
        'Automated Task',
        c.Type,
        'Case was not created with the right Type.'
      );
      System.assertEquals(
        'System',
        c.Origin,
        'Case was not created with the right Origin.'
      );
    }
  }
}