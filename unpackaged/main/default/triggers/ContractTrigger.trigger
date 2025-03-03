trigger ContractTrigger on Contract(before insert, before update) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}