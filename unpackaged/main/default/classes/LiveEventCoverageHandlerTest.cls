@isTest(isparallel=true)
private class LiveEventCoverageHandlerTest {
  @TestSetup
  private static void makeData() {
    createAccount();
  }

  @isTest
  private static void testCreateUpdateLes() {
    Account accountBEFORECreateLe = [
      SELECT
        Id,
        Total_Live_Event_Support_hours_sold__c,
        Total_Live_Event_Support_hours_booked__c,
        Total_Remaining_Hours_to__c,
        Total_Live_Event_Support_hours_available__c,
        Live_Event_Support_Hours_used__c
      FROM Account
      WHERE NAME = 'UATTestLiveEvent'
      LIMIT 1
    ];

    Test.startTest();
    createNewLEs();
    Test.stopTest();

    Account accountAFTERCreateLe = [
      SELECT
        Id,
        Total_Live_Event_Support_hours_sold__c,
        Total_Live_Event_Support_hours_booked__c,
        Total_Remaining_Hours_to__c,
        Total_Live_Event_Support_hours_available__c,
        Live_Event_Support_Hours_used__c
      FROM Account
      WHERE NAME = 'UATTestLiveEvent'
      LIMIT 1
    ];

    List<AggregateResult> results = [
      SELECT
        Account__c,
        SUM(Full_Coverage_duration_hours__c) hoursBooked,
        SUM(Remaining_Hours_to_cover__c) hoursRemaining,
        SUM(Hours_Covered_So_Far__c) hoursUsed
      FROM Live_Event_Coverage__c
      WHERE
        Account__c = :accountAFTERCreateLe.ID
        AND (NOT Status__c LIKE '%Completed%')
      GROUP BY Account__c
    ];

    Map<Id, Decimal> accountBookedHours = new Map<Id, Decimal>();
    Map<Id, Decimal> accountRemainingHours = new Map<Id, Decimal>();

    for (AggregateResult result : results) {
      accountBookedHours.put(
        (Id) result.get('Account__c'),
        (Decimal) result.get('hoursBooked')
      );
      accountRemainingHours.put(
        (Id) result.get('Account__c'),
        (Decimal) result.get('hoursBooked')
      );
    }

    System.assertEquals(
      accountAFTERCreateLe.Total_Live_Event_Support_hours_booked__c,
      accountBEFORECreateLe.Total_Live_Event_Support_hours_booked__c +
      accountBookedHours.get(accountAFTERCreateLe.Id),
      'Account: Total Live Event Hours Booked error'
    );

    System.assertEquals(
      accountAFTERCreateLe.Total_Remaining_Hours_to__c,
      accountRemainingHours.get(accountAFTERCreateLe.Id),
      'Account: Total Live Event Hours Remaining error'
    );

    System.assertEquals(
      accountAFTERCreateLe.Total_Live_Event_Support_hours_available__c,
      accountBEFORECreateLe.Total_Live_Event_Support_hours_available__c -
      accountBookedHours.get(accountAFTERCreateLe.Id),
      'Account: Total Live Hours Available error 2'
    );

    System.assertEquals(
      accountAFTERCreateLe.Total_Live_Event_Support_hours_available__c,
      accountAFTERCreateLe.Total_Live_Event_Support_hours_sold__c -
        accountAFTERCreateLe.Total_Live_Event_Support_hours_booked__c -
        accountAFTERCreateLe.Live_Event_Support_Hours_used__c,
      'Account: Total Live Event Hours Available error'
    );
    System.assertEquals(
      accountAFTERCreateLe.Live_Event_Support_Hours_used__c,
      accountBEFORECreateLe.Live_Event_Support_Hours_used__c,
      'Account: Total Live Event hours USED error on creation of LEs'
    );
  }
  @istest
  private static void testCompleteLEs() {
    List<String> qualifiedStatuses = new List<String>{
      'Closed - Completed [Business Hours]',
      'Closed - Completed [Off-Hours]',
      'Closed - Completed [Mixed]'
    };

    createNewLEs();

    Account accountBEFORE = [
      SELECT
        Id,
        Total_Live_Event_Support_hours_sold__c,
        Total_Live_Event_Support_hours_booked__c,
        Total_Remaining_Hours_to__c,
        Total_Live_Event_Support_hours_available__c,
        Total_Live_Support_Events__c,
        Live_Event_Support_Hours_used__c
      FROM Account
      WHERE NAME = 'UATTestLiveEvent'
      LIMIT 1
    ];

    test.startTest();
    completeLEs();
    test.stopTest();

    Account accountAFTER = [
      SELECT
        Id,
        Total_Live_Event_Support_hours_sold__c,
        Total_Live_Event_Support_hours_booked__c,
        Total_Live_Support_Events__c,
        Total_Remaining_Hours_to__c,
        Total_Live_Event_Support_hours_available__c,
        Live_Event_Support_Hours_used__c
      FROM Account
      WHERE NAME = 'UATTestLiveEvent'
      LIMIT 1
    ];

    List<AggregateResult> results = [
      SELECT
        COUNT(Id) nEvents,
        Account__c,
        SUM(Full_Coverage_duration_hours__c) hoursBooked,
        SUM(Hours_Covered_So_Far__c) hoursUsed
      FROM Live_Event_Coverage__c
      WHERE Account__c = :accountAFTER.Id AND Status__c IN :qualifiedStatuses
      GROUP BY Account__c
    ];

    Map<Id, Decimal> accountNEvents = new Map<Id, Decimal>();
    Map<Id, Decimal> accountHoursBooked = new Map<Id, Decimal>();
    Map<Id, Decimal> accountHoursUsed = new Map<Id, Decimal>();

    for (AggregateResult result : results) {
      accountNEvents.put(
        (Id) result.get('Account__c'),
        (Decimal) result.get('nevents')
      );
      accountHoursBooked.put(
        (Id) result.get('Account__c'),
        (Decimal) result.get('hoursBooked')
      );
      accountHoursUsed.put(
        (Id) result.get('Account__c'),
        (Decimal) result.get('hoursUsed')
      );
    }

    System.assertEquals(
      accountAFTER.Total_Live_Support_Events__c,
      accountNEvents.get(accountAFTER.Id),
      'Account Closed LEs: Number of Completed event calculation error'
    );

    System.assert(
      accountAFTER.Total_Live_Support_Events__c >
      accountBEFORE.Total_Live_Support_Events__c,
      'Account Closed LEs: Number of Completed event calculation error'
    );

    System.assertEquals(
      accountAFTER.Total_Live_Event_Support_hours_available__c,
      accountAFTER.Total_Live_Event_Support_hours_sold__c -
        accountAFTER.Total_Live_Event_Support_hours_booked__c -
        AccountAFTER.Live_Event_Support_Hours_used__c,
      'Account Closed LEs: Number of Total Live Event hours available error'
    );
  }

