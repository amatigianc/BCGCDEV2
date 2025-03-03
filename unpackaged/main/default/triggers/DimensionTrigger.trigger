trigger DimensionTrigger on SBQQ__Dimension__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}