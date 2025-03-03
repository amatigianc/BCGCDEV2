trigger ProductActionTrigger on SBQQ__ProductAction__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}