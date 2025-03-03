@isTest(isparallel=true)
public with sharing class CaseInsertMilestonesHandlerTest {
  @TestSetup
  static void createDataSet() {
    List<SlaProcess> slaProcessesId = [
      SELECT Id, description, Name
      FROM SlaProcess
      WHERE
        SObjectType = 'Case'
        AND IsActive = TRUE
        AND IsVersionDefault = TRUE
        AND Name = 'Platinum'
    ];

    List<Account> accounts = AccountTestFactory.createCustomers(3);

    List<Contact> contactsAccount = new List<Contact>();
    for (Account acc : accounts) {
      contact contact = ContactTestFactory.getContact(acc);
      contactsAccount.add(contact);
    }
    insert contactsAccount;

    List<Entitlement> accountEntitlments = new List<Entitlement>();
    for (Account acc : accounts) {
      Entitlement accountEntitlment = new Entitlement();
      accountEntitlment.AccountId = acc.Id;

      accountEntitlment.SlaProcessId = slaProcessesId[0].Id;
      accountEntitlment.Name = 'TestSLA ' + acc.Name;
      accountEntitlment.StartDate = System.today();
      accountEntitlment.EndDate = Date.newInstance(2041, 4, 12);

      accountEntitlments.add(accountEntitlment);
    }

    insert accountEntitlments;
  }

  @isTest
  static void testMilestonesOnCases() {
    List<Case> cases = new List<Case>();

    List<Contact> contactList = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Account.name LIKE 'AccountTestFactory%'
    ];

    List<Account> accountList = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];

    Id technicalSupportRecordType = RecordTypeUtility.getid(
      Case.getSObjectType(),
      'Technical Support'
    );

    Test.startTest();
    for (Contact contactTest : contactList) {
      Case caseAccount = new Case();

      caseAccount.ContactId = contactTest.Id;
      caseAccount.Status = 'New';
      caseAccount.RecordTypeId = technicalSupportRecordType;
      caseAccount.Origin = 'Email';
      caseAccount.Priority = 'P1 - Critical';
      caseAccount.Subject = 'TEST MILESTONE';
      caseAccount.Description = 'TEST TEST';
      cases.add(caseAccount);
    }

    for (Account accRec : accountList) {
      Case accountCase = new Case();
      accountCase.Status = 'New';
      accountCase.RecordTypeId = technicalSupportRecordType;
      accountCase.Origin = 'Email';
      accountCase.Priority = 'P1 - Critical';
      accountCase.AccountId = accRec.Id;
      cases.add(accountCase);
    }

    for (Account accRec : accountList) {
      Case accountCase = new Case(
        Status = 'New',
        RecordTypeId = technicalSupportRecordType,
        Origin = 'System',
        Priority = 'P1 - Critical',
        accountId = accRec.Id
      );
      cases.add(accountCase);
    }

    insert cases;

    Test.stopTest();

    List<CaseMilestone> caseMilestones = [
      SELECT Id, MilestoneTypeId, CaseId, MilestoneType.Name, Case.Origin
      FROM CaseMilestone
      WHERE
        CaseId IN (
          SELECT Id
          FROM Case
          WHERE Status = 'New' AND (Origin = 'Email' OR Origin = 'System')
        )
    ];

    System.assertEquals(
      false,
      caseMilestones.isEmpty(),
      'Not all the cases have a milestone added'
    );

    for (CaseMilestone casemilestone : caseMilestones) {
      System.assertEquals(
        'Email',
        casemilestone.Case.Origin,
        'Err: CaseMilestone created for System or Automated Task origings'
      );

      System.assertEquals(
        'First Response',
        casemilestone.MilestoneType.Name,
        'Not all the cases have a First Response Case milestone'
      );
    }
  }
}