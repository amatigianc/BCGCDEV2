public with sharing class OpportunityRenewalExpireContractHandler extends DomainLogicHandler {
    Set<Id> contractIds = new Set<Id>();
    List<SObjectField> qualifiedFields = new List<SObjectField>{
        Opportunity.StageName
    };

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            contractIds.add(((Opportunity) newObj).SBQQ__RenewedContract__c);
        }
    }

    public override void processRecords() {
        List<Contract> contracts = [
            SELECT Id, Status
            FROM Contract
            WHERE Id IN :contractIds
        ];
        for (Contract contract : contracts) {
            contract.Status = 'Expired';
        }
        update contracts;
    }

    private Boolean isQualified(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(newObj, oldObj, qualifiedFields) &&
            newObj.get('StageName') == 'Closed Won';
    }
}