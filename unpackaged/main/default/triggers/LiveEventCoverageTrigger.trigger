trigger LiveEventCoverageTrigger on Live_Event_Coverage__c(
  after insert,
  after update,
  after delete
) {
  DomainHandlerUtility handler = new DomainHandlerUtility();
  handler.process();
}