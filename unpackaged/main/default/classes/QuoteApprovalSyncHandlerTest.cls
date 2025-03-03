@IsTest
public with sharing class QuoteApprovalSyncHandlerTest {
  @TestSetup
  static void setup() {
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
        'SteelBrickCPQUser',
        'AdvancedApprovalsUser'
      }
    );
    provisioner.assignPermissions();
  }

  @IsTest
  public static void testApprovalSync() {
    SBQQ__Quote__c quote = QuoteTestFactory.createBaseQuote();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Test.startTest();

      SBAA.ApprovalAPI.submit(quote.Id, SBAA__Approval__c.Quote__c);

      Test.stopTest();
    }

    quote = [
      SELECT SBQQ__Status__c
      FROM SBQQ__Quote__c
      WHERE Id = :quote.Id
      LIMIT 1
    ];

    System.assertEquals(
      'Approved',
      quote.SBQQ__Status__c,
      'Expected Approved, Actual: ' + quote.SBQQ__Status__c
    );
  }
}