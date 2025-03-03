@isTest(isparallel=true)
public with sharing class TriggerUtilityTest {
  @isTest
  private static void testIsChanged() {
    String stringField = 'Email';
    Contact newContact = new Contact(Email = 'newValue@value.com');
    Contact oldContact = new Contact(Email = 'oldValue@value.com');
    Boolean expected = true;
    Boolean actual = TriggerUtility.isChanged(
      newContact,
      oldContact,
      stringField
    );
    System.assertEquals(
      expected,
      actual,
      'String field parameter change not identified.'
    );

    Set<SObjectField> fields = new Set<SObjectField>{
      Contact.Email,
      Contact.FirstName
    };
    newContact = new Contact(
      Email = 'newContact@testIsChanged.com',
      FirstName = 'New'
    );
    oldContact = new Contact(
      Email = 'newContact@testIsChanged.com',
      FirstName = 'New'
    );

    expected = false;
    actual = TriggerUtility.isChanged(newContact, oldContact, fields);
    System.assertEquals(
      expected,
      actual,
      'Change in field values was not correctly identified.'
    );

    oldContact = new Contact(
      Email = 'oldContact@testIsChanged.com',
      FirstName = 'New'
    );

    expected = true;
    actual = TriggerUtility.isChanged(newContact, oldContact, Contact.Email);
    System.assertEquals(
      expected,
      actual,
      'Change in field values was not correctly identified.'
    );
  }

  @isTest
  private static void testGetChangedFields() {
    Set<SObjectField> fields = new Set<SObjectField>{
      Contact.Email,
      Contact.FirstName
    };
    Contact newContact = new Contact(
      Email = 'newContact@testIsChanged.com',
      FirstName = 'New'
    );
    Contact oldContact = new Contact(
      Email = 'newContact@testIsChanged.com',
      FirstName = 'New'
    );

    Set<SObjectField> changedFields = TriggerUtility.getChangedFields(
      newContact,
      oldContact,
      fields
    );

    System.assertEquals(
      0,
      changedFields.size(),
      'Identical records returned a changed field.'
    );

    newContact.FirstName = 'Newer';

    changedFields = TriggerUtility.getChangedFields(
      newContact,
      oldContact,
      fields
    );
    System.assertEquals(
      1,
      changedFields.size(),
      'Incorrect number of changed fields returned.'
    );
    System.assert(
      changedFields.contains(Contact.FirstName),
      'Incorrect SObjectField returned.'
    );
  }

  @isTest
  private static void testHasValues() {
    Contact testContact = new Contact(
      Email = 'testHasValues@example.com',
      LastName = 'testHasValues'
    );
    Boolean expected = true;
    Boolean actual = TriggerUtility.hasValues(
      testContact,
      new List<SObjectField>{ Contact.Email, Contact.LastName }
    );
    System.assertEquals(
      expected,
      actual,
      'Record was incorrectly identified as missing values.'
    );

    testContact.FirstName = null;

    expected = false;
    actual = TriggerUtility.hasValues(
      testContact,
      new List<SObjectField>{
        Contact.Email,
        Contact.LastName,
        Contact.FirstName
      }
    );
    System.assertEquals(
      expected,
      actual,
      'Record was incorrectly identified as having values.'
    );
  }
}