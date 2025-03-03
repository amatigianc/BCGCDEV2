public with sharing class QuoteBillingAddressHandler extends DomainLogicHandler {
    Map<SObjectField, SObjectField> billingAddressMap = new Map<SObjectField, SObjectField>{
        Account.BillingCity => SBQQ__Quote__c.SBQQ__BillingCity__c,
        Account.BillingCountry => SBQQ__Quote__c.SBQQ__BillingCountry__c,
        Account.BillingPostalCode => SBQQ__Quote__c.SBQQ__BillingPostalCode__c,
        Account.BillingState => SBQQ__Quote__c.SBQQ__BillingState__c,
        Account.BillingStreet => SBQQ__Quote__c.SBQQ__BillingStreet__c
    };
    BCMap qualifiedAccountQuotes = new BCMap('SBQQ__Account__c');
    Map<Id, Account> accounts;

    public override void check(SObject newObj) {
        SBQQ__Quote__c newQuote = (SBQQ__Quote__c) newObj;
        if (isQualified(newQuote)) {
            qualifiedAccountQuotes.put(newQuote);
        }
    }

    public override void processRecords() {
        if (qualifiedAccountQuotes.isNotAllEmpty()) {
            accounts = new Map<Id, Account>(
                [
                    SELECT
                        Id,
                        BillingCity,
                        BillingCountry,
                        BillingPostalCode,
                        BillingState,
                        BillingStreet
                    FROM Account
                    WHERE Id IN :qualifiedAccountQuotes.keyAllSet()
                ]
            );
            for (Id accountId : accounts.keySet()) {
                setFields(accountId);
            }
        }
    }

    void setFields(Id accountId) {
        Account account = accounts.get(accountId);
        for (Sobject newQuote : qualifiedAccountQuotes.getAll(accountId)) {
            for (SObjectField accountField : billingAddressMap.keySet()) {
                SObjectField quoteField = billingAddressMap.get(accountField);
                if (newQuote.get(quoteField) == null) {
                    newQuote.put(quoteField, account.get(accountField));
                }
            }
        }
    }

    Boolean isQualified(SBQQ__Quote__c newQuote) {
        return !TriggerUtility.hasValues(newQuote, billingAddressMap.values());
    }
}