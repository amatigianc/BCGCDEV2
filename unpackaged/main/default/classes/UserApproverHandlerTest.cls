@IsTest
public with sharing class UserApproverHandlerTest {
    @TestSetup
    static void makeData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        User svpUser = new User(
            FirstName = 'SVP',
            LastName = 'User',
            Email = 'svp.user@example.com',
            UserName = 'svp.user@example.com',
            Alias = 'svpusr',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );

        insert svpUser;

        User vpUser = new User(
            FirstName = 'VP',
            LastName = 'User',
            Email = 'vp.user@example.com',
            UserName = 'vp.user@example.com',
            Alias = 'vpusr',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ManagerId = svpUser.Id
        );

        insert vpUser;

        User dirUser = new User(
            FirstName = 'Director',
            LastName = 'User',
            Email = 'dir.user@example.com',
            UserName = 'dir.user@example.com',
            Alias = 'dirusr',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ManagerId = vpUser.Id
        );

        insert dirUser;

        User managerUser = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager.user@example.com',
            UserName = 'manager.user@example.com',
            Alias = 'mgrusr',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ManagerId = dirUser.Id
        );

        insert managerUser;

        User endUser = new User(
            FirstName = 'End',
            LastName = 'User',
            Email = 'end.user@example.com',
            UserName = 'end.user@example.com',
            Alias = 'endusr',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ManagerId = managerUser.Id
        );

        insert endUser;
    }

    @IsTest
    public static void testUserManagerApprover() {
        User managerUser = [
            SELECT
                Id,
                Director_Approver__r.FirstName,
                VP_Approver__r.FirstName,
                SVP_Approver__r.FirstName
            FROM User
            WHERE Username = 'manager.user@example.com'
        ];
        User vpUser = [
            SELECT Id
            FROM User
            WHERE Username = 'vp.user@example.com'
        ];

        //validate the inserts worked
        System.assertEquals('VP', managerUser.Director_Approver__r.FirstName);
        System.assertEquals('SVP', managerUser.VP_Approver__r.FirstName);
        System.assertEquals(null, managerUser.SVP_Approver__r?.FirstName);

        Test.startTest();
        managerUser.ManagerId = vpUser.Id;
        update managerUser;
        Test.stopTest();

        managerUser = [
            SELECT
                Id,
                Director_Approver__r.FirstName,
                VP_Approver__r.FirstName,
                SVP_Approver__r.FirstName
            FROM User
            WHERE Id = :managerUser.Id
        ];
        User subordinateUser = [
            SELECT
                Id,
                Director_Approver__r.FirstName,
                VP_Approver__r.FirstName,
                SVP_Approver__r.FirstName
            FROM User
            WHERE ManagerId = :managerUser.Id
        ];

        //validate the updates
        System.assertEquals('SVP', managerUser.Director_Approver__r.FirstName);
        System.assertEquals(null, managerUser.VP_Approver__r?.FirstName);
        System.assertEquals(null, managerUser.SVP_Approver__r?.FirstName);

        //check end user to make sure it updated
        System.assertEquals(
            'VP',
            subordinateUser.Director_Approver__r.FirstName
        );
        System.assertEquals('SVP', subordinateUser.VP_Approver__r?.FirstName);
        System.assertEquals(null, subordinateUser.SVP_Approver__r?.FirstName);
    }
}