@IsTest
public with sharing class BatchContractRenewalQuoteTest {
  @TestSetup
  static void setupDate() {
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

    Account account = AccountTestFactory.createCustomer();

    List<Date> startDates = new List<Date>(getRandomStartDates(3));

    List<Contract> contracts = new List<Contract>();
    for (Integer i = 0; i < 3; i++) {
      contracts.add(
        new Contract(
          AccountId = account.Id,
          StartDate = startDates[i],
          ContractTerm = 12,
          Status = 'Draft'
        )
      );
    }

    insert contracts;
  }

  @IsTest
  public static void testBatch() {
    Account account = [
      SELECT Id, (SELECT Id, EndDate, SBQQ__RenewalQuoted__c FROM Contracts)
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      LIMIT 1
    ];

    List<Contract> contracts = account.Contracts;

    Test.startTest();
    BatchContractRenewalQuote contractBatch = new BatchContractRenewalQuote();
    Database.executeBatch(contractBatch);
    Test.stopTest();

    contracts = [
      SELECT Id, EndDate, SBQQ__RenewalQuoted__c
      FROM Contract
      WHERE Id IN :contracts
    ];

    for (Contract contract : contracts) {
      if (Date.today().daysBetween(contract.EndDate) <= 90) {
        System.assertEquals(
          true,
          contract.SBQQ__RenewalQuoted__c,
          'Renewal Quoted not checked when expected'
        );
      } else {
        System.assertEquals(
          false,
          contract.SBQQ__RenewalQuoted__c,
          'Renewal Quoted checked when not expected'
        );
      }
    }
  }

  private static Set<Date> getRandomStartDates(Integer size) {
    Set<Date> results = new Set<Date>();
    results.add(Date.today().addMonths(-10));

    while (results.size() < size) {
      Integer offset = (Integer) (Math.random() * 364.0);
      results.add(Date.today() - offset);
    }

    return results;
  }
}