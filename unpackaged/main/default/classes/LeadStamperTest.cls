@isTest(isparallel=true)
public with sharing class LeadStamperTest {
  @isTest
  private static void testStamp() {
    List<PicklistEntry> stages = Lead.Stage__c.getDescribe()
      .getPicklistValues();
    Lead testLead = LeadTestFactory.getLead();
    testLead.Stage__c = stages[0].getValue();
    insert testLead;

    testLead = [
      SELECT Id, n2de__Is_rejected__c, Rejected_Reason__c, Stage_Date__c
      FROM Lead
      WHERE Id = :testLead.Id
    ];

    System.assertEquals(
      Date.today(),
      testLead.Stage_Date__c,
      'Stage Date not set correctly.'
    );
  }
}