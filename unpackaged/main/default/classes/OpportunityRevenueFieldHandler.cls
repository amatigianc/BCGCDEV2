public with sharing class OpportunityRevenueFieldHandler extends DomainLogicHandler {
    private static CurrencyUtility cuInstance;
    List<Opportunity> workSet = new List<Opportunity>();

    public override void check(SObject newObj) {
        newObj.put('ACVH__c', newObj.get('ACV__c'));
        newObj.put('TCVH__c', newObj.get('TCV__c'));
        workSet.add((Opportunity)newObj);
    }
    
    public override void check(SObject newObj, SObject oldObj) {
        newObj.put('ACVH__c', newObj.get('ACV__c'));
        newObj.put('TCVH__c', newObj.get('TCV__c'));
        workSet.add((Opportunity)newObj);
    }

    public override void processRecords() {
        Set<Date> closeDates = new Set<Date>();
        for(Opportunity opp : workSet) {
            closeDates.add(opp.CloseDate);
        }

        cuInstance = CurrencyUtility.getInstance(closeDates);

        for(Opportunity opp : workSet) {
            opp.USD_Existing_MRR__c = cuInstance.convertPriceToUSD(opp.Existing_MRR__c, opp.CurrencyIsoCode, opp.CloseDate);
            opp.USD_MRR_Commit__c = cuInstance.convertPriceToUSD(opp.MRR_Commit__c, opp.CurrencyIsoCode, opp.CloseDate);
            opp.USD_Total_ACV__c = cuInstance.convertPriceToUSD(opp.ACV__c, opp.CurrencyIsoCode, opp.CloseDate);
        }
    }
}