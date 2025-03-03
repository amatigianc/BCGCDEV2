/**
 * Tests for this class are found in ContactStamperTest
 */
public with sharing class ContactStageFieldStamper extends FieldStamper {
    public override void stamp(SObject sobj) {
        sobj.put(Contact.Stage_Date__c, Date.today());
    }
}