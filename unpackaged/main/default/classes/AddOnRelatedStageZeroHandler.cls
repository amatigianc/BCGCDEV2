/**
 * This class is responsible for facilitating the syncing of data between existing
 * Opportunities with the "Lead" Record Type with newly created Opportunities with
 * the "Add-On" Record Type. After syncing, the Lead Opportunities are deleted.
 *
 * This is required as the existing "Convert" process for New Business Opportunities
 * is not possible for Add-Ons due to the requirement that they must originate from
 * Contracts that are amended.
 */
public with sharing class AddOnRelatedStageZeroHandler extends DomainLogicHandler {
    BCMap qualifiedOppsByAccountId = new BCMap('AccountId');

    public override void check(SObject newObj) {
        if (isQualified(newObj)) {
            qualifiedOppsByAccountId.put(newObj);
        }
    }

    public override void processRecords() {
        if (!qualifiedOppsByAccountId.isAllEmpty()) {
            BCMap existingLeadOpps = new BCMap(
                [
                    SELECT
                        Id,
                        AccountId,
                        Meeting_Occurred_Stage_Set_Date__c,
                        Meeting_Pending_Stage_Set_Date__c,
                        Meeting_Scheduled_Stage_Set_Date__c,
                        X6QA__c,
                        Named_Account__c,
                        Named_Account_Tier__c
                    FROM Opportunity
                    WHERE
                        IsClosed = FALSE
                        AND RecordType.Name = 'Lead'
                        AND AccountId IN :qualifiedOppsByAccountId.keyAllSet()
                ],
                'AccountId'
            );
            List<Add_On_Lead_Opp_Cleanup__e> events = new List<Add_On_Lead_Opp_Cleanup__e>();
            for (Id accountId : existingLeadOpps.keySet()) {
                for (
                    SObject addOnOpp : qualifiedOppsByAccountId.getAll(
                        accountId
                    )
                ) {
                    events.add(
                        new Add_On_Lead_Opp_Cleanup__e(
                            Opportunity_Id__c = existingLeadOpps.get(accountId)
                                .Id
                        )
                    );
                    setFields(addOnOpp, existingLeadOpps.get(accountId));
                }
            }

            EventBus.publish(events);
        }
    }

    Boolean isQualified(SObject newObj) {
        return RecordTypeUtility.getName(newObj) == 'Add-On';
    }

    void setFields(SObject addOnOpp, SObject leadOpp) {
        List<SObjectField> fields = new List<SObjectField>{
            Opportunity.Meeting_Occurred_Stage_Set_Date__c,
            Opportunity.Meeting_Pending_Stage_Set_Date__c,
            Opportunity.Meeting_Scheduled_Stage_Set_Date__c,
            Opportunity.X6QA__c
        };

        for (SObjectField field : fields) {
            addOnOpp.put(field, leadOpp.get(field));
        }

        addOnOpp.put(Opportunity.LeadSource, 'QA');
    }
}