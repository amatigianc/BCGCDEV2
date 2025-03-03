@isTest
public with sharing class OpportunityDisqualificationHandlerTest {
    private static List<PicklistEntry> qualifiedOutReasons = Opportunity.Qualified_Out_Reason__c.getDescribe()
        .getPicklistValues();

    @TestSetup
    static void makeData() {
        List<Opportunity> opps = OpportunityTestFactory.getStageZeroOpps(
            qualifiedOutReasons.size()
        );

        insert opps;

        User bdr = TestUserProvisioner.getNewUser();
        insert bdr;

        List<AccountTeamMember> teamMembers = new List<AccountTeamMember>();
        for (Opportunity opp : opps) {
            teamMembers.add(
                new AccountTeamMember(
                    UserId = bdr.Id,
                    TeamMemberRole = 'Business Development Rep',
                    AccountId = opp.AccountId
                )
            );
        }
        insert teamMembers;

        Account namedAccount = new Account(
            Id = opps[0].AccountId,
            Named_Account__c = true
        );
        update namedAccount;
    }

    @isTest
    private static void testCleanAccountTeam() {
        List<Id> accountIds = new List<Id>();
        List<Opportunity> opps = [
            SELECT Id, AccountId, StageName
            FROM Opportunity
            WHERE RecordType.Name = 'Lead' AND IsClosed = FALSE
            LIMIT :qualifiedOutReasons.size()
        ];
        for (Integer i = 0; i < qualifiedOutReasons.size(); i++) {
            opps[i].StageName = '0 - Disqualified';
            opps[i].Qualified_Out_Reason__c = qualifiedOutReasons[i].getValue();
            accountIds.add(opps[i].AccountId);
        }

        Test.startTest();

        update opps;

        Test.stopTest();

        List<Account> accounts = [
            SELECT Id, Named_Account__c, (SELECT Id FROM AccountTeamMembers)
            FROM Account
            WHERE Id IN :accountIds
        ];
        for (Account account : accounts) {
            Boolean expected = account.Named_Account__c;
            System.assertEquals(
                expected,
                !account.AccountTeamMembers.isEmpty(),
                'Account Team Members were incorrectly processed.'
            );
        }
    }

    @isTest
    private static void testKeepAccountDisqualified() {
        List<Opportunity> opps = [
            SELECT Id, StageName, Qualified_Out_Reason__c
            FROM Opportunity
            WHERE RecordType.Name = 'Lead' AND IsClosed = FALSE
        ];
        for (Integer i = 0; i < opps.size(); i++) {
            opps[i].StageName = '0 - Disqualified';
            opps[i].Qualified_Out_Reason__c = qualifiedOutReasons[i].getValue();
        }

        Test.startTest();

        update opps;

        Test.stopTest();

        List<Log__c> logs = [SELECT Id, Text__c FROM Log__c];
        System.assert(true, logs.isEmpty());

        List<String> qualifiedReasons = new List<String>{
            'Not a business',
            'Out of business',
            'Never a fit',
            'Competitor',
            'Vendor',
            'Partner'
        };

        opps = [
            SELECT Id, Account.Keep_Disqualified__c, Qualified_Out_Reason__c
            FROM Opportunity
            WHERE RecordType.Name = 'Lead' AND StageName = '0 - Disqualified'
        ];
        for (Opportunity opp : opps) {
            System.assertEquals(
                qualifiedReasons.contains(opp.Qualified_Out_Reason__c),
                opp.Account.Keep_Disqualified__c,
                'The related Account\'s Keep Disqualified field was not correctly set for Qualified Out Reason: ' +
                opp.Qualified_Out_Reason__c
            );
        }
    }
    @isTest
    private static void testClosedDateUpdate() {
        List<Opportunity> opps = [
            SELECT Id, StageName, Qualified_Out_Reason__c
            FROM Opportunity
            WHERE RecordType.Name = 'Lead' AND IsClosed = FALSE
            LIMIT 3
        ];
        for (Integer i = 0; i < opps.size(); i++) {
            opps[i].CloseDate = Date.today().addDays(30);
        }

        opps[0].StageName = '0 - Meeting Pending';
        opps[1].StageName = '0 - Meeting Scheduled';
        opps[2].StageName = '0 - Meeting Scheduled';

        update opps;

        opps[2].StageName = '0 - Meeting Occurred';

        update opps[2];

        for (Integer i = 0; i < opps.size(); i++) {
            opps[i].StageName = '0 - Disqualified';
            opps[i].Qualified_Out_Reason__c = qualifiedOutReasons[i].getValue();
        }

        Test.startTest();

        update opps;

        Test.stopTest();

        opps = [
            SELECT Id, CloseDate
            FROM Opportunity
            WHERE RecordType.Name = 'Lead' AND StageName = '0 - Disqualified'
        ];

        for (Opportunity opp : opps) {
            System.assertEquals(
                Date.today(),
                opp.CloseDate,
                'Opportunity CloseDate was not updated to todays date'
            );
        }
    }
}