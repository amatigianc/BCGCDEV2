/**
 * Description: When a Subscription related to the Support Package or Live Event Support products is
 * created it updates the information related to the available number of Live Event Support Hours on the related Account.
 * SObject: SBQQ__Subscription__c
 *
 * Events: AFTER_INSERT
 */

public with sharing class SubscriptionSupportPackageUpdate extends DomainLogicHandler {
  Set<Id> accountIds = new Set<Id>();
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

  public override void check(SObject newObject) {
    SBQQ__Subscription__c newSubscription = (SBQQ__Subscription__c) newObject;
    if (isQualified(newSubscription)) {
      accountIds.add(newSubscription.SBQQ__Account__c);
    }
  }

  public override void processRecords() {
    processAccounts(accountIds);
  }

  Boolean isQualified(SBQQ__Subscription__c newSubscription) {
    return qualifiedProducts.containsKey(newSubscription.SBQQ__ProductName__c);
  }

  @future
  static void processAccounts(Set<Id> accountIds) {
    SupportSubscriptionProcessor.process(accountIds);
  }
}