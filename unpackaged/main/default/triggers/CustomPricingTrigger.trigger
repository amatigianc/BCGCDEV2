trigger CustomPricingTrigger on Custom_Pricing__c(
    before insert,
    after insert,
    after update
) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}