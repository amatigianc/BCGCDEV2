@isTest
public with sharing class AccountTestFactory {
  static Database.DMLOptions getDmlOption() {
    Database.DMLOptions dmlOption = new Database.DMLOptions();
    dmlOption.DuplicateRuleHeader.AllowSave = true;
    return dmlOption;
  }

  public static Account getCustomer() {
    return getCustomers(1)[0];
  }

  public static List<Account> getCustomers(Integer count) {
    List<Account> customers = new List<Account>();
    for (Integer i = 0; i < count; i++) {
      String guid = GuidUtility.generateGuid();
      customers.add(
        new Account(
          Name = 'AccountTestFactory' + guid,
          Naming_Rights__c = Account.Naming_Rights__c.getDescribe()
              .getPicklistValues()[0]
            .getValue(),
          RecordTypeId = RecordTypeUtility.getId(
            Account.getSObjectType(),
            'Customer'
          ),
          GUID__c = guid,
          BillingCountryCode = 'US',
          BillingCity = 'Test City',
          BillingPostalCode = '41234',
          BillingState = 'New York',
          BillingStreet = '123 Main st',
          Customer_Tier__c = Account.Customer_Tier__c.getDescribe()
              .getPicklistValues()[0]
            .getValue()
        )
      );
    }
    return customers;
  }

  public static Account createCustomer() {
    return createCustomers(1)[0];
  }

  public static List<Account> createCustomers(Integer count) {
    List<Account> customers = getCustomers(count);
    Database.insert(customers, getDmlOption());
    return customers;
  }

  public static Account getPartner() {
    return getPartners(1)[0];
  }

  public static List<Account> getPartners(Integer count) {
    List<Account> partners = new List<Account>();
    for (Integer i = 0; i < count; i++) {
      partners.add(
        new Account(
          Name = 'AccountTestFactory Partner ' + String.valueOf(i + 1),
          RecordTypeId = RecordTypeUtility.getId(
            Account.getSObjectType(),
            'Partner'
          ),
          Website = 'www.dummytesterthisisfakebeepbop.cob',
          Partner_Type__c = Account.Partner_Type__c.getDescribe()
              .getPicklistValues()[0]
            .getValue(),
          Partner_Category__c = Account.Partner_Category__c.getDescribe()
              .getPicklistValues()[0]
            .getValue(),
          BillingCountryCode = 'US',
          BillingCity = 'Test City',
          BillingPostalCode = '41234',
          BillingState = 'New York',
          BillingStreet = '123 Main st'
        )
      );
    }
    return partners;
  }

  public static List<Account> createPartners(Integer count) {
    List<Account> partners = getPartners(count);
    Database.insert(partners);
    return partners;
  }

  public static Account createPartner() {
    return createPartners(1)[0];
  }
}