trigger CaseTrigger on Case(
  before insert,
  after insert,
  before update,
  after update
) {
  DomainHandlerUtility handler = new DomainHandlerUtility();
  handler.process();

}