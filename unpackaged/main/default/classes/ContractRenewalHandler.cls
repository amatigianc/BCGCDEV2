public with sharing class ContractRenewalHandler extends DomainLogicHandler {
    List<SObjectField> qualifiedFields = new List<SObjectField>{ Contract.Status };

    public override void check(SObject newObj, SObject oldObj) {
        if(isQualified(newObj, oldObj)) {
            ((Contract)newObj).SBQQ__RenewalForecast__c = true;
        }
    }

    private Boolean isQualified(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(newObj, oldObj, qualifiedFields) &&
            newObj.get('Status') == 'Activated';
    }
}