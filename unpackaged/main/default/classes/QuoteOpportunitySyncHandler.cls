public with sharing class QuoteOpportunitySyncHandler extends DomainLogicHandler {
    List<Id> opportunityIds = new List<Id>();

    List<SObjectField> quoteFields = new List<SObjectField>{
        SBQQ__Quote__c.ACV_Override__c,
        SBQQ__Quote__c.SBQQ__SubscriptionTerm__c,
        SBQQ__Quote__c.SBQQ__NetAmount__c,
        SBQQ__Quote__c.One_Time_Revenue__c
    };

    public override void check(SObject newObj, SObject oldObj) {
        if(TriggerUtility.isChanged(newObj, oldObj, quoteFields)) {
            opportunityIds.add((Id)newObj.get('SBQQ__Opportunity2__c'));
        }
    }
    
    public override void processRecords() {
        if(!System.isFuture() && !System.isBatch()) {
            updateOpportunities(opportunityIds);
        }
    }

    @future
    public static void updateOpportunities(List<Id> recordIds) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for(Id oppId : recordIds) {
            oppsToUpdate.add(new Opportunity(Id=oppId));
        }

        update oppsToUpdate;
    }
}