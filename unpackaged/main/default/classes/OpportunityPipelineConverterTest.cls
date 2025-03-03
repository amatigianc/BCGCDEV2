@isTest
public with sharing class OpportunityPipelineConverterTest {
  @TestSetup
  static void makeData() {
    User bdr = TestUserProvisioner.getNewUser();
    bdr.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'BDR' LIMIT 1].Id;
    bdr.LastName = 'OpportunityPipelineConverterTest';
    bdr.Division = 'Japan';
    bdr.Sub_Division__c = 'Korea';
    TestUserProvisioner.insertUsers(JSON.serialize(new List<User>{ bdr }));
  }

  @isTest
  static void testConvert() {
    User bdr = [
      SELECT Id
      FROM User
      WHERE LastName = 'OpportunityPipelineConverterTest'
      LIMIT 1
    ];

    List<Account> accounts = AccountTestFactory.createCustomers(2);

    List<Opportunity> opps = new List<Opportunity>{
      new Opportunity(
        AccountId = accounts[0].Id,
        RecordTypeId = RecordTypeUtility.getId(
          Opportunity.getSObjectType(),
          'Lead'
        ),
        CloseDate = Date.today().addYears(1),
        StageName = '0 - Meeting Pending',
        Contract_Type__c = 'Standard Term Contract',
        OwnerId = bdr.Id
      ),
      new Opportunity(
        AccountId = accounts[1].Id,
        RecordTypeId = RecordTypeUtility.getId(
          Opportunity.getSObjectType(),
          'Lead'
        ),
        CloseDate = Date.today().addYears(1),
        StageName = '0 - Meeting Pending',
        Contract_Type__c = 'Standard Term Contract',
        OwnerId = bdr.Id
      )
    };
    insert opps;

    for (Opportunity opp : opps) {
      opp.StageName = '0 - Meeting Scheduled';
    }
    update opps;

    for (Opportunity opp : opps) {
      opp.StageName = '0 - Meeting Occurred';
    }
    update opps;

    opps = [
      SELECT Id, Convert_to_Pipeline__c
      FROM Opportunity
      WHERE Id IN :opps
    ];

    for (Opportunity opp : opps) {
      opp.Convert_to_Pipeline__c = true;
    }

    Test.startTest();
    update opps;
    Test.stopTest();

    opps = [
      SELECT
        Id,
        Account.Account_Stage__c,
        Account.Name,
        RecordType.Name,
        StageName
      FROM Opportunity
      WHERE Id IN :opps
    ];
    for (Opportunity opp : opps) {
      switch on opp.Account.Account_Stage__c {
        when 'Customer' {
          System.assertEquals(
            'Add-On',
            opp.RecordType.Name,
            'Incorrect Record Type for Customer: ' + opp.Account.Name
          );
        }
        when else {
          System.assertEquals(
            'New Business',
            opp.RecordType.Name,
            'Incorrect Record Type for Prospect: ' + opp.Account.Name
          );
        }
      }

      System.assertEquals(
        '1 - Discovery',
        opp.StageName,
        'Stage was incorrectly set for converted Opportunity.'
      );
    }
  }
}