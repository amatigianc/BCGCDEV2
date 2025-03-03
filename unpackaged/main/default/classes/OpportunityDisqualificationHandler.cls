public with sharing class OpportunityDisqualificationHandler extends DomainLogicHandler {
    Map<Id, String> accountIdDisqualifications = new Map<Id, String>();
    Set<Id> qualifiedAccountTeamAccountIds = new Set<Id>();
    public override void check(SObject newObj, SObject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;
        if (isQualified(newObj, oldObj)) {
            if (AccountDisqualifier.isReasonQualified(newOpp)) {
                accountIdDisqualifications.put(
                    newOpp.AccountId,
                    newOpp.Qualified_Out_Reason__c
                );
            }
            qualifiedAccountTeamAccountIds.add(newOpp.AccountId);
            newOpp.CloseDate = Date.Today();
        }
    }

    public override void processRecords() {
        DisqualifiedOppAccountTeamProcessor.removeMembership(
            qualifiedAccountTeamAccountIds
        );
        AccountDisqualifier.process(accountIdDisqualifications);
    }

    private Boolean isQualified(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(
                newObj,
                oldObj,
                Opportunity.StageName
            ) &&
            (String) newObj.get(Opportunity.StageName) == '0 - Disqualified';
    }
}