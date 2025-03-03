public with sharing class AccountHierarchyCheckHandler extends DomainLogicHandler {
    List<Account> workSet = new List<Account>();
    Id customerRecordTypeId = RecordTypeUtility.getId(
        Account.getSObjectType(),
        'Customer'
    );

    public override void check(SObject newObj) {
        Account account = (Account) newObj;
        if (account.RecordTypeId == customerRecordTypeId) {
            account.Pending_Hierarchy_Review__c = true;
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        Account newAccount = (Account) newObj;
        Account oldAccount = (Account) oldObj;
        if (isQualified(newAccount, oldAccount)) {
            newAccount.Pending_Hierarchy_Review__c = true;
        }
    }

    private Boolean isQualified(Account newAccount, Account oldAccount) {
        return isCustomer(newAccount) &&
            hasParent(newAccount) &&
            isChanged(newAccount, oldAccount);
    }

    private Boolean isCustomer(Account newAccount) {
        return newAccount.RecordTypeId == customerRecordTypeId;
    }

    private Boolean hasParent(Account newAccount) {
        return newAccount.ParentId != null;
    }

    private Boolean isChanged(Account newAccount, Account oldAccount) {
        return newAccount.ParentId != oldAccount.ParentId;
    }
}