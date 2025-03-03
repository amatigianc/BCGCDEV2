public with sharing class OpportunitySalesforceCorrectionHandler extends DomainLogicHandler {
    public override void check(Sobject newObj, SObject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;
        if (isQualified(newOpp, oldObj)) {
            newOpp.Reason_for_Win_Loss__c = 'Salesforce Correction';
            newOpp.SubReason_for_winloss__c = 'Salesforce Correction';
        }
    }

    private Boolean isQualified(Opportunity newOpp, SObject oldOpp) {
        return TriggerUtility.isChanged(
                newOpp,
                oldOpp,
                Opportunity.StageName
            ) && (String) newOpp.StageName == 'Salesforce Correction';
    }
}