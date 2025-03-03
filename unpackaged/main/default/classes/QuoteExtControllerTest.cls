//pulled from https://help.salesforce.com/s/articleView?id=sf.cpq_enable_aa.htm&type=5

@isTest
private class QuoteExtControllerTest {
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
  static void testSubmit() {
    SBQQ__Quote__c quote = QuoteTestFactory.createBaseQuote();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Test.startTest();

      QuoteExtController con = new QuoteExtController(
        new ApexPages.StandardController(quote)
      );
      con.onSubmit();

      Test.stopTest();
    }

    quote = [
      SELECT ApprovalStatus__c
      FROM SBQQ__Quote__c
      WHERE Id = :quote.Id
      LIMIT 1
    ];

    System.assertEquals('Approved', quote.ApprovalStatus__c);
  }

  @IsTest
  static void testRecall() {
    SBQQ__Quote__c quote = QuoteTestFactory.createBaseQuote();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Test.startTest();

      QuoteExtController con = new QuoteExtController(
        new ApexPages.StandardController(quote)
      );
      con.onRecall();

      Test.stopTest();
    }

    quote = [
      SELECT ApprovalStatus__c
      FROM SBQQ__Quote__c
      WHERE Id = :quote.Id
      LIMIT 1
    ];

    System.assertEquals('Recalled', quote.ApprovalStatus__c);
  }
}