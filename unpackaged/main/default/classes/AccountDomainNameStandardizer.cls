public with sharing class AccountDomainNameStandardizer extends DomainLogicHandler {
    public override void check(SObject newObj) {
        Account newAccount = (Account) newObj;
        if (isQualified(newAccount)) {
            lowerCaseEmailDomain(newAccount);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        Account newAccount = (Account) newObj;
        Account oldAccount = (Account) oldObj;
        if (isQualified(newAccount, oldAccount)) {
            lowerCaseEmailDomain(newAccount);
        }
    }

    Boolean isQualified(Account newAccount) {
        return String.isNotEmpty(newAccount.Email_Domain_Name__c);
    }

    Boolean isQualified(Account newAccount, Account oldAccount) {
        return isQualified(newAccount);
    }

    void lowerCaseEmailDomain(Account newAccount) {
        newAccount.Email_Domain_Name__c = newAccount.Email_Domain_Name__c.toLowerCase();
    }
}