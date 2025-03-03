trigger ProductRuleTrigger on SBQQ__ProductRule__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}