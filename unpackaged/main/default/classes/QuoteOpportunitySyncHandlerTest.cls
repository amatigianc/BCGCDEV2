@IsTest
public with sharing class QuoteOpportunitySyncHandlerTest {
  @IsTest
  public static void quoteOpportunitySyncHandlerTest() {
    Account account = AccountTestFactory.createCustomer();

    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);

    opp.Manual_ACV__c = 1000.0;
    opp.Manual_TCV__c = 1200.0;
    insert opp;

    opp = [
      SELECT Id, ACVH__c, TCVH__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    //Test without primary quote
    System.assertEquals(1000.00, opp.ACVH__c, 'ACVH is not correct');
    System.assertEquals(1200.00, opp.TCVH__c, 'TCVH is not correct');

    SBQQ__Quote__c relatedQuote = QuoteTestFactory.getPrimaryQuote(opp.Id);
    relatedQuote.SBQQ__Primary__c = false;
    relatedQuote.SBQQ__Account__c = account.Id;

    insert relatedQuote;

    Test.startTest();
    relatedQuote.ACV_Override__c = 1200.0;
    update relatedQuote;
    Test.stopTest();

    opp = [
      SELECT Id, ACVH__c, TCVH__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    //Test with new value from primary quote
    System.assertEquals(1000.00, opp.ACVH__c, 'ACVH is not correct');
    System.assertEquals(1200.00, opp.TCVH__c, 'TCVH is not correct');
  }
}