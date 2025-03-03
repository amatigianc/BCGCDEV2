public with sharing class OpportunityClosedHandler extends DomainLogicHandler {
    List<Id> oppIds = new List<Id>();

    public override void check(SObject newObject, SObject oldObject) {
        Opportunity newOpp = (Opportunity) newObject;
        Opportunity oldOpp = (Opportunity) oldObject;
        if (isQualified(newOpp, oldOpp)) {
            oppIds.add(newOpp.Id);
        }
    }

    public override void processRecords() {
        List<OpportunityContactRole> roles = [
            SELECT Id, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds
        ];

        List<Id> contactIds = new List<Id>();
        for (OpportunityContactRole role : roles) {
            contactIds.add(role.ContactId);
        }

        List<Contact> contacts = [
            SELECT
                Id,
                (
                    SELECT Id
                    FROM OpportunityContactRoles
                    WHERE Opportunity.IsClosed = FALSE
                )
            FROM Contact
            WHERE Id IN :contactIds
        ];

        List<Contact> recycledContacts = new List<Contact>();
        for (Contact contact : contacts) {
            if (contact.OpportunityContactRoles.isEmpty()) {
                contact.Stage__c = 'Recycled';
                recycledContacts.add(contact);
            }
        }
        update recycledContacts;
    }

    Boolean isQualified(Opportunity newOpp, Opportunity oldOpp) {
        return newOpp.isClosed &&
            isChanged(newOpp, oldOpp) &&
            //newOpp.ContactId != null &&
            isDealTypeQualified(newOpp);
    }

    Boolean isDealTypeQualified(Opportunity newOpp) {
        return newOpp.Deal_Type__c == 'New Business' ||
            newOpp.Deal_Type__c == 'Add-On' ||
            newOpp.Deal_Type__c == 'Renewal Growth';
    }

    Boolean isChanged(Opportunity newOpp, Opportunity oldOpp) {
        return newOpp.StageName != oldOpp.StageName;
    }
}