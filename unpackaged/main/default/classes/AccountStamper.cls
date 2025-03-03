/**
 * Tests for this class are found in AccountStamperTest
 */
public with sharing class AccountStamper extends DomainLogicHandler {
    FieldStamperUtility stamper = new FieldStamperUtility(
        new Map<SObjectField, FieldStamper>{
            Account.X6sense_Account_Buying_Stage__c => new AccountBuyingStageFieldStamper(),
            Account.X6QA__c => new AccountLast6QAStamper()
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