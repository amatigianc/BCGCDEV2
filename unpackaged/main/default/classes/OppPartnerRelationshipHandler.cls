/**
 * Most of this class' functionality is validated in OpportunityPartnerChangeHandlerTest,
 * with the exception of the publishing of the Opportunity_Partner_Change__e events, which
 * is validated as part of OpportunityPartnerChangeHandlerTest/
 */
public with sharing class OppPartnerRelationshipHandler extends DomainLogicHandler {
    List<Id> customerIds = new List<Id>();
    List<Id> partnerIds = new List<Id>();
    List<String> partnerTypes = new List<String>();
    Map<String, Opportunity> qualifiedOppsMap = new Map<String, Opportunity>();
    List<Opportunity_Partner_Change__e> oppPartnerChangeEvents = new List<Opportunity_Partner_Change__e>();

    public override void check(Sobject newObj) {
        Opportunity newOpp = (Opportunity) newObj;
        if (isQualified(newOpp)) {
            addQualifiedData(newOpp);
        }
    }

    public override void check(Sobject newObj, sobject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;
        Opportunity oldOpp = (Opportunity) oldObj;
        if (isQualified(newOpp, oldOpp)) {
            addQualifiedData(newOpp);
        }
    }

    public override void processRecords() {
        filterExistingRelationships();
        createPartnerRelationshipRecords();
        if (!oppPartnerChangeEvents.isEmpty()) {
            Eventbus.publish(oppPartnerChangeEvents);
        }
    }

    private void addQualifiedData(Opportunity newOpp) {
        customerIds.add(newOpp.AccountId);
        partnerIds.add(newOpp.Partner__c);
        partnerTypes.add(newOpp.Partner_Type__c);

        String key =
            String.valueOf(newOpp.AccountId) +
            newOpp.Partner__c +
            newOpp.Partner_Type__c;
        qualifiedOppsMap.put(key, newOpp);
    }

    private Boolean isQualified(Opportunity newOpp) {
        return newOpp.Partner__c != null;
    }

    private Boolean isQualified(Opportunity newOpp, Opportunity oldOpp) {
        return isChanged(newOpp, oldOpp) && isQualified(newOpp);
    }

    private Boolean isChanged(Opportunity newOpp, Opportunity oldOpp) {
        if (
            newOpp.Partner__c != oldOpp.Partner__c ||
            newOpp.Partner_Type__c != oldOpp.Partner_Type__c
        ) {
            oppPartnerChangeEvents.add(
                new Opportunity_Partner_Change__e(
                    Opportunity_Id__c = oldOpp.Id,
                    Customer_Id__c = oldOpp.AccountId,
                    Partner_Id__c = oldOpp.Partner__c,
                    Partner_Type__c = oldOpp.Partner_Type__c
                )
            );
            return true;
        }
        return false;
    }

    private void filterExistingRelationships() {
        List<Partner_Relationship__c> partnerRelationships = [
            SELECT Id, Partner_Account__c, Customer_Account__c, Type__c
            FROM Partner_Relationship__c
            WHERE
                Partner_Account__c IN :partnerIds
                AND Customer_Account__c IN :customerIds
                AND Type__c IN :partnerTypes
        ];

        for (
            Partner_Relationship__c partnerRelationship : partnerRelationships
        ) {
            String key =
                String.valueOf(partnerRelationship.Customer_Account__c) +
                partnerRelationship.Partner_Account__c +
                partnerRelationship.Type__c;
            qualifiedOppsMap.remove(key);
        }
    }

    private void createPartnerRelationshipRecords() {
        List<Partner_Relationship__c> partnerRelationships = new List<Partner_Relationship__c>();
        for (Opportunity opps : qualifiedOppsMap.values()) {
            Partner_Relationship__c partnerRecord = new Partner_Relationship__c(
                Partner_Account__c = opps.Partner__c,
                Customer_Account__c = opps.AccountId,
                Type__c = opps.Partner_Type__c,
                Active__c = true
            );
            partnerRelationships.add(partnerRecord);
        }

        insert partnerRelationships;
    }
}