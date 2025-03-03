@isTest(isparallel=true)
public with sharing class LiveEventCoverageDeleteHandlerTest {
  @TestSetup
  private static void makeData() {
    createAccounts();
    createLE();
  }

  @isTest
  private static void deleteLE() {
    Account accountRecord = [
      SELECT
        Id,
        Total_Live_Event_Support_hours_sold__c,
        Total_Live_Event_Support_hours_booked__c,
        Total_Live_Event_Support_hours_available__c
      FROM Account
      WHERE NAME = 'UATTestLiveEvent'
    ];

    Live_Event_Coverage__c lE = [
      SELECT Id, Full_Coverage_duration_hours__c, Hours_Covered_So_Far__c
      FROM Live_Event_Coverage__c
      WHERE
        Account__c = :accountRecord.Id
        AND Status__c NOT IN (
          'Closed - Completed [Business Hours]',
          'Closed - Completed [Off-Hours]',
          'Closed - Completed [Mixed]'
        )
      LIMIT 1
    ];

    test.startTest();
    delete lE;
    test.stopTest();

    Account accountRecordAfterDelete = [
      SELECT
        Id,
        Total_Live_Event_Support_hours_sold__c,
        Total_Live_Event_Support_hours_booked__c,
        Total_Live_Event_Support_hours_available__c
      FROM Account
      WHERE NAME = 'UATTestLiveEvent'
    ];

    System.assertEquals(
      accountRecordAfterDelete.Total_Live_Event_Support_hours_booked__c,
      accountRecord.Total_Live_Event_Support_hours_booked__c -
      LE.Full_Coverage_duration_hours__c,
      'LE Deletion: Live Event Hours Booked calculation unsuccessful '
    );

    System.assertEquals(
      accountRecordAfterDelete.Total_Live_Event_Support_hours_available__c,
      accountRecord.Total_Live_Event_Support_hours_available__c +
      LE.Full_Coverage_duration_hours__c,
      'LE Deletion: Live Event Hours Avaialble calculation unsuccessful'
    );
  }

  static void createLE() {
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
      Status__c = 'New',
      Live_Product__c = 'Brightcove Live',
      Timezone__c = '(GMT-10:00) Hawaii',
      BGS_Managed_Event__c = 'No',
      Test_Start_Time__c = Time.newInstance(10, 0, 0, 0),
      Test_End_Time__c = Time.newInstance(10, 30, 0, 0),
      Test_Date__c = Date.today(),
      Event_Start_Date__c = Date.today(),
      Event_End_Date__c = Date.today(),
      Event_Start_Time__c = Time.newInstance(1, 0, 0, 0),
      Event_End_Time__c = Time.newInstance(3, 0, 0, 0)
    );

    Live_Event_Coverage__c lErecord2 = new Live_Event_Coverage__c(
      Event_Point_Of_Contact__c = contactRecord.Id,
      Account__c = accountRecord,
      RecordTypeId = liveEventCoverageRecordTypeId,
      Status__c = 'Closed - Completed [Off-Hours]',
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
      Event_Start_Time__c = Time.newInstance(1, 0, 0, 0),
      Event_End_Time__c = Time.newInstance(3, 0, 0, 0)
    );

    Live_Event_Coverage__c lErecord3 = new Live_Event_Coverage__c(
      Event_Point_Of_Contact__c = contactRecord.Id,
      Account__c = accountRecord,
      RecordTypeId = liveEventCoverageRecordTypeId,
      Publisher_ID__c = '11111',
      Communication_Channel__c = 'Not yet defined',
      Live_Event_Category__c = 'Other',
      Number_of_concurrent_streams__c = 1,
      MAX_CCU_Estimated__c = 1,
      High_Profile__c = 'No',
      Status__c = 'New',
      Live_Product__c = 'Brightcove Live',
      Timezone__c = '(GMT-10:00) Hawaii',
      BGS_Managed_Event__c = 'No',
      Test_Start_Time__c = Time.newInstance(10, 0, 0, 0),
      Test_End_Time__c = Time.newInstance(10, 30, 0, 0),
      Test_Date__c = Date.today(),
      Event_Start_Date__c = Date.today(),
      Event_End_Date__c = Date.today(),
      Event_Start_Time__c = Time.newInstance(1, 0, 0, 0),
      Event_End_Time__c = Time.newInstance(3, 0, 0, 0)
    );

    List<Live_Event_Coverage__c> lEList = new List<Live_Event_Coverage__c>{
      lErecord,
      lErecord2,
      lErecord3
    };

    insert lEList;
  }

  private static void createAccounts() {
    Account customerAccount = AccountTestFactory.getCustomer();
    customerAccount.Name = 'UATTestLiveEvent';
    customerAccount.Account_Stage__c = 'Customer';
    customerAccount.Total_Live_Event_Support_hours_sold__c = 20;

    insert customerAccount;

    ContactTestFactory.createContact(customerAccount);
  }
}