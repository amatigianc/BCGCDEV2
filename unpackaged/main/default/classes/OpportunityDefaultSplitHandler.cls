public with sharing class OpportunityDefaultSplitHandler {
    static Map<String, List<String>> dealTypeToSplitTypeMap = new Map<String, List<String>>{
        'New Business' => new List<String>{ 'ACV', 'TCV' },
        'Add-On' => new List<String>{ 'ACV', 'TCV' },
        'Debook' => new List<String>{ 'ACV', 'TCV' },
        'Renewal Growth' => new List<String>{ 'ACV', 'TCV' },
        'Renewal' => new List<String>{ 'EMRR Value', 'MRR Commit Value' },
        'Early Renewal' => new List<String>{ 'EMRR Value', 'MRR Commit Value' }
    };

    static Set<String> teamMemberRoles = new Set<String>{
        'Opportunity Owner',
        'Account Executive',
        'Account Manager',
        'Customer Success Manager',
        'Channel Manager'
    };

    @future
    public static void rectifyOpportunitySplits(Set<Id> opportunityIds) {
        List<OpportunitySplit> splitsToInsert = new List<OpportunitySplit>();
        List<Opportunity> opportunities = getOpportunities(opportunityIds);
        Map<String, OpportunitySplitType> oppSplitTypeByNameMap = getOppSplitTypeMapByName();
        for (Opportunity opportunity : opportunities) {
            if (!dealTypeToSplitTypeMap.containsKey(opportunity.Deal_Type__c)) {
                continue;
            }

            List<OpportunityTeamMember> oppTeamMembers = opportunity.OpportunityTeamMembers;
            List<OpportunitySplit> oppSplits = opportunity.OpportunitySplits;

            for (OpportunityTeamMember oppTeamMember : oppTeamMembers) {
                if (!teamMemberRoles.contains(oppTeamMember.TeamMemberRole)) {
                    continue;
                }

                Boolean hasSplit = getHasSplit(oppSplits, oppTeamMember, dealTypeToSplitTypeMap.get(opportunity.Deal_Type__c));

                if (!hasSplit) {
                    splitsToInsert.addAll(
                        generateNewSplits(
                            oppTeamMember,
                            opportunity,
                            oppSplitTypeByNameMap
                        )
                    );
                }
            }
        }

        insert splitsToInsert;
    }

    private static List<OpportunitySplit> generateNewSplits(
        OpportunityTeamMember oppTeamMember,
        Opportunity opportunity,
        Map<String, OpportunitySplitType> oppSplitTypeByNameMap
    ) {
        List<OpportunitySplit> results = new List<OpportunitySplit>();
        List<String> splitTypesToCreate = dealTypeToSplitTypeMap.get(
            opportunity.Deal_Type__c
        );

        for (String splitTypeName : splitTypesToCreate) {
            OpportunitySplit oppSplit = new OpportunitySplit();
            oppSplit.OpportunityId = opportunity.Id;
            oppSplit.SplitOwnerId = oppTeamMember.UserId;
            oppSplit.SplitPercentage = 100.0;
            oppSplit.SplitTypeId = oppSplitTypeByNameMap.get(splitTypeName).Id;
            results.add(oppSplit);
        }

        return results;
    }

    private static Map<String, OpportunitySplitType> getOppSplitTypeMapByName() {
        List<OpportunitySplitType> opportunitySplitTypes = [
            SELECT Id, MasterLabel
            FROM OpportunitySplitType
            WHERE IsActive = TRUE
        ];

        Map<String, OpportunitySplitType> results = new Map<String, OpportunitySplitType>();

        for (OpportunitySplitType oppSplitType : opportunitySplitTypes) {
            results.put(oppSplitType.MasterLabel, oppSplitType);
        }

        return results;
    }

    private static List<Opportunity> getOpportunities(Set<Id> opportunityIds) {
        return [
            SELECT
                Id,
                Deal_Type__c,
                (
                    SELECT Id, TeamMemberRole, UserId, OpportunityId
                    FROM OpportunityTeamMembers
                ),
                (
                    SELECT
                        Id,
                        OpportunityId,
                        SplitOwnerId,
                        SplitPercentage,
                        SplitType.MasterLabel,
                        SplitTypeId
                    FROM OpportunitySplits
                )
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];
    }

    private static Boolean getHasSplit(List<OpportunitySplit> oppSplits, OpportunityTeamMember oppTeamMember, List<String> splitTypesToCheck) {
        Boolean results = false;

        for (OpportunitySplit oppSplit : oppSplits) {
            if (oppSplit.SplitOwnerId == oppTeamMember.UserId && splitTypesToCheck.contains(oppSplit.SplitType.MasterLabel)) {
                results = true;
                break;
            }
        }

        return results;
    }
}