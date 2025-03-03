trigger ContactTrigger on Contact(
    before insert,
    after insert,
    before update,
    after update
) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}