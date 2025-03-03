/**
 * test coverage is found in Account6QAOppHandlerTest
 */
public with sharing class StageZeroOppNewBusinessQualifier {
  public static Boolean isQualified(Account account) {
    return isNotExistingCustomer(account) && checkNamed(account);
  }

  static Boolean isNotExistingCustomer(Account account) {
    return account.Account_Stage__c != 'Customer';
  }

  static Boolean checkNamed(Account account) {
    return isNamedAccount(account) && isTierQualified(account);
  }

  static Boolean isNamedAccount(Account account) {
    return account.Named_Account__c;
  }

  static Boolean isTierQualified(Account account) {
    return isTopTiered(account) || isQualifiedLowerTier(account);
  }

  static Boolean isTopTiered(Account account) {
    List<String> qualifiedTiers = new List<String>{ 'Tier 1', 'Tier 2' };
    return qualifiedTiers.contains(account.Named_Account_Tier__c);
  }

  static Boolean isQualifiedLowerTier(Account account) {
    List<String> qualifiedTiers = new List<String>{ 'Tier 3' };
    return qualifiedTiers.contains(account.Named_Account_Tier__c) &&
      isMedia(account) &&
      isAmericas(account);
  }

  static Boolean isMedia(Account account) {
    return account.Account_Business_Unit__c == 'Media';
  }

  static Boolean isAmericas(Account account) {
    return account.Sales_Division__c == 'Americas';
  }
}