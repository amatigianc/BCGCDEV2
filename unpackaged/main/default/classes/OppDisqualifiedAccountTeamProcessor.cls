public with sharing class OppDisqualifiedAccountTeamProcessor extends DomainLogicHandler {
    List<Id> accountIds = new List<Id>();
    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            accountIds.add((Id) newObj.get(Opportunity.AccountId));
        }
    }

    public override void processRecords() {
        List<AccountTeamMember> accountTeamMembers = [
            SELECT Id
            FROM AccountTeamMember
            WHERE AccountId IN :accountIds AND Account.Named_Account__c = TRUE
        ];
        try {
            delete accountTeamMembers;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
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