public with sharing class PersistentIdHandler extends DomainLogicHandler {
    public override void check(SObject newObj) {
        if (isQualified(newObj)) {
            newObj.put('GUID__c', GuidUtility.generateGuid());
        }
    }

    private Boolean isQualified(SObject newObj) {
        return newObj.get('GUID__c') == null || newObj.isClone();
    }
}