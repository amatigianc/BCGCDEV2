@isTest
public with sharing class OpportunityClosedHandlerTest {
  @TestSetup
  static void makeData() {
    TestUserProvisioner provisioner = new TestUserProvisioner(
      UserInfo.getUserId()
    );
    provisioner.setPermissionSetGroup('Sales Rep');
    provisioner.assignPermissions();

    List<Account> accounts = AccountTestFactory.getCustomers(2);
    accounts[0].Name = 'OpportunityClosedLostHandlerTest';
    accounts[1].Name = 'testRecyleContacts';
    insert accounts;
  }

  @isTest
  static void testRecyleContactsNewBus() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'OpportunityClosedLostHandlerTest'
      LIMIT 1
    ];

    Opportunity opp = OpportunityTestFactory.getStageZeroOpp();
    opp.Deal_Type__c = 'New Business';
    opp.AccountId = account.Id;
    insert opp;

    OpportunityTestFactory.disqualifyStageZeroOpp(opp);

    SBQQ.TriggerControl.disable();

    Test.startTest();
    update opp;
    Test.stopTest();

    Id contactId = opp.ContactId;

    Contact contact = [
      SELECT Id, Stage__c
      FROM Contact
      WHERE Id = :opp.ContactId
    ];

    System.assertEquals(
      'Recycled',
      contact.Stage__c,
      'Contact Stage was not set to "Recycled"'
    );
  }

  @isTest
  static void testRecyleContactsAddOn() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'OpportunityClosedLostHandlerTest'
      LIMIT 1
    ];

    Opportunity opp = OpportunityTestFactory.getStage1Opp(
      account.Id,
      RecordTypeUtility.getId(Opportunity.getSObjectType(), 'Add-On')
    );
    opp.Deal_Type__c = 'Add-On';
    opp.Add_On_Type__c = 'Upsell';

    upsert opp;
    OpportunityTestFactory.setStage2(opp);
    update opp;
    OpportunityTestFactory.setStage3(opp);
    update opp;
    OpportunityTestFactory.setStage4(opp);
    update opp;
    opp.StageName = 'Closed Lost';

    SBQQ.TriggerControl.disable();

    Test.startTest();
    update opp;
    Test.stopTest();

    Id contactId = opp.ContactId;

    Contact contact = [
      SELECT Id, Stage__c
      FROM Contact
      WHERE Id = :opp.ContactId
    ];

    System.assertEquals(
      'Recycled',
      contact.Stage__c,
      'Contact Stage was not set to "Recycled"'
    );
  }

  @isTest
  static void testRecyleContactsRenewalContactOpenOpp() {
    Account account1 = [
      SELECT Id
      FROM Account
      WHERE Name = 'OpportunityClosedLostHandlerTest'
      LIMIT 1
    ];

    Account account2 = [
      SELECT Id
      FROM Account
      WHERE Name = 'testRecyleContacts'
      LIMIT 1
    ];

    Opportunity opp = OpportunityTestFactory.getStage1Opp(
      account1.Id,
      RecordTypeUtility.getId(
        Opportunity.getSObjectType(),
        'Renewal Growth Add-on'
      )
    );
    opp.Deal_Type__c = 'Renewal Growth';
    opp.Add_On_Type__c = 'Upsell';

    upsert opp;
    OpportunityTestFactory.setStage2(opp);
    update opp;
    OpportunityTestFactory.setStage3(opp);
    update opp;
    OpportunityTestFactory.setStage4(opp);
    update opp;
    opp.StageName = 'Closed Lost';

    Contact newContact = ContactTestFactory.createContact(account2);

    Opportunity opp2 = OpportunityTestFactory.getStageZeroOpp();
    opp.AccountId = account2.Id;
    insert opp2;

    OpportunityContactRole newContactRole = new OpportunityContactRole();
    newContactRole.ContactId = newContact.Id;
    newContactRole.OpportunityId = opp.Id;
    insert newContactRole;

    SBQQ.TriggerControl.disable();

    Test.startTest();
    update opp;
    Test.stopTest();

    Id contactId = opp.ContactId;

    Contact contact = [
      SELECT Id, Stage__c
      FROM Contact
      WHERE Id = :opp.ContactId
    ];

    System.assertEquals(
      'Recycled',
      contact.Stage__c,
      'Contact Stage was not set to "Recycled"'
    );
    System.assertNotEquals(
      'Recycled',
      newcontact.Stage__c,
      'Contact Stage was set to "Recycled"'
    );
  }
}