@isTest
public class OpportunityNameHandlerTest {
  @TestSetup
  private static void setupData() {
    User user = TestUserProvisioner.getNewUser();
    insert user;

    TestUserProvisioner provisioner = new TestUserProvisioner(user.Id);
    provisioner.setPermissions(
      new List<String>{
        'Opportunity_RecordType_Add_On',
        'Opportunity_RecordType_New_Business',
        'Opportunity_RecordType_Professional_Services',
        'Opportunity_RecordType_Renewal'
      }
    );
    provisioner.assignPermissions();

    // A "long name" in this context should exceed 80 characters.
    String longName = 'Long Name 12345678901234567890123456789012345678901234567890 OpportunityNameHandler';
    String shortName = 'Short Name OpportunityNameHandler';

    List<Account> accounts = AccountTestFactory.getCustomers(2);
    accounts[0].Name = shortName;
    accounts[1].Name = longName;

    insert accounts;
  }

  @isTest
  private static void testSetOppName() {
    Map<Id, Account> accounts = new Map<Id, Account>(
      [
        SELECT Id, Name
        FROM Account
        WHERE Name LIKE 'Short Name%' OR Name LIKE 'Long Name%'
      ]
    );

    List<Id> recordTypeIds = new List<Id>{
      RecordTypeUtility.getId(Opportunity.getSobjectType(), 'New Business'),
      RecordTypeUtility.getId(Opportunity.getSobjectType(), 'Renewal'),
      RecordTypeUtility.getId(Opportunity.getSobjectType(), 'Add-On'),
      RecordTypeUtility.getId(
        Opportunity.getSobjectType(),
        'Professional Services'
      )
    };

    List<Opportunity> opps = new List<Opportunity>();
    for (Id accountId : accounts.keySet()) {
      for (Id recordTypeId : recordTypeIds) {
        Opportunity opp = OpportunityTestFactory.getStage1Opp(accountId);
        opp.RecordTypeId = recordTypeId;
        opps.add(opp);
      }
    }
    insert opps;

    Test.startTest();

    opps = [
      SELECT Id, Name, Account.Name, RecordType.Name, CloseDate
      FROM Opportunity
      WHERE Id IN :opps
    ];

    for (Opportunity opp : opps) {
      String accountName = opp.Account.Name;
      if (accountName.startsWith('Long Name')) {
        accountName = accountName.left(80).trim();
      }
      String dateComponent =
        String.valueOf(opp.CloseDate.month()) +
        '/' +
        String.valueOf(opp.CloseDate.day()) +
        '/' +
        String.valueOf(opp.CloseDate.year());
      String expectedName =
        accountName +
        ' - ' +
        opp.RecordType.Name +
        ' - ' +
        dateComponent;

      System.assertEquals(
        expectedName,
        opp.Name,
        'Opportunity Name not correctly set at creation.'
      );

      opp.CloseDate = opp.CloseDate.addDays(1);
    }

    update opps;

    Test.stopTest();

    opps = [
      SELECT Id, Name, Account.Name, RecordType.Name, CloseDate
      FROM Opportunity
      WHERE Id IN :opps
    ];

    for (Opportunity opp : opps) {
      String accountName = opp.Account.Name;
      if (accountName.startsWith('Long Name')) {
        accountName = accountName.left(80).trim();
      }
      String dateComponent =
        String.valueOf(opp.CloseDate.month()) +
        '/' +
        String.valueOf(opp.CloseDate.day()) +
        '/' +
        String.valueOf(opp.CloseDate.year());

      String expectedName =
        accountName +
        ' - ' +
        opp.RecordType.Name +
        ' - ' +
        dateComponent;

      System.assertEquals(
        expectedName,
        opp.Name,
        'Opportunity Name not correctly set after update.'
      );
    }
  }

  @isTest
  private static void testDuplicatePrevention() {
    Account account = [
      SELECT Id, Name
      FROM Account
      WHERE RecordType.Name = 'Customer'
      LIMIT 1
    ];

    List<Opportunity> opps = new List<Opportunity>();
    List<Id> recordTypeIds = new List<Id>{
      RecordTypeUtility.getId(Opportunity.getSobjectType(), 'New Business'),
      RecordTypeUtility.getId(Opportunity.getSobjectType(), 'Renewal'),
      RecordTypeUtility.getId(Opportunity.getSobjectType(), 'Add-On'),
      RecordTypeUtility.getId(
        Opportunity.getSobjectType(),
        'Professional Services'
      )
    };

    for (Id recordTypeId : recordTypeIds) {
      opps.add(OpportunityTestFactory.getStage1Opp(account.Id, recordTypeId));
    }

    Test.startTest();

    insert opps;

    Test.stopTest();

    Database.SaveResult result = Database.insert(
      OpportunityTestFactory.getStage1Opp(account.Id, recordTypeIds[0]),
      false
    );

    System.assertEquals(
      false,
      result.isSuccess(),
      'Duplicate record was inserted.'
    );
    String expectedDateComponent =
      String.valueOf(Date.today().month()) +
      '/' +
      String.valueOf(Date.today().day()) +
      '/' +
      String.valueOf(Date.today().year());

    String expectedError =
      'An Opportunity with the name "' +
      account.Name +
      ' - New Business - ' +
      expectedDateComponent +
      '" already exists.';
    System.assertEquals(
      expectedError,
      result.getErrors()[0].getMessage(),
      'Incorrect error message returned.'
    );
  }
}