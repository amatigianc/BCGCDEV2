@IsTest
public with sharing class AccountCaseSupportPackageUpdateTest {
  @TestSetup
  static void testData() {
    List<Account> accountSet = AccountTestFactory.getCustomers(3);

    for (Account accountRec : AccountSet) {
      accountRec.Support_package__c = 'Silver';
    }

    insert accountSet;

    List<Case> caseSet = new List<Case>();
    Id technicalSupportRecordType = RecordTypeUtility.getid(
      Case.getSObjectType(),
      'Technical Support'
    );

    for (Account accountRec : accountSet) {
      Case caseRec = new Case();
      caseRec.AccountId = accountRec.Id;
      caseRec.RecordTypeId = technicalSupportRecordType;
      caseRec.Status = 'New';
      caseRec.Support_Package__c = accountRec.Support_package__c;
      caseRec.Origin = 'Email';
      caseSet.add(caseRec);
    }
    insert caseSet;
  }

  @isTest
  static void processTest() {
    List<Account> accountSet = [
      SELECT Id, Support_Package__c
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    Test.startTest();
    for (Account accountRec : accountSet) {
      accountRec.Support_package__c = 'Platinum';
    }
    update accountSet;

    Test.stopTest();

    List<Case> caseSet = [
      SELECT Id, AccountId, Support_Package__c, Account.Support_package__c
      FROM Case
      WHERE IsClosed = FALSE AND AccountId IN :accountSet
    ];

    for (Case caseRec : caseSet) {
      System.assertEquals(
        'Platinum',
        caseRec.Support_Package__c,
        'Not all the open cases got the support package updated'
      );
    }
  }
}