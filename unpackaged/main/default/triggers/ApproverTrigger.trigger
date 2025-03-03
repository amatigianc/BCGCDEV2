trigger ApproverTrigger on sbaa__Approver__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}