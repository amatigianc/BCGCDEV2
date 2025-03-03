/* Description: it's a schedule job APEX that updates the live event support hours sold (Active) field on the Account object
 * based on the list of active subscriptions
 * SObject: Subscriptions
 * Events: Scheduled job once a day
 * Misc: To Launch the scheduled job open the Developer Console, Debug Execute Anonymous Window and paste the following lines:
 *
 * LiveEventSupportHoursActiveSubscriptions l = new LiveEventSupportHoursActiveSubscriptions();
 * string t = '00 26 * * * ?';
 * string jobID = System.schedule('LiveEventHoursUpdate', t, l);
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class SubscriptionsLiveEventSupportHoursActive implements Schedulable {
  Map<Id, List<SBQQ__Subscription__c>> accountIdWithSubscription = new Map<Id, List<SBQQ__Subscription__c>>();
  List<String> liveEventProducts = new List<String>{
    'Live Streaming Special Event Support',
    'Live Event Support Hours'
  };

  List<String> supportPackagesProducts = new List<String>{
    'Silver Support',
    'Silver Support Package',
    'Gold Support',
    'Gold Support Package',
    'Platinum Support',
    'Platinum Support Package',
    'Platinum Plus Support',
    'Platinum Plus Support Package',
    'Platinum Plus Support Upgrade',
    'Platinum Plus Support Package Upgrade'
  };

  global void execute(SchedulableContext sc) {
    try {
      qualifyAccount();
      updateAccountLiveEventHoursActive();
    } catch (Exception e) {
      ExceptionHandler.process(e, 'LiveEventSupportHoursActiveSubscriptions');
    }
  }

  private void updateAccountLiveEventHoursActive() {
    List<Account> accounts = [
      SELECT
        Id,
        Live_Event_Support_hours_Active__c,
        Total_Live_Event_Support_hours_sold__c
      FROM Account
      WHERE Id IN :accountIdWithSubscription.keySet()
    ];
    for (Account account : accounts) {
      Decimal totalLiveEventHoursSupportActive = 0;
      List<SBQQ__Subscription__c> subscriptions = accountIdWithSubscription.get(
        account.Id
      );

      for (SBQQ__Subscription__c subscription : subscriptions) {
        Decimal quantity = 0;
        switch on subscription.SBQQ__ProductName__c {
          when 'Gold Support', 'Gold Support Package' {
            quantity = 4.0;
          }
          when 'Platinum Support',
            'Platinum Support Package',
            'Platinum Plus Support',
            'Platinum Plus Support Upgrade',
            'Platinum Plus Support Package Upgrade' {
            quantity = 12.0;
          }
          when 'Live Streaming Special Event Support',
            'Live Event Support Hours' {
            quantity = subscription.SBQQ__Quantity__c;
          }
          when else {
            quantity = 0.0;
          }
        }
        totalLiveEventHoursSupportActive += quantity;
      }
      account.Live_Event_Support_hours_Active__c = totalLiveEventHoursSupportActive;

      if (
        account.Total_Live_Event_Support_hours_sold__c == 0 ||
        account.Total_Live_Event_Support_hours_sold__c == null
      ) {
        account.Total_Live_Event_Support_hours_sold__c = totalLiveEventHoursSupportActive;
      }
    }
    update accounts;
  }

  private void qualifyAccount() {
    List<Account> accounts = [
      SELECT
        Id,
        (
          SELECT Id, SBQQ__ProductName__c, SBQQ__Quantity__c, SBQQ__EndDate__c
          FROM SBQQ__Subscriptions__r
          WHERE
            (SBQQ__Product__r.Name IN :liveEventProducts
            OR SBQQ__Product__r.Name IN :supportPackagesProducts)
            AND SBQQ__StartDate__c <= TODAY
            AND SBQQ__EndDate__c >= TODAY
            AND SBQQ__Quantity__c > 0
        )
      FROM Account
      WHERE
        RecordType.Name = 'Customer'
        AND Account_Stage__c = 'Customer'
        AND Id IN (
          SELECT SBQQ__Account__c
          FROM SBQQ__Subscription__c
          WHERE
            (SBQQ__Product__r.Name IN :liveEventProducts
            OR SBQQ__Product__r.Name IN :supportPackagesProducts)
            AND SBQQ__EndDate__c = :System.today().addDays(-1)
            AND SBQQ__Quantity__c > 0
        )
    ];

    for (Account account : accounts) {
      List<SBQQ__Subscription__c> subscriptions = new List<SBQQ__Subscription__c>();
      for (SBQQ__Subscription__c suscription : account.SBQQ__Subscriptions__r) {
        subscriptions.add(suscription);
      }
      accountIdWithSubscription.put(account.Id, subscriptions);
    }
  }
}