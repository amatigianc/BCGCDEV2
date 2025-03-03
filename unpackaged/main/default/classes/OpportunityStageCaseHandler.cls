public with sharing class OpportunityStageCaseHandler extends DomainLogicHandler {
  List<Id> qualifiedOppIds = new List<Id>();
  Id technicalSupportRecordType;
  Database.DMLOptions dmlOpts;

  public override void check(Sobject newObj, Sobject oldObj) {
    Opportunity newOpp = (Opportunity) newObj;
    Opportunity oldOpp = (Opportunity) oldObj;

    if (isQualified(newOpp, oldOpp)) {
      qualifiedOppIds.add(newOpp.Id);
    }
  }

  public override void processRecords() {
    if (qualifiedOppIds.isEmpty()) {
      return;
    }

    technicalSupportRecordType = RecordTypeUtility.getid(
      Case.getSObjectType(),
      'Technical Support'
    );
    setDmlOptions();

    List<Opportunity> opportunities = [
      SELECT Id, Name, AccountId, Account.Name, RecordType.Name, Owner.Name, Contract_Id__c, Trial_Account_Id__c
      FROM Opportunity
      WHERE Id IN :qualifiedOppIds
    ];

    List<Case> cases = new List<Case>();
    for (Opportunity opp : opportunities) {
      cases.add(getCase(opp));
    }

    insert cases;
  }

  Boolean isQualified(Opportunity newOpp, Opportunity oldOpp) {
    return (newOpp.StageName == 'Closed Won') &&
      (newOpp.StageName != oldOpp.StageName) &&
      (isRecordTypeQualified(newOpp));
  }

  Boolean isRecordTypeQualified(Opportunity newOpp) {
    return (RecordTypeUtility.getName(newOpp) == 'New Business' ||
      RecordTypeUtility.getName(newOpp) == 'Add-on') ||
      (RecordTypeUtility.getName(newOpp) == 'Renewal' &&
      newOPP.Is_the_Contract_Auto_Renewing__c != 'Yes');
  }

  void setDmlOptions() {
    AssignmentRule caseAssignRule = [
      SELECT Id, name
      FROM AssignmentRule
      WHERE SObjectType = 'Case' AND Active = TRUE
    ];

    dmlOpts = new Database.DMLOptions();
    dmlOpts.AssignmentRuleHeader.AssignmentRuleId = caseAssignRule.Id;
  }

  Case getCase(Opportunity opp) {
    Case techSupportCase = new Case();

    techSupportCase.setOptions(dmlOpts);
    techSupportCase.AccountId = opp.AccountId;
    techSupportCase.RecordTypeId = technicalSupportRecordType;
    techSupportCase.Status = 'New';
    techSupportCase.Subject =
      '[Automated] Review ' +
      opp.RecordType.name +
      ': ' +
      opp.Name;
    techSupportCase.First_Response__c = System.now();
    techSupportCase.Case_Language__c = 'English';
    techSupportCase.Description =
      'Account Name: ' +
      opp.Account.Name +
      '\n' + 
      'Contract ID: ' +
      opp.Contract_Id__c +
      '\n' +
      'Brightcove Account Number: ' +
      opp.Trial_Account_Id__c +
      '\n' +
      'Account Link: ' +
      URL.getSalesforceBaseUrl().toExternalForm() +
      '/' +
      opp.AccountId +
      '\n' +
      'Opportunity Owner: ' +
      opp.Owner.Name +
      '\n' +
      'Opportunity Type: ' +
      opp.RecordType.Name +
      '\n' +
      'Opportunity Link: ' +
      URL.getSalesforceBaseUrl().toExternalForm() +
      '/' +
      opp.Id +
      '\n \n' +
      'Thank you. \n Technical Support Team';
    techSupportCase.Type = 'Automated Task';
    techSupportCase.Priority = 'P3 - Normal';
    techSupportCase.Origin = 'System';

    return techSupportCase;
  }
}