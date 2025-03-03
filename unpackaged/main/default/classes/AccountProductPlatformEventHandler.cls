/**
 * Description: Single CLASS that manages the Platform Events 'Subscription_Events__e'
 * Event Name: 'Subscription Event'
 * EVENTS: the events are published by 'SubscriptionsToBCSubscriptionHandler'
 */

public with sharing class AccountProductPlatformEventHandler {
  public static void process(List<Account_Products_Events__e> events) {
    List<Id> subscriptionIds = new List<Id>();

    for (Account_Products_Events__e event : events) {
      subscriptionIds.add(event.Subscription_Id__c);
    }

    List<SBQQ__Subscription__c> subscriptions = [
      SELECT
        Id,
        SBQQ__Account__c,
        SBQQ__StartDate__c,
        SBQQ__EndDate__c,
        SBQQ__Quantity__c,
        SBQQ__Product__r.Name,
        SBQQ__CustomerPrice__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Contract_Id__c,
        SBQQ__QuoteLine__r.SBQQ__Description__c
      FROM SBQQ__Subscription__c
      WHERE Id = :subscriptionIds
    ];

    List<Account_Product__c> accountProducts = new List<Account_Product__c>();
    for (SBQQ__Subscription__c subscription : subscriptions) {
      accountProducts.add(
        new Account_Product__c(
          Account__c = subscription.SBQQ__Account__c,
          Start_Date__c = subscription.SBQQ__StartDate__c,
          End_Date__c = subscription.SBQQ__EndDate__c,
          Quantity__c = subscription.SBQQ__Quantity__c,
          Product_Name__c = subscription.SBQQ__Product__r.Name,
          Contract_Id__c = subscription.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Contract_Id__c,
          Product_Description__c = subscription.SBQQ__QuoteLine__r.SBQQ__Description__c,
          Product_Customer_Price__c = subscription.SBQQ__CustomerPrice__c
        )
      );
    }

    insert accountProducts;
  }
}