@isTest
public with sharing class OpportunityClientTerminationHandlerTest {
    @TestSetup
    static void makeData() {
        Account account = AccountTestFactory.getCustomer();
        account.Account_Stage__c = 'Customer';
        account.Name = 'OpportunityClientTerminationHandlerTest';
        insert account;

        Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
        opp.RecordTypeId = RecordTypeUtility.getId(
            Opportunity.getSObjectType(),
            'Add-On'
        );
        insert opp;
    }

    @isTest
    static void testUpdateAccounts() {
        Opportunity opp = [
            SELECT Id, AccountId, Client_Termination_Status__c
            FROM Opportunity
            WHERE Account.Name = 'OpportunityClientTerminationHandlerTest'
            LIMIT 1
        ];
        opp.Client_Termination_Status__c = 'Approved';

        Test.startTest();
        update opp;
        Test.stopTest();

        Account account = [
            SELECT Id, Account_Stage__c
            FROM Account
            WHERE Id = :opp.AccountId
        ];
        System.assertEquals(
            'Former',
            account.Account_Stage__c,
            'Account Stage was not set to Former.'
        );
    }
}