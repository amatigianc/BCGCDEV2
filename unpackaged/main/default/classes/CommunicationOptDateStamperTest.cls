@IsTest(isparallel=true)
public with sharing class CommunicationOptDateStamperTest {
  @IsTest
  private static void testInsertandUpdateContact() {
    Contact contact = ContactTestFactory.getContact();
    contact.Communication_Opt_In__c = true;
    contact.Communication_Opt_Out__c = true;
    contact.Phone_Opt_In__c = true;
    contact.Phone_Opt_Out__c = true;
    insert contact;

    contact = [
      SELECT
        Id,
        Communication_Opt_In_Date__c,
        Communication_Opt_Out_Date__c,
        Phone_Opt_In_Date__c,
        Phone_Opt_Out_Date__c
      FROM Contact
      WHERE Id = :contact.Id
    ];

    system.assertEquals(
      Date.today(),
      contact.Communication_Opt_In_Date__c,
      'Communication_Opt_In_Date__c has not updated to todays date when created'
    );
    system.assertEquals(
      Date.today(),
      contact.Communication_Opt_Out_Date__c,
      'Communication_Opt_Out_Date__c has not updated to todays date when created'
    );
    system.assertEquals(
      Date.today(),
      contact.Phone_Opt_In_Date__c,
      'Phone_Opt_In_Date__c has not updated to todays date when created'
    );
    system.assertEquals(
      Date.today(),
      contact.Phone_Opt_Out_Date__c,
      'Phone_Opt_Out_Date__c has not updated to todays date when created'
    );

    contact.Communication_Opt_In__c = false;
    contact.Communication_Opt_Out__c = false;
    contact.Phone_Opt_In__c = false;
    contact.Phone_Opt_Out__c = false;

    update contact;
    contact = [
      SELECT
        Id,
        Communication_Opt_In_Date__c,
        Communication_Opt_Out_Date__c,
        Phone_Opt_In_Date__c,
        Phone_Opt_Out_Date__c
      FROM Contact
      WHERE Id = :contact.Id
    ];

    system.assertEquals(
      null,
      contact.Communication_Opt_In_Date__c,
      'Communication_Opt_In_Date__c has not cleared'
    );
    system.assertEquals(
      null,
      contact.Communication_Opt_Out_Date__c,
      'Communication_Opt_Out_Date__c has not cleared'
    );
    system.assertEquals(
      null,
      contact.Phone_Opt_In_Date__c,
      'Phone_Opt_In_Date__c has not cleared'
    );
    system.assertEquals(
      null,
      contact.Phone_Opt_Out_Date__c,
      'Phone_Opt_Out_Date__c has not cleared'
    );

    contact.Communication_Opt_In__c = true;
    contact.Communication_Opt_Out__c = true;
    contact.Phone_Opt_In__c = true;
    contact.Phone_Opt_Out__c = true;

    update contact;
    contact = [
      SELECT
        Id,
        Communication_Opt_In_Date__c,
        Communication_Opt_Out_Date__c,
        Phone_Opt_In_Date__c,
        Phone_Opt_Out_Date__c
      FROM Contact
      WHERE Id = :contact.Id
    ];

    system.assertEquals(
      Date.today(),
      contact.Communication_Opt_In_Date__c,
      'Communication_Opt_In_Date__c has not updated to todays date when updated'
    );
    system.assertEquals(
      Date.today(),
      contact.Communication_Opt_Out_Date__c,
      'Communication_Opt_Out_Date__c has not updated to todays date when updated'
    );
    system.assertEquals(
      Date.today(),
      contact.Phone_Opt_In_Date__c,
      'Phone_Opt_In_Date__c has not updated to todays date when updated'
    );
    system.assertEquals(
      Date.today(),
      contact.Phone_Opt_Out_Date__c,
      'Phone_Opt_Out_Date__c has not updated to todays date when updated'
    );
  }

  @IsTest
  private static void testInsertandUpdatelead() {
    Lead lead = LeadTestFactory.getLead();

    lead.Communication_Opt_In__c = true;
    lead.Communication_Opt_Out__c = true;
    lead.Phone_Opt_In__c = true;
    lead.Phone_Opt_Out__c = true;

    insert lead;

    lead = [
      SELECT
        Id,
        Communication_Opt_In_Date__c,
        Communication_Opt_Out_Date__c,
        Phone_Opt_In_Date__c,
        Phone_Opt_Out_Date__c
      FROM Lead
      WHERE Id = :lead.Id
    ];

    system.assertEquals(
      Date.today(),
      lead.Communication_Opt_In_Date__c,
      'Communication_Opt_In_Date__c has not updated to todays date when created'
    );
    system.assertEquals(
      Date.today(),
      lead.Communication_Opt_Out_Date__c,
      'Communication_Opt_Out_Date__c has not updated to todays date when created'
    );
    system.assertEquals(
      Date.today(),
      lead.Phone_Opt_In_Date__c,
      'Phone_Opt_In_Date__c has not updated to todays date when created'
    );
    system.assertEquals(
      Date.today(),
      lead.Phone_Opt_Out_Date__c,
      'Phone_Opt_Out_Date__c has not updated to todays date when created'
    );

    lead.Communication_Opt_In__c = false;
    lead.Communication_Opt_Out__c = false;
    lead.Phone_Opt_In__c = false;
    lead.Phone_Opt_Out__c = false;

    update lead;
    lead = [
      SELECT
        Id,
        Communication_Opt_In_Date__c,
        Communication_Opt_Out_Date__c,
        Phone_Opt_In_Date__c,
        Phone_Opt_Out_Date__c
      FROM Lead
      WHERE Id = :lead.Id
    ];

    system.assertEquals(
      null,
      lead.Communication_Opt_In_Date__c,
      'Communication_Opt_In_Date__c has not cleared'
    );
    system.assertEquals(
      null,
      lead.Communication_Opt_Out_Date__c,
      'Communication_Opt_Out_Date__c has not cleared'
    );
    system.assertEquals(
      null,
      lead.Phone_Opt_In_Date__c,
      'Phone_Opt_In_Date__c has not cleared'
    );
    system.assertEquals(
      null,
      lead.Phone_Opt_Out_Date__c,
      'Phone_Opt_Out_Date__c has not cleared'
    );

    lead.Communication_Opt_In__c = true;
    lead.Communication_Opt_Out__c = true;
    lead.Phone_Opt_In__c = true;
    lead.Phone_Opt_Out__c = true;

    update lead;
    lead = [
      SELECT
        Id,
        Communication_Opt_In_Date__c,
        Communication_Opt_Out_Date__c,
        Phone_Opt_In_Date__c,
        Phone_Opt_Out_Date__c
      FROM Lead
      WHERE Id = :lead.Id
    ];

    system.assertEquals(
      Date.today(),
      lead.Communication_Opt_In_Date__c,
      'Communication_Opt_In_Date__c has not updated to todays date when updated'
    );
    system.assertEquals(
      Date.today(),
      lead.Communication_Opt_Out_Date__c,
      'Communication_Opt_Out_Date__c has not updated to todays date when updated'
    );
    system.assertEquals(
      Date.today(),
      lead.Phone_Opt_In_Date__c,
      'Phone_Opt_In_Date__c has not updated to todays date when updated'
    );
    system.assertEquals(
      Date.today(),
      lead.Phone_Opt_Out_Date__c,
      'Phone_Opt_Out_Date__c has not updated to todays date when updated'
    );
  }
}