@isTest
public with sharing class OpportunityStageDateStamperTest {
  static Map<String, SObjectField> stageFieldMap = new Map<String, SObjectField>{
    '1 - Discovery' => Opportunity.Discovery_Stage_Set_Date__c,
    '2 - Demo' => Opportunity.Demo_Stage_Set_Date__c,
    '3 - Solution Design & Evaluation' => Opportunity.Solution_Design_Stage_Set_Date__c,
    '4 - Negotiation' => Opportunity.Negotiation_Stage_Set_Date__c,
    '0 - Meeting Pending' => Opportunity.Meeting_Pending_Stage_Set_Date__c,
    '0 - Meeting Scheduled' => Opportunity.Meeting_Scheduled_Stage_Set_Date__c,
    '0 - Meeting Occurred' => Opportunity.Meeting_Occurred_Stage_Set_Date__c
  };

  @TestSetup
  static void makeData() {
    AccountTestFactory.createCustomers(3);
  }

  @isTest
  private static void testStampStagedDateOnInsert() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    insert opp;

    opp = [
      SELECT Id, Discovery_Stage_Set_Date__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    System.assertEquals(
      true,
      opp.Discovery_Stage_Set_Date__c != null,
      'Discovery Stage Set Date field was not stamped.'
    );

    Datetime actual = opp.Discovery_Stage_Set_Date__c;
    Datetime expected = Datetime.now();

    System.assertEquals(
      true,
      actual <= expected,
      'Datetime value was not correctly set'
    );
  }

  @isTest
  private static void testStampStagedDateOnConvert() {
    Opportunity opp = OpportunityTestFactory.getStageZeroOpp();
    insert opp;

    opp = [
      SELECT Id, Meeting_Pending_Stage_Set_Date__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    System.assertEquals(
      true,
      opp.Meeting_Pending_Stage_Set_Date__c != null,
      'Discovery Stage Set Date field was not stamped.'
    );

    Datetime actual = opp.Meeting_Pending_Stage_Set_Date__c;
    Datetime expected = Datetime.now();

    System.assertEquals(
      true,
      actual <= expected,
      'Datetime value was not correctly set'
    );

    opp.StageName = '0 - Meeting Scheduled';
    update opp;
    opp.Stagename = '0 - Meeting Occurred';
    update opp;

    opp.Convert_To_Pipeline__c = true;

    Test.startTest();
    update opp;
    Test.stopTest();

    opp = [
      SELECT Id, Discovery_Stage_Set_Date__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    actual = opp.Discovery_Stage_Set_Date__c;
    expected = Datetime.now();

    // System.assertEquals(
    //     true,
    //     actual <= expected,
    //     'Datetime value was not correctly set'
    // );
  }

  @isTest
  private static void testStampStagedDateOnUpdate() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    insert opp;

    OpportunityTestFactory.setStage2(opp);
    update opp;

    opp = [
      SELECT Id, StageName, Demo_Stage_Set_Date__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    SObjectField stageDateField = stageFieldMap.get(opp.StageName);
    System.assertEquals(
      true,
      opp.get(stageDateField) != null,
      'Discovery Stage Set Date field was not stamped.'
    );

    Datetime actual = (Datetime) opp.get(stageDateField);
    Datetime expected = Datetime.now();

    System.assertEquals(
      true,
      actual <= expected,
      'Datetime value was not correctly set'
    );
  }
}