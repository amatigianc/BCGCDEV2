public with sharing class OpportunityClosedWonOwnerHandler extends DomainLogicHandler {
    List<Opportunity> workset = new List<Opportunity>();
    List<Id> accountIds = new List<Id>();

    public override void check(Sobject newObj, sobject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;
        Opportunity oldOpp = (Opportunity) oldObj;
        if (isQualified(newOpp, oldOpp)) {
            workset.add(newOpp);
            accountIds.add(newOpp.AccountId);
        }
    }

    public override void processRecords() {
        setOpportunityOwner();
    }

    private Boolean isQualified(Opportunity newOpp, Opportunity oldOpp) {
        return (newOpp.StageName != oldOpp.StageName) &&
            (newOpp.StageName == 'Closed Won');
    }

    private Map<Id, Id> getAccountMgrIds() {
        List<AccountTeamMember> teamMembers = [
            SELECT Id, UserId, AccountId
            FROM AccountTeamMember
            WHERE
                AccountId IN :accountIds
                AND TeamMemberRole = 'Account Manager'
        ];

        Map<Id, Id> accountManagerIds = new Map<Id, Id>();
        for (AccountTeamMember teamMember : teamMembers) {
            accountManagerIds.put(teamMember.AccountId, teamMember.UserId);
        }
        return accountManagerIds;
    }

    private void setOpportunityOwner() {
        Map<Id, Id> accountManagerIds = getAccountMgrIds();

        for (Opportunity opportunity : workset) {
            if (accountManagerIds.containsKey(opportunity.AccountId)) {
                opportunity.OwnerId = accountManagerIds.get(
                    opportunity.AccountId
                );
            }
        }
    }
}