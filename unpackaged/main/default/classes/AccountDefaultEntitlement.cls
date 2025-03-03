public with sharing class AccountDefaultEntitlement extends DomainLogicHandler {
  List<Id> accountIds = new List<Id>();
  List<Id> accountCustomerIds = new List<Id>();

  public override void check(SObject newObject) {
    Account newAccount = (Account) newObject;
    if (AccountDefaultSupportPackageQualifier.isQualified(newAccount)) {
      accountIds.add(newObject.Id);
    }
  }

  public override void check(SObject newObject, SObject oldObject) {
    Account newAccount = (Account) newObject;
    Account oldAccount = (Account) oldObject;
    if (
      AccountDefaultSupportPackageQualifier.isQualified(newAccount, oldAccount)
    ) {
      if (newAccount.Account_Stage__c == 'Former') {
        accountIds.add(newAccount.Id);
      } else if (newAccount.Account_Stage__c == 'Customer') {
        accountCustomerIds.add(newAccount.Id);
      }
    }
  }

  public override void processRecords() {
    if (!accountCustomerIds.isEmpty()) {
      endDefaultGold(accountCustomerIds);
    }
    if (!accountIds.isEmpty()) {
      processAccounts(accountIds);
    }
  }

  static void processAccounts(List<Id> accountIds) {
    List<Entitlement> entitlements = new List<Entitlement>();

    List<Account> accounts = [
      SELECT Id, Support_Package__c, Account_Stage__c, Sales_Division__c
      FROM Account
      WHERE Id IN :accountIds
    ];

    for (Account account : accounts) {
      if (account.Account_Stage__c == 'Prospect') {
        Entitlement ent = EntitlementProcessor.getEntitlement(
          account,
          'Gold Default',
          Date.today(),
          Date.today().addYears(100)
        );

        entitlements.add(ent);

        entitlements.add(
          EntitlementProcessor.getEntitlement(
            account,
            'Silver Default',
            Date.today(),
            Date.today().addYears(100)
          )
        );
      }
    }

    insert entitlements;
  }

  void endDefaultGold(List<Id> accountCustomerIds) {
    List<Entitlement> entitlementsToUpdate = [
      SELECT Id
      FROM Entitlement
      WHERE Name = 'Gold Default' AND AccountID IN :accountCustomerIds
    ];

    for (entitlement ent : entitlementsToUpdate) {
      ent.EndDate = Date.today();
    }
    update entitlementsToUpdate;
  }
}