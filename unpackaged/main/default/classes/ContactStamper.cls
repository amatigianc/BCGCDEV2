public with sharing class ContactStamper extends DomainLogicHandler {
    FieldStamperUtility stamper = new FieldStamperUtility(
        new Map<SObjectField, FieldStamper>{
            Contact.Stage__c => new ContactStageFieldStamper()
        }
    );

    public override void check(SObject newObj) {
        stamper.qualifyRecord(newObj);
    }

    public override void check(SObject newObj, SObject oldObj) {
        stamper.qualifyRecord(newObj, oldObj);
    }

    public override void processRecords() {
        stamper.processStampers();
    }
}