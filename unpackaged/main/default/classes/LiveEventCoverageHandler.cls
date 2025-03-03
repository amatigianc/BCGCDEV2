/**
 *  This trigger reacts to the creation and update of a Live_Event_Coverage__c record and recalculates
 *  the information about the number of live event hours available on the account
 *  SObject Live_Event_Coverage__c
 *  Event After_Insert, After_Update
 */

public with sharing class LiveEventCoverageHandler extends DomainLogicHandler {
  List<Id> accountIds = new List<Id>();
  Map<Id, Account> accounts = new Map<Id, Account>();

  public override void check(SObject newobj) {
    Live_Event_Coverage__c liveEventCoverage = (Live_Event_Coverage__c) newobj;

    if (isQualifiedRecordType(newobj)) {
      accountIds.add(liveEventCoverage.Account__c);
    }
  }

  public override void check(SObject newobj, SObject oldobj) {
    Live_Event_Coverage__c liveEventCoverage = (Live_Event_Coverage__c) newobj;
    if (isQualifiedRecordType(newobj)) {
      accountIds.add(liveEventCoverage.Account__c);
    }
  }

  public override void processRecords() {
    for (Id accountId : accountIds) {
      accounts.put(
        accountId,
        new Account(
          Id = accountId,
          Total_Live_Event_Support_hours_booked__c = 0,
          Total_Remaining_Hours_to__c = 0,
          Total_Live_Support_Events__c = 0,
          Live_Event_Support_Hours_used__c = 0
        )
      );
    }

    accountOpenLEsUpdate();
    accountCompletedLEsUpdate();
    update accounts.values();
  }

  private void accountOpenLEsUpdate() {
    List<String> unqualifiedStatuses = new List<String>{
      'Closed - Rejected',
      'Closed - Completed [Business Hours]',
      'Closed - Completed [Off-Hours]',
      'Closed - Completed [Mixed]'
    };

    List<AggregateResult> resultsBookedHoursToUpdate = [
      SELECT
        Account__c,
        SUM(Full_Coverage_duration_hours__c) totalBookedHours,
        SUM(Remaining_Hours_to_cover__c) pendingHours
      FROM Live_Event_Coverage__c
      WHERE
        Account__c = :accountIds
        AND Status__c NOT IN :unqualifiedStatuses
        AND Pro_Bono__c = FALSE
      GROUP BY Account__c
    ];

    for (AggregateResult results : resultsBookedHoursToUpdate) {
      Id accountId = (Id) results.get('Account__c');

      Account account = accounts.get(accountId);
      account.Total_Live_Event_Support_hours_booked__c = (Decimal) results.get(
        'totalBookedHours'
      );
      account.Total_Remaining_Hours_to__c = (Decimal) results.get(
        'pendingHours'
      );

      accounts.put(accountId, account);
    }
  }

  private void accountCompletedLEsUpdate() {
    List<String> qualifiedStatuses = new List<String>{
      'Closed - Completed [Business Hours]',
      'Closed - Completed [Off-Hours]',
      'Closed - Completed [Mixed]'
    };

    List<AggregateResult> resultsAccountNEventsToUpdate = [
      SELECT
        Count(Id) nEvents,
        SUM(Hours_Covered_So_Far__c) hoursUsed,
        Account__c
      FROM Live_Event_Coverage__c
      WHERE
        Account__c = :accountIds
        AND Status__c IN :qualifiedStatuses
        AND Status__c != 'Closed - Rejected'
        AND Pro_Bono__c = FALSE
      GROUP BY Account__c
    ];

    for (AggregateResult results : resultsAccountNEventsToUpdate) {
      Id accountId = (Id) results.get('Account__c');

      Account account = accounts.get(accountId);

      account.Total_Live_Support_Events__c = (Decimal) results.get('nEvents');
      account.Live_Event_Support_Hours_used__c = (Decimal) results.get(
        'hoursUsed'
      );

      accounts.put(accountId, account);
    }
  }

  private Boolean isQualifiedRecordType(SObject newObj) {
    return RecordTypeUtility.getName((Live_Event_Coverage__c) newObj)
      .equals('Live Event Support');
  }
}