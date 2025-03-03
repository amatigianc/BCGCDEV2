@isTest(isparallel=true)
public with sharing class RecordTypeUtilityTest {
  @isTest
  private static void testGetName() {
    RecordType recordType = [
      SELECT Id, Name
      FROM RecordType
      WHERE SObjectType = 'Account' AND IsActive = TRUE
      LIMIT 1
    ];
    String expected = recordType.Name;

    Account account = AccountTestFactory.getCustomer();
    account.Name = 'RecordTypeUtilityTest';
    account.RecordTypeId = recordType.Id;

    String actual = RecordTypeUtility.getName(account);

    System.assertEquals(
      expected,
      actual,
      'Incorrect Record Type Name returned.'
    );
  }

  @isTest
  private static void testGetId() {
    RecordType recordType = [
      SELECT Id, Name
      FROM RecordType
      WHERE SObjectType = 'Account' AND IsActive = TRUE
      LIMIT 1
    ];

    Id expected = recordType.Id;
    Id actual = RecordTypeUtility.getId(
      Account.getSObjectType(),
      recordType.Name
    );

    System.assertEquals(
      expected,
      actual,
      'Incorrect Record Id returned for "' + recordType.Name + '"'
    );
  }
}