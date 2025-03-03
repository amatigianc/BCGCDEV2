/**
 * Tests for this method are found in LeadStamperTest
 */
public with sharing class LeadStageFieldStamper extends FieldStamper {
    public override void stamp(SObject sobj) {
        sobj.put(Lead.Stage_Date__c, Date.today());
    }
}