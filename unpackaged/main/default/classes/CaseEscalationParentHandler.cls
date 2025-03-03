/**
 * SOBject: Case
 * EVENT: BEFORE_UPDATE
 * Description: it manages updates on Case Escalations record type cases.
 * 1. When the parent case on the escalation case is updated, the AccountId on the escalation is updated to the Parent Case's Account.
 */

public with sharing class CaseEscalationParentHandler extends DomainLogicHandler {
  List<Case> qualifiedCases = new List<Case>();
  List<Id> parentCaseIds = new List<Id>();

  Id caseRecordType = RecordTypeUtility.getId(
    Case.getSObjectType(),
    'Case Escalation'
  );

  public override void check(SObject newObj, SObject oldObj) {
    Case newCase = (Case) newObj;
    Case oldCase = (Case) oldObj;

    if (isQualified(oldCase, newCase)) {
      qualifiedCases.add(newCase);
      parentCaseIds.add(newCase.ParentId);
    }
  }

  public override void processRecords() {
    try {
      updateCaseAccount();
    } catch (Exception e) {
      ExceptionHandler.process(e, 'CaseEscalationParentHandler');
    }
  }

  private void updateCaseAccount() {
    Map<Id, Case> parentCases = new Map<Id, Case>(
      [SELECT Id, AccountId FROM Case WHERE Id IN :parentCaseIds]
    );

    for (Case caseRecord : qualifiedCases) {
      caseRecord.AccountId = parentCases.get(caseRecord.ParentId).AccountId;
    }
  }

  private Boolean isQualified(Case oldCase, Case newCase) {
    return isRecordTypeQualified(newCase) &&
      isParentIdChanged(oldCase, newCase);
  }

  private Boolean isRecordTypeQualified(Case newCase) {
    return newCase.RecordTypeId == caseRecordType;
  }

  private Boolean isParentIdChanged(Case oldCase, Case newCase) {
    return (oldCase.ParentId != newCase.ParentId) && newCase.ParentId != null;
  }
}