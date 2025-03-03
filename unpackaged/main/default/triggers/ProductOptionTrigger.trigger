trigger ProductOptionTrigger on SBQQ__ProductOption__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}