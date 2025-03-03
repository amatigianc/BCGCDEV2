@isTest
public with sharing class OppOwnerDivisionStamperTest {
  @TestSetup
  static void makeData() {
    List<UserRole> userroles = [
      SELECT Id, Name
      FROM UserRole
      WHERE Name IN ('BDR', 'Account Executive')
    ];
    List<User> users = TestUserProvisioner.getNewUsers(2);
    users[0].UserRoleId = userroles[0].Id;
    users[0].Division = 'Division 1';
    users[0].Sub_Division__c = User.Sub_Division__c.getDescribe()
        .getPicklistValues()[0]
      .getValue();
    users[1].UserRoleId = userroles[1].Id;
    users[1].Division = 'Division 2';
    users[1].Sub_Division__c = User.Sub_Division__c.getDescribe()
        .getPicklistValues()[1]
      .getValue();
    insert users;
  }

  @isTest
  static void testStamp() {
    Account account = AccountTestFactory.createCustomer();
    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    opp.OwnerId = [
      SELECT Id
      FROM User
      WHERE UserRole.Name = 'Account Executive' AND IsActive = TRUE
      LIMIT 1
    ]
    .Id;
    insert opp;

    opp = [
      SELECT
        Id,
        Owner.Division,
        Owner_Division__c,
        Owner.Sub_Division__c,
        Owner_Sub_Division__C
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    System.assertEquals(
      opp.Owner.Division,
      opp.Owner_Division__c,
      'Owner Division was not stamped'
    );
    System.assertEquals(
      opp.Owner.Sub_Division__c,
      opp.Owner_Sub_Division__c,
      'Owner Sub Division was not stamped'
    );
  }

  @isTest
  static void testUpdate() {
    Opportunity opp = OpportunityTestFactory.getStageZeroOpp();
    opp.OwnerId = [
      SELECT Id
      FROM User
      WHERE UserRole.Name = 'BDR' AND IsActive = TRUE
      LIMIT 1
    ]
    .Id;
    insert opp;

    opp.StageName = '0 - Meeting Scheduled';
    update opp;

    opp.StageName = '0 - Meeting Occurred';
    update opp;

    Test.startTest();
    opp = [
      SELECT
        Id,
        Owner_Division__c,
        Owner_Sub_Division__c,
        Owner.Division,
        Owner.Sub_Division__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    System.assertEquals(
      opp.Owner.Division,
      opp.Owner_Division__c,
      'Owner Division was not stamped'
    );
    System.assertEquals(
      opp.Owner.Sub_Division__c,
      opp.Owner_Sub_Division__c,
      'Owner Sub Division was not stamped'
    );

    opp.Convert_to_Pipeline__c = true;
    opp.OwnerId = [
      SELECT Id
      FROM User
      WHERE UserRole.Name = 'Account Executive' AND IsActive = TRUE
      LIMIT 1
    ]
    .Id;
    update opp;
    Test.stopTest();

    System.assertEquals(
      opp.Owner.Division,
      opp.Owner_Division__c,
      'Owner Division was not stamped'
    );
    System.assertEquals(
      opp.Owner.Sub_Division__c,
      opp.Owner_Sub_Division__c,
      'Owner Sub Division was not stamped'
    );
  }
}