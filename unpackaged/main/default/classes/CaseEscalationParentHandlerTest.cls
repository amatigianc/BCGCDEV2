@isTest
private class CaseEscalationParentHandlerTest {
  @TestSetup
  static void makeData() {
    Id accountCustomerRecordType = RecordTypeUtility.getId(
      Account.getSObjectType(),
      'Customer'
    );

    Account parentAccount = new Account(
      Name = 'ParentAccount',
      recordtypeId = accountCustomerRecordType,
      Account_Stage__c = 'Customer',
      BillingCountry = 'Italy'
    );
    Account dummyAccount = new Account(
      Name = 'DummyAccount',
      recordTypeId = accountCustomerRecordType,
      Account_Stage__c = 'Customer',
      BillingCountry = 'Italy'
    );

    List<Account> accountList = new List<Account>();
    accountList.add(parentAccount);
    accountList.add(dummyAccount);

    insert accountList;

    Id caseCaseEscalation = RecordTypeUtility.getId(
      Case.getSObjectType(),
      'Case Escalation'
    );

    Id caseTechnicalSupport = RecordTypeUtility.getId(
      Case.getSObjectType(),
      'Technical Support'
    );

    Case caseTechSupport = new Case(
      Account = parentAccount,
      Description = 'TestParentAccount',
      Subject = 'TestParentAccount',
      RecordTypeId = caseTechnicalSupport,
      Origin = 'Email',
      First_Response__c = system.now()
    );

    Case caseEscalation = new Case(
      Account = dummyAccount,
      Description = 'TestDummyEscalation',
      Subject = 'TestDummyEscalation',
      RecordTypeId = caseCaseEscalation
    );

    List<Case> caseList = new List<Case>();
    caseList.add(caseTechSupport);
    caseList.add(caseEscalation);

    insert caseList;
  }

  @isTest
  static void testAccountUpdate() {
    Case caseTechSupport = [
      SELECT Id, AccountId
      FROM Case
      WHERE Subject = 'TestParentAccount'
    ];

    Case caseEscalation = [
      SELECT Id, AccountId, ParentId, Parent.AccountId
      FROM Case
      WHERE Subject = 'TestDummyEscalation'
    ];

    Test.startTest();
    caseEscalation.ParentId = caseTechSupport.Id;
    update caseEscalation;
    Test.stopTest();

    Case caseEscalationAFTER = [
      SELECT Id, AccountId, ParentId, Parent.AccountId
      FROM Case
      WHERE Subject = 'TestDummyEscalation'
    ];

    System.assertEquals(
      caseTechSupport.AccountId,
      caseEscalationAFTER.AccountId,
      'err: Case Escalation Account not updated'
    );
  }
}