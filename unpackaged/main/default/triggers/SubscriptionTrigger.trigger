trigger SubscriptionTrigger on SBQQ__Subscription__c(
    before insert,
    after insert
) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}