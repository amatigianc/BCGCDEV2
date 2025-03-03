trigger OpportunityContactRoleTrigger on OpportunityContactRole(after insert) {
    DomainHandlerUtility handler = new DomainHandlerUtility();
    handler.process();
}