trigger BlockPriceTrigger on SBQQ__BlockPrice__c(
    before insert,
    after insert,
    after update
) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}