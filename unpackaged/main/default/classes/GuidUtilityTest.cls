@isTest(isparallel=true)
public with sharing class GuidUtilityTest {
  @isTest
  private static void testGenerateGuid() {
    String guid = GuidUtility.generateGuid();
    System.assertNotEquals(null, guid, 'Null value returned.');
    System.assertEquals(36, guid.length(), 'Guid value is incorrect length');
  }

  @isTest
  private static void testGetGuidMap() {
    Account account = AccountTestFactory.createCustomer();

    account = [SELECT Id, GUID__c FROM Account WHERE Id = :account.Id];

    System.assertNotEquals(
      null,
      account.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      account.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    Test.setFixedSearchResults(new List<Id>{ account.Id });
    List<String> guids = new List<String>{ account.GUID__c };

    Map<String, Id> guidIdMap = GuidUtility.getGuidMap(guids);

    System.assertEquals(
      guids.size(),
      guidIdMap.size(),
      'Incorrect number of results returned.'
    );
  }
}