/**
 * test coverage is found in Account6QAOppHandlerTest
 */
public with sharing class StageZeroOppAddOnQualifier {
    public static Boolean isQualified(Account account) {
        return isCurrentCustomer(account);
    }

    static Boolean isCurrentCustomer(Account account) {
        return account.Account_Stage__c == 'Customer';
    }
}