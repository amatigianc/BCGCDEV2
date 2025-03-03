@IsTest(isparallel=true)
public with sharing class RecordControllerTest {
  @testSetup
  static void makeData() {
    Account account = AccountTestFactory.getCustomer();
    account.GUID__c = GuidUtility.generateGuid();
    insert account;
  }

  @isTest
  static void validateAndRedirectTest() {
    Account account = [SELECT Id, GUID__c FROM Account LIMIT 1];
    Test.setFixedSearchResults(new List<Id>{ account.Id });
    PageReference pageRef = Page.Record;
    pageRef.getParameters().put('id', account.GUID__c);

    Test.setCurrentPage(pageRef);

    PageReference retPageRef = RecordController.validateAndRedirect();
    String actualUrl = retPageRef.getUrl();
    String expectedUrl =
      Url.getSalesforceBaseUrl().toExternalForm() +
      '/' +
      account.Id;
    System.assertEquals(
      expectedUrl,
      actualUrl,
      'Redirect Url not correctly returned.'
    );
  }
}