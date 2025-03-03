@isTest
public with sharing class OpportunityContactRoleContactStageTest {
  @TestSetup
  static void makeData() {
    ContactTestFactory.createContact();
  }

  @isTest
  static void testOppContactRolecontactStage() {
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
    insert opp;

    Contact newContact = [
      SELECT Id
      FROM Contact
      WHERE LastName LIKE 'ContactTestFactory%'
    ];

    OpportunityContactRole contactRole = new OpportunityContactRole();
    contactRole.ContactId = newContact.Id;
    contactRole.OpportunityId = opp.Id;

    Test.startTest();
    insert contactRole;
    Test.stopTest();

    newContact = [
      SELECT Id, Stage__c
      FROM Contact
      WHERE Id = :newContact.Id
    ];

    System.assertEquals(
      'Opportunity',
      newContact.Stage__c,
      'Contact stage was not updated to Opportunity'
    );
  }
}