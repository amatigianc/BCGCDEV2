@IsTest
public with sharing class ScheduleContractRenewalQuoteTest {
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

    //ensures no duplicates, so no errors on renewal opps creating
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
  public static void testScheduledJob() {
    Test.startTest();

    String jobId = System.schedule(
      'testScheduleContractRenewalQuote',
      ScheduleContractRenewalQuote.CRON_EXP,
      new ScheduleContractRenewalQuote()
    );

    CronTrigger ct = [
      SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger
      WHERE Id = :jobId
    ];

    System.assertEquals(
      ScheduleContractRenewalQuote.CRON_EXP,
      ct.CronExpression
    );

    System.assertEquals(0, ct.TimesTriggered);

    DateTime nextRun = DateTime.newInstance(
      Date.today() + 1,
      Time.newInstance(0, 0, 0, 0)
    );
    System.assertEquals(nextRun, ct.NextFireTime);

    Test.stopTest();
  }

  //we need to generate a set of random start dates that will both produce a date
  //where the end will be within 90 days and not within 90 days of today
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