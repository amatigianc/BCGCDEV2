public with sharing class CaseDetailsController {
  public Case caseRecord { get; set; }

  public CaseDetailsController() {
    Id caseId = getCaseId();
    caseRecord = [SELECT CaseNumber, Subject FROM Case WHERE Id = :caseId];
  }

  private Id getCaseId() {
    Id caseId = ApexPages.currentPage().getParameters().get('id');
    if (caseId == null) {
      throw new IllegalArgumentException('Case ID is required.');
    }
    return caseId;
  }
}