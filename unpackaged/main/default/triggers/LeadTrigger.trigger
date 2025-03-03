trigger LeadTrigger on Lead(before insert, before update, after update) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}