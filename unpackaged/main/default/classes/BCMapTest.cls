@isTest(isparallel=true)
public with sharing class BCMapTest {
  @isTest
  static void testMultiTypeMethods() {
    Account account = AccountTestFactory.createCustomer();

    List<Contact> contacts = ContactTestFactory.getContacts(5, account);
    contacts[0].Department = 'IT';
    contacts[1].Department = 'IT';
    contacts[2].Department = 'IT';
    contacts[3].Department = 'Finance';
    contacts[4].Department = 'Finance';

    BCMap contactsMap = new BCMap(contacts, 'Department');

    List<SObject> actualValues = contactsMap.valuesAll();
    System.assertEquals(
      contacts.size(),
      actualValues.size(),
      'Collection sizes do not match.'
    );

    System.assert(contactsMap.isNotAllEmpty());
    System.assertEquals(
      2,
      contactsMap.keyAllSet().size(),
      'Incorrect number of keys in map.'
    );

    Map<String, Integer> expectedCounts = new Map<String, Integer>{
      'IT' => 3,
      'Finance' => 2
    };

    for (String department : expectedCounts.keySet()) {
      Integer expectedCount = expectedCounts.get(department);

      Integer actualCount = contactsMap.getAll(department).size();
      System.assertEquals(
        expectedCount,
        actualCount,
        'Incorrect number of records for key "' + department + '"'
      );

      for (Contact contact : (List<Contact>) contactsMap.getAll(department)) {
        System.assertEquals(
          contact.Department,
          department,
          'Incorrect Contact values for key "' + department + '"'
        );
      }
    }

    Integer expectedLegalCount = 20;

    List<Contact> legalContacts = ContactTestFactory.getContacts(
      expectedLegalCount,
      account
    );
    for (Contact contact : legalContacts) {
      contact.Department = 'Legal';
    }

    contactsMap.putAll(legalContacts);

    System.assertEquals(
      expectedLegalCount,
      contactsMap.getAll('Legal').size(),
      'Incorrect number of returned contacts for Department "Legal"'
    );

    Integer expectedFinanceCount = contactsMap.getAll('Finance').size();

    List<Contact> financeContacts = (List<Contact>) contactsMap.removeAll(
      'Finance'
    );
    System.assertEquals(
      expectedFinanceCount,
      financeContacts.size(),
      'Incorrect number of records removed for Department "Finance"'
    );
    for (Contact financeContact : financeContacts) {
      System.assertEquals(
        'Finance',
        financeContact.Department,
        'Incorrect records were removed for Department "Finance"'
      );
    }
  }

  @isTest
  static void testSingleTypeMethods() {
    Account account = AccountTestFactory.createCustomer();
    List<Contact> contacts = ContactTestFactory.getContacts(3, account);

    BCMap contactsMap = new BCMap(contacts, 'Email');
    System.assert(contactsMap.isNotEmpty());
    System.assertEquals(
      contacts.size(),
      contactsMap.keySet().size(),
      'Incorrect number of map keys.'
    );

    List<SObject> actualValues = contactsMap.values();
    System.assertEquals(
      contacts.size(),
      actualValues.size(),
      'Collection sizes do not match.'
    );

    for (Contact contact : contacts) {
      System.assert(
        contactsMap.containsKey(contact.Email),
        'Contact Email "' + contact.Email + '" key missing from map.'
      );
      System.assertEquals(
        contact,
        (Contact) contactsMap.get(contact.Email),
        'Incorrect contact value associated with key "' + contact.Email + '"'
      );
    }

    Contact newContact = new Contact(Email = 'newcontact@bcmaptest.com');
    contactsMap.put(newContact);
    System.assert(
      contactsMap.containsKey('newcontact@bcmaptest.com'),
      'Contact Email key "newcontact@bcmaptest.com" missing from map.'
    );
    System.assertEquals(
      newContact,
      (Contact) contactsMap.get(newContact.Email),
      'Incorrect contact value associated with key "' + newContact.Email + '"'
    );

    System.assertEquals(
      newContact,
      (Contact) contactsMap.remove(newContact.Email),
      'Incorrect '
    );
  }

  @isTest
  static void testPolyKey() {
    Account account = AccountTestFactory.createCustomer();

    List<Contact> contacts = ContactTestFactory.getContacts(5, account);
    contacts[0].Department = 'IT';
    contacts[1].Department = 'IT';
    contacts[2].Department = 'IT';
    contacts[3].Department = 'Finance';
    contacts[4].Department = 'Finance';

    Map<String, List<Contact>> expectedMap = new Map<String, List<Contact>>();
    for (Contact contact : contacts) {
      String key = contact.LastName + contact.Department;
      if (!expectedMap.containsKey(key)) {
        expectedMap.put(key, new List<Contact>());
      }
      expectedMap.get(key).add(contact);
    }

    BCMap actualMap = new BCMap(
      contacts,
      new List<String>{ 'LastName', 'Department' }
    );
    for (String key : expectedMap.keySet()) {
      System.assert(actualMap.containsKey(key), key + ' key was not found.');
      Integer expected = expectedMap.get(key).size();
      Integer actual = actualMap.getAll(key).size();
      System.assertEquals(
        expected,
        actual,
        'Incorrect number of values for key ' + key
      );
    }
  }

  @isTest
  static void underloadedConstructorTest() {
    BCMap m = new BCMap('Department');
    m.put(new Contact(FirstName = 'IT Contact', Department = 'IT'));
    m.put(new Contact(FirstName = 'Finance Contact', Department = 'Finance'));

    Contact actual = (Contact) m.get('IT');
    System.assertEquals(
      'IT Contact',
      actual.FirstName,
      'Incorrect SObject returned.'
    );

    m = new BCMap(new List<String>{ 'Department' });
    m.put(new Contact(FirstName = 'IT Contact', Department = 'IT'));
    m.put(new Contact(FirstName = 'Finance Contact', Department = 'Finance'));

    actual = (Contact) m.get('Finance');
    System.assertEquals(
      'Finance Contact',
      actual.FirstName,
      'Incorrect SObject returned.'
    );
  }
}