public with sharing class ContactTestFactory {
  static Database.DMLOptions getDmlOption() {
    Database.DMLOptions dmlOption = new Database.DMLOptions();
    dmlOption.DuplicateRuleHeader.AllowSave = true;
    return dmlOption;
  }

  public static Contact getContact(Account account) {
    return getContacts(1, account)[0];
  }

  public static Contact getContact() {
    return getContacts(1)[0];
  }

  public static List<Contact> getContacts(Integer count, Account account) {
    List<Contact> contacts = new List<contact>();
    for (Integer i = 0; i < count; i++) {
      contacts.add(
        new Contact(
          FirstName = 'Test',
          LastName = 'ContactTestFactory' + String.valueOf(i),
          Email = 'test.contact' + String.valueOf(i) + '@example.com',
          accountId = account.Id
        )
      );
    }
    return contacts;
  }

  public static List<Contact> getContacts(Integer count) {
    Account account = AccountTestFactory.createCustomer();
    List<Contact> contacts = new List<contact>();
    for (Integer i = 0; i < count; i++) {
      contacts.add(
        new Contact(
          FirstName = 'Test',
          LastName = 'ContactTestFactory' + String.valueOf(i),
          Email = 'test.contact' + String.valueOf(i) + '@example.com',
          accountId = account.Id
        )
      );
    }
    return contacts;
  }

  public static Contact createContact() {
    return createContacts(1)[0];
  }

  public static Contact createContact(Account account) {
    return createContacts(1, account)[0];
  }

  public static List<Contact> createContacts(Integer count) {
    List<Contact> contacts = getContacts(count);
    Database.insert(contacts, getDmlOption());
    return contacts;
  }

  public static List<Contact> createContacts(Integer count, Account account) {
    List<Contact> contacts = getContacts(count, account);
    Database.insert(contacts, getDmlOption());
    return contacts;
  }
}