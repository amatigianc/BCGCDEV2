public with sharing class AccountDomainNameHandler extends DomainLogicHandler {
    private Map<String, Id> accountIdsByDomains = new Map<String, Id>();
    public override void check(SObject newObj) {
        Account newAccount = (Account) newObj;
        if (isQualified(newAccount)) {
            accountIdsByDomains.put(
                newAccount.Email_Domain_Name__c,
                newAccount.Id
            );
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        Account newAccount = (Account) newObj;
        Account oldAccount = (Account) oldObj;
        if (isQualified(newAccount, oldAccount)) {
            accountIdsByDomains.put(
                newAccount.Email_Domain_Name__c,
                newAccount.Id
            );
        }
    }

    public override void processRecords() {
        if (!accountIdsByDomains.isEmpty()) {
            List<Brightcove_Account__c> bcAccounts = [
                SELECT Id, Account__c, Email_Domain__c
                FROM Brightcove_Account__c
                WHERE
                    Account__c = NULL
                    AND Email_Domain__c IN :accountIdsByDomains.keySet()
            ];

            for (Brightcove_Account__c bcAccount : bcAccounts) {
                bcAccount.Account__c = accountIdsByDomains.get(
                    bcAccount.Email_Domain__c
                );
            }

            update bcAccounts;
        }
    }

    private Boolean isQualified(Account newAccount) {
        return newAccount.Email_Domain_Name__c != null;
    }

    private Boolean isQualified(Account newAccount, Account oldAccount) {
        return isQualified(newAccount) &&
            TriggerUtility.isChanged(
                newAccount,
                oldAccount,
                Account.Email_Domain_Name__c
            );
    }
}