trigger EmailTemplateTrigger on sbaa__EmailTemplate__c (before insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}