public with sharing class AccountDefaultSupportPackage extends DomainLogicHandler {
  Map<Id, Account> accountList = new Map<Id, Account>();
  List<Id> accountCustomerList = new List<Id>();

  public override void check(SObject newObject) {
    Account newAccount = (Account) newObject;
    if (AccountDefaultSupportPackageQualifier.isQualified(newAccount)) {
      accountList.put(newAccount.Id, newAccount);
    }
  }

  public override void check(SObject newObject, SObject oldObject) {
    Account newAccount = (Account) newObject;
    Account oldAccount = (Account) oldObject;
    if (
      AccountDefaultSupportPackageQualifier.isQualified(newAccount, oldAccount)
    ) {
      if (newAccount.Account_Stage__c == 'Former') {
        accountList.put(newAccount.Id, newAccount);
      } else if (newAccount.Account_Stage__c == 'Customer') {
        accountCustomerList.add(newAccount.Id);
      }
    }
  }

  public override void processRecords() {
    if (!accountCustomerList.isEmpty()) {
      endDefaultGold(accountCustomerList);
    }
    if (!accountList.isEmpty()) {
      processAccounts(accountList);
    }
  }

  static void processAccounts(Map<Id, Account> accountList) {
    Map<String, String> accountStageSupportPackages = new Map<String, String>{
      'Prospect' => 'Gold',
      'Former' => 'Silver'
    };

    for (Account account : accountList.values()) {
      account.Support_Package__c = accountStageSupportPackages.get(
        account.Account_Stage__c
      );
    }
  }

  @Future
  static void endDefaultGold(List<Id> accountCustomerList) {
    List<Entitlement> entitlementsNotDefault = [
      SELECT AccountId
      FROM Entitlement
      WHERE AccountId IN :accountCustomerList AND (NOT Name LIKE '%Default')
    ];

    List<Id> accountNoSupport = new List<Id>();
    for (Entitlement ent : entitlementsNotDefault) {
      accountNoSupport.add(ent.AccountId);
    }

    List<Account> accountSupport = [
      SELECT Id, Support_Package__c
      FROM Account
      WHERE Id IN :accountCustomerList AND Id NOT IN :accountNoSupport
    ];

    for (Account accUpdate : accountSupport) {
      accUpdate.Support_Package__c = 'Silver';
    }
    update accountSupport;
  }
}