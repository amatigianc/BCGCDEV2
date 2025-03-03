trigger ProductTrigger on Product2 (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}