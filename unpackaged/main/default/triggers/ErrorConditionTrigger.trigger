trigger ErrorConditionTrigger on SBQQ__ErrorCondition__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}