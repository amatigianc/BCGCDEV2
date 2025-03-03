/**
 * Triggers on BEFORE_INSERT of CampaignMember
 * Stamps the value of the CampaignMember's Response_Date__c field
 * with the value of the Last_Live_Chat_Date__c field of related
 * Contacts or Leads on related CampaignMembers.
 *
 * Test coverage is found in LastLiveDateChatHandlerTest.
 */
public with sharing class DirectResponseHandler extends DomainLogicHandler {
    List<Id> leadIds = new List<Id>();
    List<Id> contactIds = new List<Id>();
    List<Id> campaignIds = new List<Id>();
    Map<Id, SObject> relatedRecords = new Map<Id, SObject>();
    List<CampaignMember> newMembers = new List<CampaignMember>();

    public override void check(SObject newObj) {
        addToRelatedIds((CampaignMember) newObj);
        newMembers.add((CampaignMember) newObj);
    }

    public override void processRecords() {
        setRelatedMaps();
        Set<Id> qualifiedCampaignIds = getQualifiedCampaignIds();
        for (CampaignMember member : newMembers) {
            if (qualifiedCampaignIds.contains(member.CampaignId)) {
                Id relatedId = member.LeadId != null
                    ? member.LeadId
                    : member.ContactId;
                member.Response_Date__c = ((Datetime) relatedRecords.get(
                            relatedId
                        )
                        ?.get('Last_Live_Chat_Date__c'))
                    ?.date();
            }
        }
    }

    Set<Id> getQualifiedCampaignIds() {
        return new Map<Id, Campaign>(
                [
                    SELECT Id, Status, Campaign_Offer_Type__c, ParentId
                    FROM Campaign
                    WHERE
                        Campaign_Offer_Type__c = :Label.Campaign_Offer_Type_Direct_Response
                        AND Name LIKE 'Conversations from Drift%'
                        AND ParentId != NULL
                        AND Status = 'In Progress'
                        AND Id IN :campaignIds
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ]
            )
            .keySet();
    }

    void addToRelatedIds(CampaignMember newMember) {
        if (newMember.ContactId != null) {
            contactIds.add(newMember.ContactId);
        }

        if (newMember.LeadId != null) {
            leadIds.add(newMember.LeadId);
        }
        campaignIds.add(newMember.CampaignId);
    }

    void setRelatedMaps() {
        if (!contactIds.isEmpty()) {
            relatedRecords.putAll(
                [
                    SELECT Id, Last_Live_Chat_Date__c
                    FROM Contact
                    WHERE Id IN :contactIds AND Last_Live_Chat_Date__c != NULL
                ]
            );
        }

        if (!leadIds.isEmpty()) {
            relatedRecords.putAll(
                [
                    SELECT ID, Last_Live_Chat_Date__c
                    FROM Lead
                    WHERE Id IN :leadIds AND Last_Live_Chat_Date__c != NULL
                ]
            );
        }
    }
}