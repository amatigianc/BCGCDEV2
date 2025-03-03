public with sharing class OrderActivationHandler extends DomainLogicHandler {
    List<SObjectField> qualifiedFields = new List<SObjectField>{ Order.Status };

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            ((Order) newObj).SBQQ__Contracted__c = true;
        }
    }

    private Boolean isQualified(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(newObj, oldObj, qualifiedFields) &&
            newObj.get('Status') == 'Activated';
    }
}