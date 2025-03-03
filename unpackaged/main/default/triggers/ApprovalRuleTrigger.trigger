trigger ApprovalRuleTrigger on sbaa__ApprovalRule__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}