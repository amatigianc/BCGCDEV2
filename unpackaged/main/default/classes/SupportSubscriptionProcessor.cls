public with sharing class SupportSubscriptionProcessor {
  static Map<String, String> qualifiedProducts = new Map<String, String>{
    'Silver Support' => 'Silver',
    'Silver Support Package' => 'Silver',
    'Gold Support' => 'Gold',
    'Gold Support Package' => 'Gold',
    'Platinum Support' => 'Platinum',
    'Platinum Support Package' => 'Platinum',
    'Platinum Plus Support' => 'Platinum+',
    'Platinum Plus Support Package Upgrade' => 'Platinum+',
    'Platinum Plus Support Upgrade' => 'Platinum+',
    'Live Streaming Special Event Support' => '',
    'Live Event Support Hours' => ''
  };

  static Map<String, Decimal> productSupportPackageQuantities = new Map<String, Decimal>{
    'Silver Support' => 0,
    'Silver Package' => 0,
    'Gold Support' => 4,
    'Gold Support Package' => 4,
    'Platinum Support' => 12,
    'Platinum Support Package' => 12,
    'Platinum Plus Support' => 12,
    'Platinum Plus Support Upgrade' => 12,
    'Platinum Plus Support Package Upgrade' => 12
  };

  public static void process(Set<Id> accountIds) {
    List<Account> accounts = getAccounts(accountIds);

    List<String> qualifiedProductNames = new List<String>(
      qualifiedProducts.keySet()
    );

    List<Entitlement> entitlements = new List<Entitlement>();

    for (Account account : accounts) {
      List<SBQQ__Subscription__c> subscriptions = account.SBQQ__Subscriptions__r;

      String prioritySupportPackage = qualifiedProducts.get(
        qualifiedProductNames[0]
      );

      Decimal hours = 0;
      Decimal tmpHours = 0;
      Integer priority = 0;

      for (SBQQ__Subscription__c subscription : subscriptions) {
        if (
          productSupportPackageQuantities.containsKey(
            subscription.SBQQ__ProductName__c
          )
        ) {
          Integer index = qualifiedProductNames.indexOf(
            subscription.SBQQ__ProductName__c
          );
          entitlements.add(
            EntitlementProcessor.getEntitlement(
              account,
              subscription.SBQQ__ProductName__c,
              subscription.SBQQ__StartDate__c,
              subscription.SBQQ__EndDate__c
            )
          );

          if (index > priority) {
            priority = index;

            prioritySupportPackage = qualifiedProducts.get(
              subscription.SBQQ__ProductName__c
            );
            tmpHours += productSupportPackageQuantities.get(
              subscription.SBQQ__ProductName__c
            );
          }
        } else {
          hours += subscription.SBQQ__Quantity__c;
        }
      }

      account.Total_Live_Event_Support_hours_sold__c = hours + tmpHours;

      account.Support_Package__c = prioritySupportPackage;
      account.Platinum_Alerts_Active__c = prioritySupportPackage.contains(
        'Platinum'
      );
    }

    try {
      update accounts;
      insert entitlements;
    } catch (Exception e) {
      ExceptionHandler.process(e, 'SupportSubscriptionProcessor');
    }
  }

  static List<Account> getAccounts(Set<Id> accountIds) {
    return [
      SELECT
        Id,
        Support_package__c,
        Sales_Division__c,
        Platinum_Alerts_Active__c,
        Total_Live_Event_Support_hours_sold__c,
        (
          SELECT
            Id,
            SBQQ__ProductName__c,
            SBQQ__Quantity__c,
            SBQQ__Account__c,
            SBQQ__StartDate__c,
            SBQQ__EndDate__c
          FROM SBQQ__Subscriptions__r
          WHERE
            SBQQ__StartDate__c <= :System.today()
            AND SBQQ__EndDate__c >= :System.today()
            AND SBQQ__ProductName__c IN :qualifiedProducts.keySet()
          ORDER BY SBQQ__ProductName__c
        )
      FROM Account
      WHERE Id IN :accountIds
    ];
  }
}