public with sharing class OpportunityOwnerHandler extends DomainLogicHandler {
    List<Opportunity> qualifiedOpps = new List<Opportunity>();
    List<Id> accIds = new List<Id>();

    static Id addOnRecordType = RecordTypeUtility.getId(
        Opportunity.getSObjectType(),
        'Add-On'
    );

    public override void check(SObject newObj) {
        if (isQualified(newObj)) {
            qualifiedOpps.add((Opportunity) newObj);
            accIds.add((Id) newObj.get(Opportunity.AccountId));
        }
    }

    public override void processRecords() {
        if (!qualifiedOpps.isEmpty()) {
            Map<Id, Account> accounts = new Map<Id, Account>(
                [
                    SELECT Id, OwnerId
                    FROM Account
                    WHERE Id IN :accIds
                ]
            );

            for (Opportunity opp : qualifiedOpps) {
                opp.OwnerId = accounts.get(opp.AccountId).OwnerId;
            }
        }
    }

    Boolean isQualified(SObject newObj) {
        return newObj.get(Opportunity.RecordTypeId) == addOnRecordType;
    }
}