@isTest
public with sharing class OpportunityQualificationHandlerTest {
    @TestSetup
    static void makeData() {
        UserRole bdrRole = [SELECT Id FROM UserRole WHERE Name = 'BDR' LIMIT 1];

        List<User> users = TestUserProvisioner.getNewUsers(2);
        users[0].UserRoleId = bdrRole.Id;

        insert users;

        TestUserProvisioner bdrProvisioner = new TestUserProvisioner(
            users[0].Id
        );

        bdrProvisioner.setPermissionSetGroup('Sales Rep');
        bdrProvisioner.assignPermissions();

        TestUserProvisioner nonBdrProvisioner = new TestUserProvisioner(
            users[1].Id
        );
        nonBdrProvisioner.setPermissionSetGroup('Sales Rep');
        nonBdrProvisioner.assignPermissions();
    }

    @isTest
    static void testQualifyAsBdr() {
        User bdr = [
            SELECT Id
            FROM User
            WHERE
                LastName = 'TestUserProvisioner'
                AND UserRole.Name = 'BDR'
                AND IsActive = TRUE
            LIMIT 1
        ];
        List<Opportunity> opps;
        System.runAs(bdr) {
            opps = OpportunityTestFactory.getStageZeroOpps(2);
            opps[0].OwnerId = bdr.Id;
            opps[1].OwnerId = bdr.Id;
            insert opps;
        }

        opps[0].StageName = '0 - Meeting Scheduled';
        opps[1].StageName = '0 - Disqualified';
        opps[1]
            .Qualified_Out_Reason__c = Opportunity.Qualified_Out_Reason__c.getDescribe()
                .getPicklistValues()[0]
            .getValue();

        System.runAs(bdr) {
            update opps;
        }

        Test.startTest();

        opps[0].StageName = '0 - Meeting Occurred';
        System.runAs(bdr) {
            update opps[0];
        }

        Test.stopTest();

        opps = [
            SELECT Qualifying_User__c, Qualifier_Role__c
            FROM Opportunity
            WHERE Id = :opps
        ];

        for (Opportunity opp : opps) {
            System.assertEquals(
                bdr.Id,
                opp.Qualifying_User__c,
                'BDR was not correctly assigned as the Qualifying User.'
            );
            System.assertEquals(
                'BDR',
                opp.Qualifier_Role__c,
                'BDR was not correctly assigned as the Qualifying User.'
            );
        }
    }

    @isTest
    static void testCreateByNonBdr() {
        User nonBdr = [
            SELECT Id
            FROM User
            WHERE
                LastName = 'TestUserProvisioner'
                AND UserRole.Name != 'BDR'
                AND IsActive = TRUE
            LIMIT 1
        ];
        List<Opportunity> opps;
        System.runAs(nonBdr) {
            opps = OpportunityTestFactory.getStageZeroOpps(2);
            opps[0].OwnerId = nonBdr.Id;
            opps[1].OwnerId = nonBdr.Id;
            insert opps;
        }

        opps[0].StageName = '0 - Meeting Scheduled';
        opps[1].StageName = '0 - Disqualified';
        opps[1]
            .Qualified_Out_Reason__c = Opportunity.Qualified_Out_Reason__c.getDescribe()
                .getPicklistValues()[0]
            .getValue();

        System.runAs(nonBdr) {
            update opps;
        }

        Test.startTest();

        opps[0].StageName = '0 - Meeting Occurred';
        System.runAs(nonBdr) {
            update opps[0];
        }

        Test.stopTest();

        opps = [
            SELECT Qualifying_User__c, Qualifier_Role__c
            FROM Opportunity
            WHERE Id = :opps
        ];

        for (Opportunity opp : opps) {
            System.assertEquals(
                nonBdr.Id,
                opp.Qualifying_User__c,
                'BDR was not correctly assigned as the Qualifying User.'
            );
            System.assertEquals(
                'Sales Rep',
                opp.Qualifier_Role__c,
                'BDR was not correctly assigned as the Qualifying User.'
            );
        }
    }
}