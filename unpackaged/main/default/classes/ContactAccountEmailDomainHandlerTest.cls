@isTest(isparallel=true)
public with sharing class ContactAccountEmailDomainHandlerTest {
  @TestSetup
  static void makeData() {
    AccountTestFactory.createCustomer();
  }

  @isTest
  private static void testSetEmailDomain() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Email_Domain_Name__c = NULL
      LIMIT 1
    ];
    Contact contact = ContactTestFactory.getContact(account);

    Test.startTest();
    insert contact;
    Test.stopTest();
    contact = [
      SELECT Id, Email_Address_Domain__c
      FROM Contact
      WHERE Id = :contact.Id
    ];
    account = [
      SELECT Id, Email_Domain_Name__c
      FROM Account
      WHERE Id = :account.Id
    ];

    System.assertEquals(
      contact.Email_Address_Domain__c,
      account.Email_Domain_Name__c,
      'Account Email Domain Name not correctly set from new Contact.'
    );
  }
}