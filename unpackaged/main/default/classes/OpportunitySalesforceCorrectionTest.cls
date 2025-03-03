@isTest
public with sharing class OpportunitySalesforceCorrectionTest {
  @isTest
  private static void testStageSelection() {
    Account account = AccountTestFactory.createCustomer();
    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.id);
    insert opp;

    Test.startTest();

    opp = [
      SELECT Id, StageName, Reason_for_Win_Loss__c, SubReason_for_winloss__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    opp.StageName = 'Salesforce Correction';
    update opp;
    Test.stopTest();

    opp = [
      SELECT Id, StageName, Reason_for_Win_Loss__c, SubReason_for_winloss__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    System.assertEquals(
      'Salesforce Correction',
      opp.Reason_for_Win_Loss__c,
      'Reason_for_Win_Loss__c Not updated to Salesforce Correction'
    );
    System.assertEquals(
      'Salesforce Correction',
      opp.SubReason_for_winloss__c,
      'SubReason_for_winloss__c Not updated to Salesforce Correction'
    );
  }
}