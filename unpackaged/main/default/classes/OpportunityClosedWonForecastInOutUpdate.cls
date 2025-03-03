public with sharing class OpportunityClosedWonForecastInOutUpdate extends DomainLogicHandler {
  List<Opportunity> opportunities = new List<Opportunity>();

  public override void check(Sobject newObj, Sobject oldObj) {
    Opportunity newOpty = (Opportunity) newObj;
    Opportunity oldOpty = (Opportunity) oldObj;

    if (isQualified(newOpty, oldOpty)) {
      opportunities.add(newOpty);
    }
  }

  private Boolean isQualified(Opportunity newOpp, Opportunity oldOpp) {
    return TriggerUtility.isChanged(newOpp, oldOpp, Opportunity.StageName) &&
      (newOpp.StageName == 'Closed Won' &&
      newOpp.Forecast_In_Out__c == 'Out');
  }

  public override void processRecords() {
    for (Opportunity oppRecord : opportunities) {
      oppRecord.Forecast_In_Out__c = 'In';
    }
  }
}