trigger ApprovalChainTrigger on sbaa__ApprovalChain__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}