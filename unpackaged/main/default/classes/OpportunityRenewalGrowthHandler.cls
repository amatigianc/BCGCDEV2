public with sharing class OpportunityRenewalGrowthHandler extends DomainLogicHandler {
    List<Opportunity> workSet = new List<Opportunity>();
    Map<Id,Opportunity> oldOpps = new Map<Id,Opportunity>();

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified((Opportunity) newObj, (Opportunity) oldObj)) {
            workSet.add((Opportunity) newObj);
            oldOpps.put(oldObj.Id, (Opportunity)oldObj);
        }
    }

    public override void processRecords() {
        Set<Id> quoteIds = new Set<Id>();

        for (Opportunity opp : workSet) {
            if (opp.SBQQ__PrimaryQuote__c != null) {
                quoteIds.add(opp.SBQQ__PrimaryQuote__c);
            }
        }

        Map<Id, SBQQ__Quote__c> quoteInfo = new Map<Id, SBQQ__Quote__c>([
            SELECT Id, SBQQ__SubscriptionTerm__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ]);

        for (Opportunity opp : workSet) {
            processOpportunity(opp, quoteInfo);
        }
    }

    private void processOpportunity(Opportunity opp, Map<Id, SBQQ__Quote__c> quoteInfo) {
        Integer subscriptionTerm = 12;
        
        if (opp.SBQQ__PrimaryQuote__c != null) {
            subscriptionTerm = quoteInfo.get(opp?.SBQQ__PrimaryQuote__c)
                    .SBQQ__SubscriptionTerm__c < 12
                ? (Integer)quoteInfo.get(opp?.SBQQ__PrimaryQuote__c)
                        .SBQQ__SubscriptionTerm__c
                : 12;
        }

        Decimal newMRR = opp.ACV__c / subscriptionTerm;
        Decimal renewalGrowth =
            newMRR - opp.Existing_MRR__c;

        opp.New_MRR__c = newMRR;
        if(renewalGrowth < 0.0) {
            renewalGrowth = 0.0;
        }
        opp.Renewal_Growth_Amount__c = renewalGrowth * subscriptionTerm;

        if(opp.StageName == 'Closed Won' && opp.StageName != oldOpps.get(opp.Id).StageName) {
            if(opp.New_MRR__c > opp.Existing_MRR__c) {
                opp.MRR_Commit__c = opp.Existing_MRR__c;
            } else {
                opp.MRR_Commit__c = newMRR;
            }
        }
    }

    private Boolean isQualified(Opportunity newOpp, Opportunity oldOpp) {
        if (
            (newOpp.ACV__c != oldOpp.ACV__c ||
            newOpp.SBQQ__PrimaryQuote__c != oldOpp.SBQQ__PrimaryQuote__c ||
            newOpp.Existing_MRR__c != oldOpp.Existing_MRR__c ||
            newOpp.StageName != oldOpp.StageName) &&
            newOpp.Existing_MRR__c != null &&
            newOpp.ACV__c != null &&
            newOpp.StageName != null
        ) {
            return true;
        }
        return false;
    }
}