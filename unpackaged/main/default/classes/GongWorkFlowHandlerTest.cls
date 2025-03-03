@isTest
public with sharing class GongWorkFlowHandlerTest {
  @TestSetup
  static void makeData() {
    User bdr = TestUserProvisioner.getNewUser();
    bdr.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'BDR'].Id;
    TestUserProvisioner.insertUsers(JSON.serialize(new List<User>{ bdr }));
  }

  @isTest
  static void testStamping() {
    User bdr = [
      SELECT Id, Name
      FROM User
      WHERE UserRole.Name = 'BDR' AND IsActive = TRUE
      LIMIT 1
    ];

    Lead lead = LeadTestFactory.getLead();
    Contact contact;
    System.runAs(bdr) {
      insert lead;

      contact = ContactTestFactory.createContact();
    }

    Test.startTest();
    lead.Gong__Current_Flow_User_Name__c = bdr.Name;
    update lead;

    contact.Gong__Current_Flow_User_Name__c = bdr.Name;
    update contact;

    Test.stopTest();

    lead = [
      SELECT Id, BDR_Added_to_Gong_Workflow__c, Gong__Current_Flow_User_Name__c
      FROM Lead
      WHERE Id = :lead.Id
    ];
    System.assertEquals(
      Date.today(),
      lead.BDR_Added_to_Gong_Workflow__c.date(),
      'BDR Added to Gong Workflow not stamped correctly.'
    );
    System.assertEquals(
      null,
      lead.Gong__Current_Flow_User_Name__c,
      'Gong Current Flow User Name not cleared.'
    );
    contact = [
      SELECT Id, BDR_Added_to_Gong_Workflow__c, Gong__Current_Flow_User_Name__c
      FROM Contact
      WHERE Id = :contact.Id
    ];
    System.assertEquals(
      null,
      contact.Gong__Current_Flow_User_Name__c,
      'Gong Current Flow User Name not cleared.'
    );
    System.assertEquals(
      Date.today(),
      contact.BDR_Added_to_Gong_Workflow__c.date(),
      'BDR Added to Gong Workflow not stamped correctly.'
    );
  }
}