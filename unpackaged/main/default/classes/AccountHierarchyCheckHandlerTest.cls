@isTest
public class AccountHierarchyCheckHandlerTest {
  @TestSetup
  static void setupPermissions() {
    TestUserProvisioner provisioner = new TestUserProvisioner(
      UserInfo.getUserId()
    );
    provisioner.setPermission('Account_Read_Global');
    provisioner.assignPermissions();
  }

  @isTest
  static void testSetPendingHierarchyReview() {
    List<Account> accounts = AccountTestFactory.createCustomers(2);

    accounts.add(AccountTestFactory.createPartner());

    Test.startTest();

    accounts = [
      SELECT Id, RecordType.Name, ParentId, Pending_Hierarchy_Review__c
      FROM Account
      WHERE Id IN :accounts
    ];

    for (Account account : accounts) {
      Boolean expected = account.RecordType.Name == 'Customer' ? true : false;
      System.assertEquals(
        expected,
        account.Pending_Hierarchy_Review__c,
        'Pending Hierarchy Review was not set correct for ' +
        account.RecordType.Name
      );
      account.Pending_Hierarchy_Review__c = false;
    }

    accounts[0].ParentId = accounts[1].Id;
    update accounts;

    Test.stopTest();

    Account childAccount = [
      SELECT Id, Pending_Hierarchy_Review__c
      FROM Account
      WHERE Id = :accounts[0].Id
    ];

    System.assertEquals(
      true,
      childAccount.Pending_Hierarchy_Review__c,
      'Pending Hierarchy Review was not set on an updated child Customer Account'
    );
  }

  private static Boolean hasRequiredPermissionSet() {
    Id userId = UserInfo.getUserId();

    List<PermissionSetAssignment> currentAssignments = [
      SELECT Id, PermissionSet.Name, PermissionSetId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :userId AND PermissionSet.Name = 'Account_Read_Global'
    ];

    return currentAssignments.size() > 0;
  }
}