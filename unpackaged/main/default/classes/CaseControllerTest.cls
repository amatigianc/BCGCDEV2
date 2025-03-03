@IsTest(isparallel=true)
public with sharing class CaseControllerTest {
  /*
   * @MethodName InsertMethod()
   * @author Sowdhanya Karri
   * @date June 2016
   * @description InsertMethod() method is written to setup testdata for Account,Contact,Videos,Video Items,and Video Activity to test the insertion of record into Video activities.
   */
  @IsTest
  static void testGetCaseDetails() {
    Account account = AccountTestFactory.createCustomer();
    Case newCase = new Case(Origin = 'Email', AccountId = account.Id);
    insert newCase;
    CaseController.getCaseDetails(newCase.Id);
    newCase = [
      SELECT Request_closure__c, Priority, E2CP__AdditionalCC__c
      FROM Case
      WHERE ID = :newCase.Id
    ];
    System.assertEquals(
      true,
      newCase.Priority != null,
      'Priority is: ' + newCase.Priority
    );
    System.assertEquals(
      true,
      newCase.Request_closure__c != null,
      'Request_closure__c is: ' + newCase.Request_closure__c
    );
    CaseController.componentAvailable(UserInfo.getUserId());
  }
  @IsTest
  static void testRequestClosure() {
    Account account = AccountTestFactory.createCustomer();
    Case newCase = new Case(Origin = 'Email', AccountId = account.Id);
    insert newCase;
    newCase = [SELECT Request_closure__c FROM Case WHERE ID = :newCase.Id];
    System.assertEquals(
      false,
      newCase.Request_closure__c,
      'newCase.Request_closure__c is: ' + newCase.Request_closure__c
    );
    CaseController.requestClosure(newCase.Id);
    newCase = [SELECT Request_closure__c FROM Case WHERE ID = :newCase.Id];
    System.assertEquals(
      true,
      newCase.Request_closure__c,
      'newCase.Request_closure__c is: ' + newCase.Request_closure__c
    );
  }

  @IsTest
  static void testUpdatePriority() {
    Account account = AccountTestFactory.createCustomer();
    Case newCase = new Case(
      Priority = 'P3',
      Origin = 'Email',
      AccountId = account.Id
    );
    insert newCase;
    newCase = [SELECT Priority FROM Case WHERE ID = :newCase.Id];
    System.assertEquals(
      true,
      newCase.Priority == 'P3',
      'newCase.Priority is: ' + newCase.Priority
    );
    CaseController.updatePriority(newCase.Id, 'P2');
    newCase = [SELECT Priority FROM Case WHERE ID = :newCase.Id];
    System.assertEquals(
      true,
      newCase.Priority == 'P2',
      'newCase.Priority is: ' + newCase.Priority
    );
  }
}