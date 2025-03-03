trigger QuoteLineTrigger on SBQQ__QuoteLine__c(before insert, before update) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}