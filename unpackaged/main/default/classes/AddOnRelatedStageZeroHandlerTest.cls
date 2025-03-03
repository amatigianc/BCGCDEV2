@isTest
public with sharing class AddOnRelatedStageZeroHandlerTest {
  @TestSetup
  static void makeData() {
    List<UserRole> roles = [
      SELECT Id
      FROM UserRole
      WHERE Name IN ('Account Manager', 'BDR')
      ORDER BY Name
    ];

    List<User> users = TestUserProvisioner.getNewUsers(2);
    users[0].UserRoleId = roles[0].Id;
    users[0].UserName = 'AM-BSTS-3645@example.com';
    users[1].UserRoleId = roles[1].Id;
    users[1].UserName = 'BDR-BSTS-3645@example.com';
    insert users;
  }

  @isTest
  static void testSync() {
    List<User> users = [
      SELECT Id, UserRole.Name
      FROM User
      WHERE UserName LIKE '%BSTS-3645@example.com'
      ORDER BY UserRole.Name
    ];

    Id accountId;
    Opportunity leadOpp;
    System.runAs(users[1]) {
      leadOpp = OpportunityTestFactory.getStageZeroOpp();
      accountId = leadOpp.AccountId;
    }

    Account account = new Account(
      Id = accountId,
      Account_Stage__c = 'Customer',
      Named_Account__c = true,
      Named_Account_Tier__c = Account.Named_Account_Tier__c.getDescribe()
          .getPicklistValues()[0]
        .getValue(),
      OwnerId = users[0].Id
    );
    update account;

    insert leadOpp;
    leadOpp.StageName = '0 - Meeting Scheduled';
    update leadOpp;
    leadOpp.StageName = '0 - Meeting Occurred';
    update leadOpp;

    leadOpp = [
      SELECT
        Id,
        AccountId,
        Meeting_Occurred_Stage_Set_Date__c,
        Meeting_Pending_Stage_Set_Date__c,
        Meeting_Scheduled_Stage_Set_Date__c,
        X6QA__c,
        Named_Account__c,
        Named_Account_Tier__c
      FROM Opportunity
      WHERE
        IsClosed = FALSE
        AND RecordType.Name = 'Lead'
        AND Account.Account_Stage__c = 'Customer'
      LIMIT 1
    ];

    Opportunity addOnOpp = OpportunityTestFactory.getStage1Opp(
      leadOpp.AccountId,
      RecordTypeUtility.getId(Opportunity.getSObjectType(), 'Add-On')
    );

    Test.startTest();
    System.runAs(users[0]) {
      insert addOnOpp;
    }
    Test.getEventBus().deliver();
    Test.stopTest();

    addOnOpp = [
      SELECT
        Id,
        Meeting_Occurred_Stage_Set_Date__c,
        Meeting_Pending_Stage_Set_Date__c,
        Meeting_Scheduled_Stage_Set_Date__c,
        X6QA__c,
        LeadSource,
        Named_Account__c,
        Named_Account_Tier__c
      FROM Opportunity
      WHERE Id = :addOnOpp.Id
    ];

    System.assertEquals(
      leadOpp.Meeting_Occurred_Stage_Set_Date__c,
      addOnOpp.Meeting_Occurred_Stage_Set_Date__c,
      'Meeting Occurred Stage Set Date not synced.'
    );
    System.assertEquals(
      leadOpp.Meeting_Pending_Stage_Set_Date__c,
      addOnOpp.Meeting_Pending_Stage_Set_Date__c,
      'Meeting Pending Stage Set Date not synced.'
    );
    System.assertEquals(
      leadOpp.Meeting_Scheduled_Stage_Set_Date__c,
      addOnOpp.Meeting_Scheduled_Stage_Set_Date__c,
      'Meeting Scheduled Stage Set Date not synced.'
    );
    System.assertEquals(
      leadOpp.Named_Account__c,
      addOnOpp.Named_Account__c,
      'Named Account not synced.'
    );
    System.assertEquals(
      leadOpp.Named_Account_Tier__c,
      addOnOpp.Named_Account_Tier__c,
      'Named Account Tier not synced.'
    );
    System.assertEquals(leadOpp.X6QA__c, addOnOpp.X6QA__c, '6QA not synced.');
    System.assertEquals('QA', addOnOpp.LeadSource, 'Lead Source not set.');

    List<Opportunity> existingLeadOpps = [
      SELECT Id
      FROM Opportunity
      WHERE AccountId = :leadOpp.AccountId AND RecordType.Name = 'Lead'
    ];
    System.assertEquals(
      0,
      existingLeadOpps.size(),
      'Existing Lead Opportunities were not deleted.'
    );
  }
}