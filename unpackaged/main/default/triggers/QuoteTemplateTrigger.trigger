trigger QuoteTemplateTrigger on SBQQ__QuoteTemplate__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}