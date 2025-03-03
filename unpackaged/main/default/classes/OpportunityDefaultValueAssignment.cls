public with sharing class OpportunityDefaultValueAssignment extends DomainLogicHandler {
    private static List<String> qualifiedRecordTypes = new List<String>{
        'New Business',
        'Add-On',
        'Renewal'
    };

    public override void check(SObject newObj) {
        Opportunity newOpp = (Opportunity) newObj;
        if (isQualified(newOpp)) {
            newOpp.Deal_Type__c = RecordTypeUtility.getName(newOpp);
        }
    }

    private Boolean isQualified(Opportunity newOpp) {
        String recordTypeName = RecordTypeUtility.getName(newOpp);
        return qualifiedRecordTypes.contains(recordTypeName);
    }
}