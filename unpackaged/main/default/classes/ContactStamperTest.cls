@isTest(isparallel=true)
public with sharing class ContactStamperTest {
  @isTest
  private static void testStamp() {
    List<PicklistEntry> stages = Contact.Stage__c.getDescribe()
      .getPicklistValues();
    Contact testContact = ContactTestFactory.getContact();
    testContact.Stage__c = stages[0].getValue();
    insert testContact;

    testContact = [
      SELECT Id, Stage_Date__c
      FROM Contact
      WHERE Id = :testContact.Id
    ];

    System.assertEquals(
      Date.today(),
      testContact.Stage_Date__c,
      'Stage Date not correctly set.'
    );
  }
}