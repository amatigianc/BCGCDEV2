@IsTest
public with sharing class OpportunityRenewalGrowthHandlerTest {
  @IsTest
  public static void opportunityRenewalGrowthTestNotClosed() {
    Account account = AccountTestFactory.createCustomer();

    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    insert opp;

    //lol
    Test.startTest();
    opp.Manual_ACV__c = 12000.00;
    opp.Existing_MRR__c = 800.0;
    opp.MRR_Commit__c = 600.0;
    update opp;
    Test.stopTest();

    opp = [
      SELECT Id, New_MRR__c, Renewal_Growth_Amount__c, MRR_Commit__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    System.assertEquals(1000.00, opp.New_MRR__c, 'New MRR is not correct');
    System.assertEquals(
      2400.00,
      opp.Renewal_Growth_Amount__c,
      'Renewal Growth Amount is not correct'
    );

    System.assertEquals(600.00, opp.MRR_Commit__c, 'MRR Commit is not correct');
  }

  @IsTest
  public static void opportunityRenewalGrowthTestClosedWon() {
    Account account = AccountTestFactory.createCustomer();

    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    insert opp;

    OpportunityTestFactory.setStage2(opp);
    update opp;

    OpportunityTestFactory.setStage3(opp);
    update opp;

    OpportunityTestFactory.setStage4(opp);
    update opp;

    SBQQ.TriggerControl.disable();
    Test.startTest();

    opp.Manual_ACV__c = 10000.00;
    opp.Existing_MRR__c = 1000.0;
    opp.MRR_Commit__c = 600.0;
    OpportunityTestFactory.closeWin(opp);
    update opp;

    Test.stopTest();
    SBQQ.TriggerControl.enable();

    opp = [
      SELECT Id, New_MRR__c, Renewal_Growth_Amount__c, MRR_Commit__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    System.assertEquals(10000.0 / 12, opp.New_MRR__c, 'New MRR is not correct');
    System.assertEquals(
      0.00,
      opp.Renewal_Growth_Amount__c,
      'Renewal Growth Amount is not correct'
    );

    System.assertEquals(
      10000.0 / 12,
      opp.MRR_Commit__c,
      'MRR Commit is not correct'
    );
  }
}