@IsTest
public with sharing class OpportunityClosedWonOrderedHandlerTest {
  @TestSetup
  static void setupData() {
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
        'AdvancedApprovalsUser'
      }
    );
    provisioner.assignPermissions();

    //Sales User Setup
    Profile profile = [SELECT Id FROM Profile WHERE Name = 'Sales'];

    List<User> users = new List<User>{
      new User(
        LastName = 'Sales',
        Email = 'test_Sales_User_Record@testemail.com',
        UserName = 'test_Sales_User_Record@testemail.com',
        Alias = 'sales',
        ProfileId = profile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US'
      ),
      new User(
        LastName = 'Manager',
        Email = 'test_Manager_User_Record@testemail.com',
        UserName = 'test_Manager_User_Record@testemail.com',
        Alias = 'mgr',
        ProfileId = profile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US'
      )
    };

    insert users;

    Account account = AccountTestFactory.createCustomer();

    List<AccountTeamMember> teamMembers = new List<AccountTeamMember>{
      new AccountTeamMember(
        AccountId = account.Id,
        TeamMemberRole = 'Sales Rep',
        UserId = users[0].Id
      ),
      new AccountTeamMember(
        AccountId = account.Id,
        TeamMemberRole = 'Account Manager',
        UserId = users[1].Id
      )
    };

    insert teamMembers;

    Product2 testProd = new Product2(
      Name = 'Test Product Pricebook Manager',
      ProductCode = 'TST-PRD-PRCE-MNGR'
    );

    insert testProd;

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = testProd.Id,
      UnitPrice = 1500,
      CurrencyIsoCode = 'USD',
      IsActive = true
    );

    insert pbe;

    Opportunity opp = OpportunityTestFactory.getStage2Opp(account.Id);

    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__Opportunity2__c = :opp.Id
    ];

    insert new SBQQ__QuoteLine__c(
      SBQQ__Product__c = testProd.Id,
      SBQQ__Quantity__c = 1,
      SBQQ__ListPrice__c = 0,
      SBQQ__StartDate__c = Date.today(),
      SBQQ__Quote__c = quote.Id,
      SBQQ__PricebookEntryId__c = pbe.Id
    );
  }

  @IsTest
  public static void testClosedWonOrdered() {
    Account account = [
      SELECT
        Id,
        (
          SELECT Id, SBQQ__Ordered__c, StageName
          FROM Opportunities
          WHERE IsClosed = FALSE
          LIMIT 1
        ),
        (
          SELECT Id, UserId
          FROM AccountTeamMembers
          WHERE TeamMemberRole = 'Account Manager'
          LIMIT 1
        )
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    Opportunity opp = account.Opportunities[0];

    System.assertEquals(
      false,
      opp.SBQQ__Ordered__c,
      'Ordered was already set to true.'
    );

    Test.startTest();

    OpportunityTestFactory.closeWin(opp);
    update opp;

    Test.stopTest();

    opp = [SELECT Id, SBQQ__Ordered__c FROM Opportunity WHERE Id = :opp.Id];

    System.assertEquals(
      true,
      opp.SBQQ__Ordered__c,
      'Ordered was not changed to true.'
    );
  }
}