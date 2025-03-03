@isTest
public with sharing class StageZeroExistingOppValidationTest {
    @TestSetup
    static void makeData() {
        Opportunity leadOpp = OpportunityTestFactory.getStageZeroOpp();
        leadOpp.LeadSource = 'QA';
        leadOpp.CloseDate = Date.today().addDays(2);
        insert leadOpp;
    }

    @isTest
    static void testStopBdrFromCreatingNewStageZero() {
        Opportunity leadOpp = [
            SELECT Id, AccountId, ContactId
            FROM Opportunity
            WHERE LeadSource = 'QA' AND CloseDate = :Date.today().addDays(2)
            LIMIT 1
        ];

        Database.SaveResult result;
        Opportunity newLeadOpp = OpportunityTestFactory.getStageZeroStubOpp();
        newLeadOpp.AccountId = leadOpp.AccountId;
        newLeadOpp.ContactId = leadOpp.ContactId;

        result = Database.insert(newLeadOpp, false);

        System.assert(
            !result.isSuccess(),
            'New Opportunity was created when an existing QA exists.'
        );
        System.assertEquals(
            'An existing open Stage Zero Opportunity exists for this Account.',
            result.getErrors()[0].getMessage(),
            'Incorrect error message returned.'
        );
    }
}