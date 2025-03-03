public class AccountDefaultSupportPackageQualifier {
  public static Boolean isQualified(Account newAccount, Account oldAccount) {
    return ((newAccount.Account_Stage__c == 'Former' &&
    oldAccount.Account_Stage__c == 'Customer') ||
    (newAccount.Account_Stage__c == 'Customer' &&
    oldAccount.Account_Stage__c == 'Prospect'));
  }

  public static Boolean isQualified(Account newAccount) {
    return newAccount.Account_Stage__c == 'Prospect';
  }
}