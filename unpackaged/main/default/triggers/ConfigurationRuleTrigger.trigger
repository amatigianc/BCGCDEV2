trigger ConfigurationRuleTrigger on SBQQ__ConfigurationRule__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}