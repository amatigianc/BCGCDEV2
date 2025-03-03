@isTest
public with sharing class OpportunityContactStageHandlerTest {
  @TestSetup
  static void makeData() {
    ContactTestFactory.createContact();
  }

  @isTest
  static void testContactStageHandlingNewBus() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    Opportunity opp = OpportunityTestFactory.getStage1Opp(
      account.Id,
      RecordTypeUtility.getId(Opportunity.getSObjectType(), 'New Business')
    );
    opp.Deal_Type__c = 'New Business';

    Test.startTest();

    insert opp;

    Test.stopTest();
    Contact contact = [
      SELECT Id, Stage__c
      FROM Contact
      WHERE Id IN (SELECT ContactId FROM Opportunity WHERE Id = :opp.Id)
    ];

    System.assertEquals(
      'Opportunity',
      contact.Stage__c,
      'Contact Stage was not set to Opportunity.'
    );
  }

  @isTest
  static void testContactStageHandlingAddOn() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    Opportunity opp = OpportunityTestFactory.getStage1Opp(
      account.Id,
      RecordTypeUtility.getId(Opportunity.getSObjectType(), 'Add-On')
    );
    opp.Deal_Type__c = 'Add-On';

    Test.startTest();

    insert opp;

    Test.stopTest();
    Contact contact = [
      SELECT Id, Stage__c
      FROM Contact
      WHERE Id IN (SELECT ContactId FROM Opportunity WHERE Id = :opp.Id)
    ];

    System.assertEquals(
      'Opportunity',
      contact.Stage__c,
      'Contact Stage was not set to Opportunity.'
    );
  }

  @isTest
  static void testContactStageHandlingRenGrowth() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    Opportunity opp = OpportunityTestFactory.getStage1Opp(
      account.Id,
      RecordTypeUtility.getId(
        Opportunity.getSObjectType(),
        'Renewal Growth Add-on'
      )
    );

    opp.Deal_Type__c = 'Renewal Growth';

    Test.startTest();

    insert opp;

    Test.stopTest();
    Contact contact = [
      SELECT Id, Stage__c
      FROM Contact
      WHERE Id IN (SELECT ContactId FROM Opportunity WHERE Id = :opp.Id)
    ];

    System.assertEquals(
      'Opportunity',
      contact.Stage__c,
      'Contact Stage was not set to Opportunity.'
    );
  }
}