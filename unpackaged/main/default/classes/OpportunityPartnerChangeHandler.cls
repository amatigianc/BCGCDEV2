public with sharing class OpportunityPartnerChangeHandler {
    static List<Id> customerIds;
    static List<Id> partnerIds;
    static List<String> partnerTypes;
    static Map<String, Partner_Relationship__c> existingPartnerRelationships;
    static Map<String, Opportunity> existingOpps;

    public static void processEvents(
        List<Opportunity_Partner_Change__e> events
    ) {
        parseEventData(events);
        List<Partner_Relationship__c> deprecatedRelationships = new List<Partner_Relationship__c>();
        for (String key : existingPartnerRelationships.keySet()) {
            if (!existingOpps.containsKey(key)) {
                deprecatedRelationships.add(
                    existingPartnerRelationships.get(key)
                );
            }
        }

        delete deprecatedRelationships;
    }

    private static void parseEventData(
        List<Opportunity_Partner_Change__e> events
    ) {
        customerIds = new List<Id>();
        partnerIds = new List<Id>();
        partnerTypes = new List<String>();

        for (Opportunity_Partner_Change__e event : events) {
            customerIds.add(event.Customer_Id__c);
            partnerIds.add(event.Partner_Id__c);
            partnerTypes.add(event.Partner_Type__c);
        }

        setExistingPartnerRelationships();
        setExistingOpps();
    }

    private static void setExistingPartnerRelationships() {
        existingPartnerRelationships = new Map<String, Partner_Relationship__c>();
        List<Partner_Relationship__c> relationships = [
            SELECT Id, Customer_Account__c, Partner_Account__c, Type__c
            FROM Partner_Relationship__c
            WHERE
                Customer_Account__c IN :customerIds
                AND Partner_Account__c IN :partnerIds
                AND Type__c IN :partnerTypes
        ];

        for (Partner_Relationship__c relationship : relationships) {
            String key =
                String.valueOf(relationship.Customer_Account__c) +
                String.valueOf(relationship.Partner_Account__c) +
                relationship.Type__c;
            existingPartnerRelationships.put(key, relationship);
        }
    }

    private static void setExistingOpps() {
        existingOpps = new Map<String, Opportunity>();

        List<Opportunity> opps = [
            SELECT Id, AccountId, Partner__c, Partner_Type__c
            FROM Opportunity
            WHERE
                AccountId IN :customerIds
                AND Partner__c IN :partnerIds
                AND Partner_Type__c IN :partnerTypes
        ];

        for (Opportunity opp : opps) {
            String key =
                String.valueOf(opp.AccountId) +
                String.valueOf(opp.Partner__c) +
                opp.Partner_Type__c;
            existingOpps.put(key, opp);
        }
    }
}