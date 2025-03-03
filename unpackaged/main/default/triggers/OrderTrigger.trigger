trigger OrderTrigger on Order(before insert, before update) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}