public with sharing class AccountLast6QAStamper extends FieldStamper {
    public override void stamp(SObject sobj) {
        Account account = (Account) sobj;
        if (account.X6QA__c) {
            account.X6sense_Account_6QA_Start_Date__c = Date.today();
        } else {
            account.X6sense_Account_6QA_End_Date__c = Date.today();
        }
    }
}