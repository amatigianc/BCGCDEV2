trigger BrightcoveAccountTrigger on Brightcove_Account__c(
    before insert,
    after insert,
    before update,
    after update
) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}