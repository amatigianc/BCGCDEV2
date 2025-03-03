@isTest
public with sharing class OpportunityClosedWonForecastInOutTest {
  @TestSetup
  static void createDataSet() {
    List<Account> accountSet = AccountTestFactory.createCustomers(3);

    List<Opportunity> oppSet = new List<Opportunity>();
    for (Account accRecord : accountSet) {
      Opportunity testOpp = OpportunityTestFactory.getStage4Opp(accRecord.Id);
      testOpp.Forecast_In_Out__c = 'Out';
      oppSet.add(testOpp);
    }
    update oppSet;
  }

  @isTest
  static void testOpportunityClosedWon() {
    List<Opportunity> optySet = [
      SELECT id, StageName, Forecast_in_out__c
      FROM Opportunity
      WHERE Forecast_In_Out__c = 'Out' AND StageName = '4 - Negotiation'
    ];

    for (Opportunity oppRecord : OptySet) {
      OpportunityTestFactory.closeWin(oppRecord);
    }

    SBQQ.TriggerControl.disable();

    Test.startTest();
    update OptySet;
    Test.stopTest();

    optySet = [
      SELECT id, Forecast_in_out__c
      FROM Opportunity
      WHERE Id IN :optySet
    ];
    for (Opportunity oppRecord : OptySet) {
      System.assertEquals(
        'In',
        oppRecord.Forecast_In_Out__c,
        'Forecast In Out not updated to IN'
      );
    }
  }
}