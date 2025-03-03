@isTest
public with sharing class OpportunityDefaultValueAssignmentTest {
  @isTest
  private static void testAssignments() {
    Account customer = AccountTestFactory.createCustomer();
    List<Opportunity> opps = new List<Opportunity>();

    opps.add(OpportunityTestFactory.getStage1Opp(customer.Id));
    opps[0].RecordTypeId = RecordTypeUtility.getId(
      Opportunity.getSObjectType(),
      'New Business'
    );

    opps.add(OpportunityTestFactory.getStage1Opp(customer.Id));
    opps[1].RecordTypeId = RecordTypeUtility.getId(
      Opportunity.getSObjectType(),
      'Renewal'
    );

    opps.add(OpportunityTestFactory.getStage1Opp(customer.Id));
    opps[2].RecordTypeId = RecordTypeUtility.getId(
      Opportunity.getSObjectType(),
      'Add-On'
    );

    opps.add(OpportunityTestFactory.getStage1Opp(customer.Id));
    opps[3].RecordTypeId = RecordTypeUtility.getId(
      Opportunity.getSObjectType(),
      'Services Record Type'
    );

    insert opps;

    opps = [
      SELECT Id, RecordType.Name, Deal_Type__c
      FROM Opportunity
      WHERE Id IN :opps
    ];

    for (Opportunity opp : opps) {
      switch on opp.RecordType.Name {
        when 'Services Record Type' {
          System.assertEquals(
            null,
            opp.Deal_Type__c,
            'Services Record Type incorrectly assigned a Deal Type value.'
          );
        }
        when else {
          System.assertEquals(
            opp.RecordType.Name,
            opp.Deal_Type__c,
            'Deal Type was not correctly assigned for Record Type: ' +
            opp.RecordType.Name
          );
        }
      }
    }
  }
}