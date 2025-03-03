@IsTest
public with sharing class ContractRenewalHandlerTest {
  @TestSetup
  static void setupData() {
    TestUserProvisioner provisioner = new TestUserProvisioner(
      UserInfo.getUserId()
    );
    provisioner.setLicenses(
      new List<String>{ 'SalesforceCPQ_CPQStandardPerm' }
    );
    provisioner.setPermissions(
      new List<String>{ 'CPQ_Global', 'Global_Read', 'SteelBrickCPQUser' }
    );
    provisioner.assignPermissions();

    AccountTestFactory.createCustomer();
  }

  @IsTest
  public static void testContractRenewal() {
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];
    Contract newContract = new Contract(
      AccountId = account.Id,
      StartDate = System.today(),
      ContractTerm = 12,
      Status = 'Draft'
    );

    insert newContract;

    Test.startTest();

    newContract.Status = 'Activated';
    update newContract;

    Test.stopTest();

    newContract = [
      SELECT Id, SBQQ__RenewalForecast__c
      FROM Contract
      WHERE Id = :newContract.Id
    ];

    System.assertEquals(
      true,
      newContract.SBQQ__RenewalForecast__c,
      'Renewal Forecast was not checked'
    );
  }
}