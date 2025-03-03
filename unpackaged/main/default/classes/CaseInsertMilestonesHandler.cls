/**
 * Description: Before a Case record is created, it gathers the AccountId and create the Entitlement record for the SLA associated to the case
 * EVENT: BEFORE_INSERT
 * SObject: Case
 */

public with sharing class CaseInsertMilestonesHandler extends DomainLogicHandler {
  List<Case> caseSet = new List<Case>();
  Map<Id, Id> contactAccountIds = new Map<Id, Id>();

  List<Id> contactIds = new List<Id>();
  List<Id> accountIds = new List<Id>();

  public override void check(SObject newObject) {
    Case newCase = (Case) newObject;

    if (isQualified(newCase)) {
      caseSet.add(newCase);
      contactIds.add(newCase.ContactId);
      accountIds.add(newCase.AccountId);
    }
  }

  private Boolean isQualified(Case newCase) {
    Id technicalSupportRecordType = RecordTypeUtility.getid(
      Case.getSObjectType(),
      'Technical Support'
    );

    return newCase.EntitlementId == null &&
      newCase.RecordTypeId == technicalSupportRecordType &&
      newCase.Status == 'New' &&
      newCase.First_Response__c == null &&
      !newCase.Origin.contains('System') &&
      !newCase.Origin.contains('Automatic Process') &&
      !newCase.Origin.contains('Automated Task') &&
      !newCase.Origin.contains('Proactive Outreach');
  }

  public override void processRecords() {
    insertCaseMilestones();
  }

  private void insertCaseMilestones() {
    List<Contact> contactFromAccounts = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Id IN :contactIds
    ];

    for (Contact contactCase : contactFromAccounts) {
      contactAccountIds.put(contactCase.Id, contactCase.AccountId);
    }

    accountIds.addAll(contactAccountIds.values());

    Map<Id, Account> accountsMap = new Map<Id, Account>(
      [
        SELECT
          Id,
          Name,
          (
            SELECT Id, Priority__c
            FROM Entitlements
            WHERE Status = 'Active'
            ORDER BY Priority__c DESC
            LIMIT 1
          )
        FROM Account
        WHERE Id IN :accountIds
      ]
    );

    for (Case caseRec : caseSet) {
      if (caseRec.AccountId == null) {
        caseRec.AccountId = contactAccountIds.get(caseRec.ContactId);
      }

      caseRec.EntitlementId = accountsMap.get(caseRec.AccountId)
        ?.Entitlements[0]
        .Id;
    }
  }
}