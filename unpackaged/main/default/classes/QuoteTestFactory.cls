@IsTest
public with sharing class QuoteTestFactory {
    public static SBQQ__Quote__c getBaseQuote() {
    List<SObject> relatedRecords = OpportunityTestFactory.initOpp();
    insert relatedRecords;
    SBQQ__Quote__c quote = getStubQuote();
    quote.SBQQ__Opportunity2__c = relatedRecords[2].Id;
    return quote;
  }

  public static SBQQ__Quote__c createBaseQuote() {
    List<SObject> relatedRecords = OpportunityTestFactory.initOpp();
    SBQQ__Quote__c quote = getStubQuote();
    quote.SBQQ__Opportunity2__r = new Opportunity(
      GUID__c = String.valueOf(relatedRecords[2].get('GUID__c'))
    );
    relatedRecords.add(quote);
    insert relatedRecords;
    return quote;
  }

  static SBQQ__Quote__c getStubQuote() {
    return new SBQQ__Quote__c(
      SBQQ__Primary__c = false,
      SBQQ__Type__c = 'Quote',
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__Status__c = 'Draft'
    );
  }

  public static SBQQ__Quote__c getPrimaryQuote(Id oppId) {
    return new SBQQ__Quote__c(
      SBQQ__Primary__c = true,
      SBQQ__Opportunity2__c = oppId,
      SBQQ__Type__c = 'Quote',
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__Status__c = 'Draft'
    );
  }

  public static SBQQ__Quote__c createPrimaryQuote(Id oppId) {
    SBQQ__Quote__c quote = getPrimaryQuote(oppId);
    insert quote;
    return quote;
  }
}