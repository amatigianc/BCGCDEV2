@isTest
public with sharing class OpportunityClosedWonOwnerHandlerTest {
  @TestSetup
  static void dataSetup() {
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

    Opportunity opp = OpportunityTestFactory.getStage4Opp(account.Id);
    update opp;
  }

  @isTest
  static void testOpportunityClosedWonOwner() {
    Account account = [
      SELECT
        Id,
        (
          SELECT Id, OwnerId, StageName
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

    SBQQ.TriggerControl.disable();
    Test.startTest();

    Opportunity opp = account.Opportunities[0];
    OpportunityTestFactory.closeWin(opp);
    update opp;

    Test.stopTest();
    SBQQ.TriggerControl.enable();

    Id expectedOwnerId = account.AccountTeamMembers[0].UserId;

    opp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :opp.Id];

    System.assertEquals(
      expectedOwnerId,
      opp.OwnerId,
      'Ownership was not changed to the related Account Manager.'
    );
  }
}