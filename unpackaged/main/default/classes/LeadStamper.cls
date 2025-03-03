public with sharing class LeadStamper extends DomainLogicHandler {
    FieldStamperUtility stamper = new FieldStamperUtility(
        new Map<SObjectField, FieldStamper>{
            Lead.Stage__c => new LeadStageFieldStamper()
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