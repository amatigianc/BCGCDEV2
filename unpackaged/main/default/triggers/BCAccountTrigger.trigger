trigger BCAccountTrigger on BCAccount__c(before insert) {
    new DomainHandlerUtility().process();
}