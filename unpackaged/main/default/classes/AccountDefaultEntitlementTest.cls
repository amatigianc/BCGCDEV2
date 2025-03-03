@isTest(isparallel=true)
public with sharing class AccountDefaultEntitlementTest {
  static Id customerRecordType = RecordTypeUtility.getId(
    Account.getSObjectType(),
    'Customer'
  );

  @isTest
  static void testDefaultEntitlementsProspect() {
    Account account = AccountTestFactory.getCustomer();
    Test.startTest();
    insert account;

    Test.stopTest();

    account = [
      SELECT
        Id,
        Support_Package__c,
        (
          SELECT Id, StartDate, EndDate, SlaProcess.Name, Name
          FROM Entitlements
          ORDER BY Name
        )
      FROM Account
      WHERE Id = :account.Id
    ];

    System.assertEquals(
      'Gold',
      account.Support_package__c,
      'Account Support Package has not been updated to Gold on insert'
    );

    List<Entitlement> entitlement = account.Entitlements;

    System.assertEquals(
      2,
      entitlement.size(),
      'New porspect accounts should have 2 Entitlements'
    );

    System.assertEquals(
      System.today(),
      entitlement[0].StartDate,
      'Entitlement Start Date was not correctly set to today'
    );
    System.assertEquals(
      System.today().addYears(100),
      entitlement[0].EndDate,
      'Entitlement End Date was not correctly set to 100 Years from today'
    );

    System.assertEquals(
      'Gold',
      entitlement[0].SlaProcess.Name,
      'Entitlement SlaProcessId was not correctly set to Gold'
    );

    System.assertEquals(
      'Gold Default',
      entitlement[0].Name,
      'Entitlement Name was not correctly set to Gold'
    );

    System.assertEquals(
      System.today(),
      entitlement[1].StartDate,
      'Entitlement Start Date was not correctly set to today'
    );
    System.assertEquals(
      System.today().addYears(100),
      entitlement[1].EndDate,
      'Entitlement End Date was not correctly set to 100 Years from today'
    );

    System.assertEquals(
      'Silver Americas',
      entitlement[1].SlaProcess.Name,
      'Entitlement SlaProcessId was not correctly set to Silver Americas'
    );

    System.assertEquals(
      'Silver Default',
      entitlement[1].Name,
      'Entitlement Name was not correctly set to Silver'
    );
  }

  @isTest
  static void testDefaultEntitlementsFormer() {
    Account account = AccountTestFactory.getCustomer();
    account.Account_Stage__c = 'Customer';
    account.Sales_Division__c = 'Americas';

    insert account;

    Test.startTest();

    account.Account_Stage__c = 'Former';
    update account;
    Test.stopTest();

    account = [
      SELECT Id, Support_package__c
      FROM Account
      WHERE Id = :account.Id
    ];

    System.assertEquals(
      'Silver',
      account.Support_package__c,
      'Account Support Package has not been updated to Silver on update to Former'
    );
  }

  @isTest
  static void testDefaultEntitlementsCustomer() {
    Account account = new Account(
      Name = 'ProspectEntitlement',
      RecordTypeId = customerRecordType,
      Account_Stage__c = 'Prospect',
      Sales_Division__c = 'Americas',
      BillingCountryCode = 'US',
      BillingCity = 'Test City',
      BillingPostalCode = '41234',
      BillingState = 'New York',
      BillingStreet = '123 Main st'
    );
    insert account;
    Test.startTest();
    account.Account_Stage__c = 'Customer';

    update account;
    Test.stopTest();

    Date endDate = Date.today().addYears(60);

    List<Entitlement> entitlement = [
      SELECT Id
      FROM Entitlement
      WHERE AccountId = :account.Id AND EndDate > :endDate
    ];

    account = [
      SELECT Id, Support_package__c
      FROM Account
      WHERE Id = :account.Id
    ];

    System.assertEquals(
      1,
      entitlement.size(),
      'Entitlement End Date was not updated'
    );

    System.assertEquals(
      'Silver',
      account.Support_Package__c,
      'Account Support package was not updated to Silver'
    );
  }
}