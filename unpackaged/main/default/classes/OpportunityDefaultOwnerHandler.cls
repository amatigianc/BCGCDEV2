public with sharing class OpportunityDefaultOwnerHandler extends DomainLogicHandler {
    Set<Id> opportunityIds = new Set<Id>();
    public override void check(SObject newObj) {
        opportunityIds.add(newObj.Id);
    }
    
    public override void processRecords() {
        if(!opportunityIds.isEmpty() && !System.isFuture() && !System.isBatch()) {
            OpportunityDefaultSplitHandler.rectifyOpportunitySplits(opportunityIds);
        }
    }
}