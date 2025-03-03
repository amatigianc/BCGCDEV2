public with sharing class AccountCaseSupportPackageUpdate extends DomainLogicHandler {
  List<Account> accountSet = new List<Account>();

  public override void check(SObject newObject, SObject oldObject) {
    Account beforeAccount = (Account) newObject;
    Account afterAccount = (Account) oldObject;

    Id accountRecordType = RecordTypeUtility.getid(
      Account.getSObjectType(),
      'Customer'
    );
    if (
      (beforeAccount.Support_package__c != afterAccount.Support_package__c) &&
      (afterAccount.RecordTypeId == accountRecordType)
    ) {
      accountSet.add(afterAccount);
    }
  }

  public override void processRecords() {
    List<Case> caseSet = new List<Case>();
    caseSet = [
      SELECT id, Support_Package__c, Account.Support_Package__c
      FROM Case
      WHERE IsClosed = FALSE AND AccountId IN :accountSet
    ];

    for (Case caseRec : caseSet) {
      caseRec.Support_Package__c = caseRec.Account.Support_package__c;
    }
    update caseSet;
  }
}