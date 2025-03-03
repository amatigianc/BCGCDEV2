public with sharing class QuoteTermHandler extends DomainLogicHandler {
    public override void check(SObject newObj, SObject oldObj) {
        SBQQ__Quote__c quote = (SBQQ__Quote__c) newObj;
        Date endDate = null;

        if(quote.SBQQ__Type__c == 'Amendment') {
            return;
        }

        if (Math.mod((Integer)quote.SBQQ__SubscriptionTerm__c, 12) > 0) {
            endDate = quote.SBQQ__StartDate__c.addMonths(
                    12 + Math.mod((Integer)quote.SBQQ__SubscriptionTerm__c, 12)
                )
                .addDays(-1);
        }

        if (quote.Single_Term__c) {
            endDate = quote.SBQQ__StartDate__c.addMonths(
                    (Integer)quote.SBQQ__SubscriptionTerm__c
                )
                .addDays(-1);
        }

        quote.SBQQ__FirstSegmentTermEndDate__c = endDate;
    }
}