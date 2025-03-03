public with sharing class QuoteContractIdHandler extends DomainLogicHandler {
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

    public override void check(SObject newObj) {
        SBQQ__Quote__c newQuote = (SBQQ__Quote__c) newObj;
        if (isQualified(newQuote)) {
            quotes.add(newQuote);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        SBQQ__Quote__c newQuote = (SBQQ__Quote__c) newObj;
        SBQQ__Quote__c oldQuote = (SBQQ__Quote__c) oldObj;
        if (isQualified(newQuote, oldQuote)) {
            quotes.add(newQuote);
        }
    }

    public override void processRecords() {
        List<Opportunity> opps = new List<Opportunity>();
        for (SBQQ__Quote__c quote : quotes) {
            opps.add(
                new Opportunity(
                    Id = quote.SBQQ__Opportunity2__c,
                    Contract_Id__c = quote.Contract_Id__c
                )
            );
        }
        update opps;
    }

    private Boolean isQualified(
        SBQQ__Quote__c newQuote,
        SBQQ__Quote__c oldQuote
    ) {
        return newQuote.SBQQ__Primary__c == true &&
            TriggerUtility.isChanged(
                newQuote,
                oldQuote,
                SBQQ__Quote__c.SBQQ__Primary__c
            ) &&
            isDealTypeQualified(newQuote);
    }

    private Boolean isQualified(SBQQ__Quote__c newQuote) {
        return newQuote.SBQQ__Primary__c && isDealTypeQualified(newQuote);
    }

    Boolean isDealTypeQualified(SBQQ__Quote__c newQuote) {
        List<String> qualifiedDealTypes = new List<String>{
            'New Business',
            'Add-On'
        };
        return qualifiedDealTypes.contains(newQuote.Deal_Type__c);
    }
}