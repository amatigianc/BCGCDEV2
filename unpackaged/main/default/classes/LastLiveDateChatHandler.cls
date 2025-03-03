/**
 * Triggers on AFTER_UPDATE of Lead and Contact
 * Sets the value of the records' Last_Live_Chat_Date__c on related
 * CampaignMember records' Response_Date__c field.
 */
public with sharing class LastLiveDateChatHandler extends DomainLogicHandler {
    Map<Id, Date> lastLiveChatDates = new Map<Id, Date>();
    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            lastLiveChatDates.put(
                newObj.Id,
                ((Datetime) newObj.get('Last_Live_Chat_Date__c')).date()
            );
        }
    }

    public override void processRecords() {
        if (!lastLiveChatDates.isEmpty()) {
            List<CampaignMember> campaignMembers = getCampaignMembers();

            for (CampaignMember member : campaignMembers) {
                setResponseDate(member);
            }

            update campaignMembers;
        }
    }

    void setResponseDate(CampaignMember member) {
        member.Response_Date__c = lastLiveChatDates.containsKey(
                member.ContactId
            )
            ? lastLiveChatDates.get(member.ContactId)
            : lastLiveChatDates.get(member.LeadId);
    }

    List<CampaignMember> getCampaignMembers() {
        return [
            SELECT
                Id,
                (
                    SELECT Id, ContactId, LeadId, Response_Date__c
                    FROM CampaignMembers
                    WHERE
                        ContactId IN :lastLiveChatDates.keySet()
                        OR LeadId IN :lastLiveChatDates.keySet()
                )
            FROM Campaign
            WHERE
                ParentId != NULL
                AND Status = 'In Progress'
                AND Campaign_Offer_Type__c = :Label.Campaign_Offer_Type_Direct_Response
                AND Name LIKE 'Conversations from Drift%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ]
        .CampaignMembers;
    }

    Boolean isQualified(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(
            newObj,
            oldObj,
            'Last_Live_Chat_Date__c'
        );
    }
}