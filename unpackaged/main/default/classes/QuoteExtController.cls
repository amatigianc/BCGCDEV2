//pulled from https://help.salesforce.com/s/articleView?id=sf.cpq_enable_aa.htm&type=5

public with sharing class QuoteExtController {
    private Id quoteId;
    private SBQQ__Quote__c quote;

    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
        quote = [SELECT Id, SBQQ__Type__c, Deal_Type__c, SBQQ__Opportunity2__r.Is_the_Contract_Auto_Renewing__c FROM SBQQ__Quote__c WHERE Id =: quoteId];
    }
    public PageReference onSubmit() {
        if (quoteId != null) {
            if(quote.Deal_Type__c == 'Renewal' && quote.SBQQ__Opportunity2__r.Is_the_Contract_Auto_Renewing__c == 'Yes') {
                quote.SBQQ__Status__c = 'Approved';
                update quote;
            } else {
                SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
            }            
        }
        return new PageReference('/' + quoteId);
    }
    
    public PageReference onRecall() {
        if (quoteId != null) {
            if(quote.Deal_Type__c == 'Renewal' && quote.SBQQ__Opportunity2__r.Is_the_Contract_Auto_Renewing__c == 'Yes') {
                quote.SBQQ__Status__c = 'Draft';
                update quote;
            } else {
                SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
            }
        }
        return new PageReference('/' + quoteId);
    }
}