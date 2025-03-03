public with sharing class DisqualifiedOppAccountTeamProcessor {
    public static void removeMembership(Set<Id> accountIds) {
        if (System.isFuture() || System.isBatch()) {
            List<AccountTeamMember> accountTeamMembers = [
                SELECT Id
                FROM AccountTeamMember
                WHERE
                    AccountId IN :accountIds
                    AND Account.Named_Account__c = FALSE
            ];
            try {
                delete accountTeamMembers;
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            return;
        }

        removeMembershipAsync(accountIds);
    }

    @future
    public static void removeMembershipAsync(Set<Id> accountIds) {
        removeMembership(accountIds);
    }
}