  private static void createAccount() {
    Account customerAccount = AccountTestFactory.getCustomer();
    customerAccount.Name = 'UATTestLiveEvent';
    customerAccount.Account_Stage__c = 'Customer';
    customerAccount.Total_Live_Event_Support_hours_sold__c = 10;

    insert customerAccount;

    ContactTestFactory.createContact(customerAccount);
  }

  private static void completeLEs() {
    Id accountRecordId = [
      SELECT Id
      FROM Account
      WHERE name = 'UATTestLiveEvent'
      LIMIT 1
    ]
    .Id;

    Live_Event_Coverage__c lErecord = [
      SELECT Id, Status__c
      FROM Live_Event_Coverage__c
      WHERE Account__c = :accountRecordId AND (NOT Status__c LIKE '%Completed%')
      LIMIT 1
    ];

    User nOCEng = [
      SELECT Id
      FROM User
      WHERE isActive = TRUE AND UserRole.name = 'Technical Support Rep'
      LIMIT 1
    ];

    Live_Event_Coverage_Timing__c lEtiming = new Live_Event_Coverage_Timing__c(
      Off_Hours_Covered__c = 0,
      CoverageLink__c = lErecord.Id,
      Coverage_Engineer__c = nOCEng.Id,
      Start_of_Coverage__c = Datetime.newInstance(2024, 2, 1, 10, 30, 0),
      End_of_Coverage__c = Datetime.newInstance(2024, 2, 1, 11, 30, 0)
    );

    insert lEtiming;

    lErecord.Status__c = 'Closed - Completed [Mixed]';
    update lErecord;
  }

  private static void createNEWLEs() {
    Id accountRecord = [
      SELECT Id
      FROM Account
      WHERE name = 'UATTestLiveEvent'
      LIMIT 1
    ]
    .Id;

    Contact contactRecord = [
      SELECT Id
      FROM Contact
      WHERE AccountId = :accountRecord
      LIMIT 1
    ];

    Id liveEventCoverageRecordTypeId = RecordTypeUtility.getId(
      Live_Event_Coverage__c.getSObjectType(),
      'Live Event Support'
    );

    Live_Event_Coverage__c lErecord = new Live_Event_Coverage__c(
      Event_Point_Of_Contact__c = contactRecord.Id,
      Account__c = accountRecord,
      RecordTypeId = liveEventCoverageRecordTypeId,
      Publisher_ID__c = '11111',
      Communication_Channel__c = 'Not yet defined',
      Live_Event_Category__c = 'Other',
      Number_of_concurrent_streams__c = 1,
      MAX_CCU_Estimated__c = 1,
      High_Profile__c = 'No',
      Live_Product__c = 'Brightcove Live',
      Timezone__c = '(GMT-10:00) Hawaii',
      Status__c = 'New',
      BGS_Managed_Event__c = 'No',
      Test_Start_Time__c = Time.newInstance(10, 0, 0, 0),
      Test_End_Time__c = Time.newInstance(10, 30, 0, 0),
      Test_Date__c = Date.today(),
      Event_Start_Date__c = Date.today(),
      Event_End_Date__c = Date.today(),
      Event_Start_Time__c = Time.newInstance(9, 0, 0, 0),
      Event_End_Time__c = Time.newInstance(11, 0, 0, 0)
    );
    Live_Event_Coverage__c lErecord2 = new Live_Event_Coverage__c(
      Event_Point_Of_Contact__c = contactRecord.Id,
      Account__c = accountRecord,
      RecordTypeId = liveEventCoverageRecordTypeId,
      Status__c = 'New',
      Publisher_ID__c = '11111',
      Communication_Channel__c = 'Not yet defined',
      Live_Event_Category__c = 'Other',
      Number_of_concurrent_streams__c = 1,
      MAX_CCU_Estimated__c = 1,
      High_Profile__c = 'No',
      Live_Product__c = 'Brightcove Live',
      Timezone__c = '(GMT-10:00) Hawaii',
      BGS_Managed_Event__c = 'No',
      Test_Start_Time__c = Time.newInstance(10, 0, 0, 0),
      Test_End_Time__c = Time.newInstance(10, 30, 0, 0),
      Test_Date__c = Date.today(),
      Event_Start_Date__c = Date.today(),
      Event_End_Date__c = Date.today(),
      Event_Start_Time__c = Time.newInstance(9, 0, 0, 0),
      Event_End_Time__c = Time.newInstance(13, 0, 0, 0)
    );

    List<Live_Event_Coverage__c> lEList = new List<Live_Event_Coverage__c>{
      lErecord,
      lErecord2
    };
    insert lEList;
  }
}