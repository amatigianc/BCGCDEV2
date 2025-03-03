trigger ProductFeatureTrigger on SBQQ__ProductFeature__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}