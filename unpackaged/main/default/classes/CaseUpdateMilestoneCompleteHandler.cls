public with sharing class CaseUpdateMilestoneCompleteHandler extends DomainLogicHandler {
  List<Id> caseIds = new List<Id>();

  public override void check(SObject newObj, SObject oldObj) {
    Case caseNewObj = (Case) newObj;
    Case caseOldObj = (Case) oldObj;

    if (isChanged(caseNewObj, caseOldObj) && !userHasByPass()) {
      caseIds.add(caseNewObj.Id);
    }
  }

  public override void processRecords() {
    completeMilestone();
  }

  private Boolean isChanged(Case caseNew, Case caseOld) {
    return ((caseOld.First_Response__c != caseNew.First_Response__c) &&
    (caseNew.First_Response__c != null));
  }

  private boolean userHasByPass() {
    return FeatureManagement.checkPermission(
      'ByPassCaseUpdateMilestoneCompleteHandler'
    );
  }

  private void completeMilestone() {
    List<CaseMilestone> caseMileStoneToUpdate = [
      SELECT Id, completionDate
      FROM CaseMilestone
      WHERE
        caseId IN :caseIds
        AND MilestoneType.Name = 'First Response'
        AND completionDate = NULL
    ];

    for (CaseMilestone caseMilestone : caseMileStoneToUpdate) {
      caseMilestone.completionDate = System.now();
    }
    update caseMileStoneToUpdate;
  }
}