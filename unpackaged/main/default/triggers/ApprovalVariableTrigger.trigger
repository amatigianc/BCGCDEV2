trigger ApprovalVariableTrigger on sbaa__ApprovalVariable__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}