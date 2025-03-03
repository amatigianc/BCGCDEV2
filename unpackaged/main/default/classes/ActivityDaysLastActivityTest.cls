@isTest
public with sharing class ActivityDaysLastActivityTest {
  @TestSetup
  static void makeRunningUsers() {
    UserRole salesRole = [
      SELECT Id
      FROM UserRole
      WHERE Name = 'Account Manager'
    ];

    UserRole marketingRole = [
      SELECT Id
      FROM UserRole
      WHERE Name = 'Marketing Operations'
    ];

    Profile marketingProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Marketing'
    ];

    List<User> users = TestUserProvisioner.getNewUsers(2);
    users[0].UserRoleId = salesRole.Id;
    users[0].FirstName = 'TEST SalesRelated';
    users[1].UserRoleId = marketingRole.id;
    users[1].FirstName = 'TEST NonSalesRelated';
    users[1].ProfileId = marketingProfile.Id;

    insert users;

    TestUserProvisioner salesWithPermission = new TestUserProvisioner(
      users[0].Id
    );

    List<PermissionSet> permissionSets = [
      SELECT Id, Name
      FROM PermissionSet
      WHERE Name = 'Creates_Sales_Activity'
    ];

    List<String> permissionSetName = new List<String>{ permissionSets[0].Name };
    salesWithPermission.setPermissions(permissionSetName);
    salesWithPermission.setPermissionSetGroup('Sales Rep');
    salesWithPermission.assignPermissions();
  }

  static void createData() {
    List<SObject> recordsToUpdate = new List<Sobject>();

    List<Contact> contacts = ContactTestFactory.getContacts(2);
    contacts[0].Salutation = 'Mr';
    contacts[0].Last_Sales_Activity_Date__c = null;
    contacts[1].Salutation = 'Mr';
    contacts[1].Last_Sales_Activity_Date__c = Date.newInstance(2013, 8, 1);

    recordsToUpdate.addAll(contacts);

    Lead leadrecord = LeadTestFactory.getLead();
    recordsToUpdate.add(leadrecord);

    insert recordsToUpdate;
  }

  @isTest
  static void processSalesRelatedTest() {
    List<SObject> recordsToUpdate = new List<SObject>();

    List<User> testUsers = [
      SELECT Id, FirstName
      FROM User
      WHERE FirstName LIKE 'TEST%SalesRelated'
      ORDER BY Firstname
    ];

    User salesWithPermission = testUsers[1];
    User nonSalesRelatedUser = testUsers[0];

    System.runAs(salesWithPermission) {
      createData();
    }

    recordstoUpdate.addAll(
      [
        SELECT Id, Last_Sales_Activity_Date__c
        FROM Contact
        WHERE LastName LIKE 'ContactTestFactory%'
      ]
    );

    recordsToUpdate.addAll(
      [
        SELECT Id, Last_Sales_Activity_Date__c
        FROM Lead
        WHERE LastName = 'LeadTestFactory'
      ]
    );

    Task phoneCall;

    phoneCall = new Task();
    phoneCall.Type = 'Call';
    phoneCall.ActivityDate = System.today();
    phoneCall.Subject = 'TEST';
    phoneCall.WhoId = (Id) recordsToUpdate[0].Id;
    phoneCall.Description = 'Log a call';

    System.runAs(salesWithPermission) {
      insert phoneCall;
    }

    List<SObject> recordsToVerify = new List<SOBject>();
    recordsToVerify.addAll(
      [
        SELECT Id, Last_Sales_Activity_Date__c
        FROM Contact
        WHERE LastName LIKE 'ContactTestFactory%'
      ]
    );

    recordsToVerify.addAll(
      [
        SELECT Id, Last_Sales_Activity_Date__c
        FROM Lead
        WHERE LastName = 'LeadTestFactory'
      ]
    );

    System.assertEquals(
      (DateTime) phoneCall.ActivityDate,
      (DateTime) recordsToVerify[0].get('Last_Sales_Activity_Date__c'),
      'Phone case Last update not updated.'
    );

    System.runAs(salesWithPermission) {
      phoneCall.ActivityDate = System.today() + 2;
      update phoneCall;
    }

    Contact contactRec = [
      SELECT Id, Last_Sales_Activity_Date__c
      FROM Contact
      WHERE Id = :phoneCall.WhoId
    ];

    if (contactRec != null) {
      System.assertEquals(
        (DateTime) phoneCall.ActivityDate,
        contactRec.Last_Sales_Activity_Date__c,
        'Contact record has not been updated'
      );
    }
    DateTime activityDatePriorchange = phoneCall.ActivityDate;

    System.runAs(nonSalesRelatedUser) {
      phoneCall.ActivityDate = phoneCall.ActivityDate + 2;
      update phoneCall;
    }

    contactRec = [
      SELECT Id, Last_Sales_Activity_Date__c
      FROM Contact
      WHERE Id = :phoneCall.WhoId
    ];

    System.assertEquals(
      activityDatePriorchange,
      contactRec.Last_Sales_Activity_Date__c,
      'Contact record has been updated'
    );

    Event eventTask = new Event();
    eventTask.ActivityDate = Date.today();
    eventTask.StartDateTime = System.now();
    eventTask.EndDateTime = System.now();
    eventTask.Type = 'Meeting';
    eventTask.WhoId = recordsToUpdate[1].Id;

    System.runAs(salesWithPermission) {
      insert eventTask;
    }

    contactRec = [
      SELECT Id, Last_Sales_Activity_Date__c
      FROM Contact
      WHERE Id = :eventTask.WhoId
    ];

    System.assertEquals(
      (DateTime) eventTask.ActivityDate,
      contactRec.Last_Sales_Activity_Date__c,
      'Contact record has not been updated'
    );
  }
}