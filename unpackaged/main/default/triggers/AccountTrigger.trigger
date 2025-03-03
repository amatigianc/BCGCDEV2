trigger AccountTrigger on Account(
    before insert,
    before update,
    after insert,
    after update
) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}