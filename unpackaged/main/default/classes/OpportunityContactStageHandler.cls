public with sharing class OpportunityContactStageHandler extends DomainLogicHandler {
    List<Id> contactIds = new List<Id>();
    public override void check(SObject newObj) {
        Opportunity newOpp = (Opportunity) newObj;

        if (isQualified(newOpp)) {
            contactIds.add(newOpp.ContactId);
        }
    }

    public override void processRecords() {
        if (!contactIds.isEmpty()) {
            List<Contact> contacts = [
                SELECT Id, Stage__C
                FROM Contact
                WHERE Id IN :contactIds
            ];
            for (Contact contact : contacts) {
                contact.Stage__c = 'Opportunity';
            }

            update contacts;
        }
    }

    Boolean isQualified(Opportunity newOpp) {
        return newOpp.ContactId != null && isRecordTypeQualified(newOpp);
    }

    Boolean isRecordTypeQualified(Opportunity newOpp) {
        return newOpp.Deal_Type__c == 'New Business' ||
            newOpp.Deal_Type__c == 'Add-On' ||
            newOpp.Deal_Type__c == 'Renewal Growth';
    }
}