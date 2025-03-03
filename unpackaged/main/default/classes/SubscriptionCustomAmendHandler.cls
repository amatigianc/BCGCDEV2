public with sharing class SubscriptionCustomAmendHandler extends DomainLogicHandler {
    Set<Id> subscriptionIdsToDelete = new Set<Id>();
    Map<Id, SBQQ__Subscription__c> newSubscriptionByRevisedId = new Map<Id, SBQQ__Subscription__c>();

    public override void check(SObject newObj) {
        SBQQ__Subscription__c thisRecord = (SBQQ__Subscription__c) newObj;
        if (isQualified(thisRecord)) {
            newSubscriptionByRevisedId.put(
                thisRecord.SBQQ__RevisedSubscription__c,
                thisRecord
            );
            subscriptionIdsToDelete.add(thisRecord.Id);
        }
    }

    public override void processRecords() {
        List<SBQQ__Subscription__c> originalSubscriptions = getOriginalSubscriptions(
            newSubscriptionByRevisedId.keySet()
        );

        for (
            SBQQ__Subscription__c originalSubscription : originalSubscriptions
        ) {
            SBQQ__Subscription__c newSubscription = newSubscriptionByRevisedId.get(
                originalSubscription.Id
            );
            Double originalProrate = originalSubscription.SBQQ__ProrateMultiplier__c;
            Double newProrate = newSubscription.SBQQ__ProrateMultiplier__c;

            Decimal listPrice =
                newSubscription.SBQQ__ListPrice__c / newProrate;
            Decimal customerPrice = listPrice;

            if (newSubscription.SBQQ__AdditionalDiscountAmount__c > 0.0) {
                customerPrice =
                    listPrice -
                    newSubscription.SBQQ__AdditionalDiscountAmount__c;
            } else if (newSubscription.SBQQ__Discount__c > 0) {
                Double discountPercent = newSubscription.SBQQ__Discount__c / 100.0;
                customerPrice = listPrice - (listPrice * discountPercent);
            }

            originalSubscription.Number_of_Plays__c = newSubscription.Number_of_Plays__c;
            originalSubscription.SBQQ__ListPrice__c = listPrice * originalProrate;
            originalSubscription.SBQQ__SpecialPrice__c = listPrice;
            originalSubscription.SBQQ__CustomerPrice__c = customerPrice * originalProrate;
            originalSubscription.SBQQ__RegularPrice__c = listPrice * originalProrate;
            originalSubscription.SBQQ__NetPrice__c = customerPrice * originalProrate;
            originalSubscription.SBQQ__RenewalPrice__c = customerPrice;
        }

        update originalSubscriptions;

        SubscriptionCustomAmendHandler.deleteSubscriptions(
            subscriptionIdsToDelete
        );
    }

    private Boolean isQualified(SBQQ__Subscription__c newSubscription) {
        if (newSubscription.SBQQ__RevisedSubscription__c == null) {
            return false;
        }

        return newSubscription.Product_is_Custom_Amend__c;
    }

    @future
    private static void deleteSubscriptions(Set<Id> subscriptionIds) {
        List<SBQQ__Subscription__c> subsToDelete = new List<SBQQ__Subscription__c>();
        for (Id subscriptionId : subscriptionIds) {
            subsToDelete.add(new SBQQ__Subscription__c(Id = subscriptionId));
        }
        delete subsToDelete;
    }

    public List<SBQQ__Subscription__c> getOriginalSubscriptions(
        Set<Id> subscriptionIds
    ) {
        return [
            SELECT
                Id,
                Number_of_Plays__c,
                SBQQ__ProrateMultiplier__c,
                SBQQ__ListPrice__c,
                SBQQ__SpecialPrice__c,
                SBQQ__CustomerPrice__c,
                SBQQ__RegularPrice__c,
                SBQQ__NetPrice__c,
                SBQQ__RenewalPrice__c
            FROM SBQQ__Subscription__c
            WHERE Id IN :subscriptionIds
        ];
    }
}