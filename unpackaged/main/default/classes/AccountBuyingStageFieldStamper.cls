/**
 * Tests for this class are found in AccountStamperTest
 */
public with sharing class AccountBuyingStageFieldStamper extends FieldStamper {
    public override void stamp(SObject sobj) {
        Account account = (Account) sobj;
        switch on account.X6sense_Account_Buying_Stage__c {
            when 'Awareness' {
                account.X6sense_Stage_Awareness__c = Date.today();
            }
            when 'Consideration' {
                account.X6sense_Stage_Consideration__c = Date.today();
            }
            when 'Decision' {
                account.X6sense_Stage_Decision__c = Date.today();
            }
            when 'Purchase' {
                account.X6sense_Stage_Purchase__c = Date.today();
            }
        }
    }
}