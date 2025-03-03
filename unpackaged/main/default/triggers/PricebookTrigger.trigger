trigger PricebookTrigger on Pricebook2 (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}