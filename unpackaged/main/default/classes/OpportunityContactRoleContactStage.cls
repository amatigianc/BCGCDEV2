public with sharing class OpportunityContactRoleContactStage extends DomainLogicHandler {
    List<Id> contacts = new List<Id>();
    List<Id> opps = new List<Id>();
    Map<Id, List<Id>> oppcontactIdMap = new Map<Id, List<Id>>();

    public override void check(SObject newObject) {
        OpportunityContactRole newRole = (OpportunityContactRole) newObject;

        contacts.add(newRole.ContactId);

        if (!oppContactIdMap.containskey(newRole.OpportunityId)) {
            oppContactIdMap.put(newRole.OpportunityId, new List<Id>());
        }
        oppContactIdMap.get(newRole.OpportunityId).add(newRole.ContactId);
    }

    public override void processRecords() {
        List<Opportunity> workingOpps = [
            SELECT Id, Deal_Type__c
            FROM Opportunity
            WHERE
                Id IN :oppContactIdMap.keyset()
                AND Deal_Type__c IN ('New Business', 'Add-On', 'Renewal Growth')
        ];
        Map<Id, Contact> contactRecords = new Map<Id, Contact>(
            [
                SELECT Id, Stage__c
                FROM Contact
                WHERE Id IN :contacts AND Stage__c != 'Opportunity'
            ]
        );
        for (Opportunity newOpp : workingOpps) {
            List<Id> contactIds = oppcontactIdMap.get(newopp.Id);
            for (Id contactId : contactIds) {
                if (contactRecords.containsKey(contactId)) {
                    Contact contact = contactRecords.get(contactId);
                    contact.Stage__c = 'Opportunity';
                }
            }
        }
        update contactRecords.values();
    }
}