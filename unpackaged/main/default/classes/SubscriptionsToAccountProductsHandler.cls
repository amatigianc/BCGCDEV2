/*
Object: Subcriptions (CPQ)
Events: AFTER_INSERT, AFTER_UPDATE
Description: called when a CPQ subscription is created/updated it publish a platform event called: Subscription_Events__e passing the ID of the Subscription
and it's managed by the 'SubscriptionPlatformEventHandler'
*/
public with sharing class SubscriptionsToAccountProductsHandler extends DomainLogicHandler {
  public List<Account_Products_Events__e> events = new List<Account_Products_Events__e>();

  public override void check(SObject obj) {
    events.add(getEvent((SBQQ__Subscription__c) obj));
  }
  public override void processRecords() {
    if (!events.isEmpty()) {
      EventBus.publish(events);
    }
  }

  private Account_Products_Events__e getEvent(SBQQ__Subscription__c record) {
    return new Account_Products_Events__e(Subscription_Id__c = record.Id);
  }
}