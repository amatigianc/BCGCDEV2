public with sharing class SubscriptionAmendedRenewalHandler extends DomainLogicHandler {
    Map<Id, SBQQ__Subscription__c> revisedSubscriptionsByOriginalId = new Map<Id, SBQQ__Subscription__c>();

    public override void check(SObject newObj) {
        SBQQ__Subscription__c revisedSubscription = (SBQQ__Subscription__c) newObj;

        if (isQualified(revisedSubscription)) {
            revisedSubscriptionsByOriginalId.put(
                revisedSubscription.SBQQ__RevisedSubscription__c,
                revisedSubscription
            );
        }
    }

    public override void processRecords() {
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__Subscription__c> originalSubscriptions = getOriginalSubscriptions();

        for (
            SBQQ__Subscription__c originalSubscription : originalSubscriptions
        ) {
            Decimal quantity = getTotalQuantity(originalSubscription);
            quoteLinesToUpdate.addAll(
                getUpdatedQuoteLines(originalSubscription, quantity)
            );
        }

        update quoteLinesToUpdate;
    }

    private Decimal getTotalQuantity(
        SBQQ__Subscription__c originalSubscription
    ) {
        if (originalSubscription.Product_is_Custom_Amend__c) {
            return originalSubscription.SBQQ__Quantity__c;
        }

        Decimal quantity = originalSubscription.SBQQ__Quantity__c;

        for (
            SBQQ__Subscription__c revisedSubscription : originalSubscription.SBQQ__Revisions__r
        ) {
            quantity += revisedSubscription.SBQQ__Quantity__c;
        }

        return quantity;
    }

    private List<SBQQ__QuoteLine__c> getUpdatedQuoteLines(
        SBQQ__Subscription__c originalSubscription,
        Decimal quantity
    ) {
        List<SBQQ__QuoteLine__c> results = new List<SBQQ__QuoteLine__c>();

        for (
            SBQQ__QuoteLine__c renewalQuoteLine : originalSubscription.SBQQ__RenewalQuoteLines__r
        ) {
            //custom amend process for MS
            if (originalSubscription.Product_is_Custom_Amend__c) {
                SBQQ__Subscription__c revisedSubscription = revisedSubscriptionsByOriginalId.get(
                    originalSubscription.Id
                );

                renewalQuoteLine.Number_of_Plays__c = revisedSubscription.Number_of_Plays__c;
                renewalQuoteLine.SBQQ__AdditionalDiscountAmount__c = revisedSubscription.SBQQ__AdditionalDiscountAmount__c;
                renewalQuoteLine.SBQQ__Discount__c = revisedSubscription.SBQQ__Discount__c;
            }

            renewalQuoteLine.SBQQ__BundledQuantity__c = quantity;
            results.add(renewalQuoteLine);
        }

        return results;
    }

    private List<SBQQ__Subscription__c> getOriginalSubscriptions() {
        return [
            SELECT
                Id,
                SBQQ__Quantity__c,
                Product_is_Custom_Amend__c,
                Number_of_Plays__c,
                (
                    SELECT
                        Id,
                        SBQQ__BundledQuantity__c,
                        Number_of_Plays__c,
                        SBQQ__AdditionalDiscountAmount__c,
                        SBQQ__Discount__c
                    FROM SBQQ__RenewalQuoteLines__r
                ),
                (SELECT Id, SBQQ__Quantity__c FROM SBQQ__Revisions__r)
            FROM SBQQ__Subscription__c
            WHERE Id IN :revisedSubscriptionsByOriginalId.keySet()
        ];
    }

    private Boolean isQualified(SBQQ__Subscription__c subscription) {
        return subscription.SBQQ__RevisedSubscription__c != null;
    }
}