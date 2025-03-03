trigger QuoteTrigger on SBQQ__Quote__c(
    before insert,
    before update,
    after update,
    after insert
) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}