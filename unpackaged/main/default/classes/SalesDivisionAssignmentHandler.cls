public with sharing class SalesDivisionAssignmentHandler extends DomainLogicHandler {
    public override void check(SObject newObj) {
        if (isQualified(newObj)) {
            SalesDivisionAssignment.assign(newObj);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            SalesDivisionAssignment.assign(newObj);
        }
    }

    Boolean isQualified(SObject newObj) {
        SObjectField countryField = SalesDivisionAssignment.countryFieldMap.get(
            newObj.getSObjectType()
        );
        return newObj.get(countryField) != null;
    }

    Boolean isQualified(SObject newObj, SObject oldObj) {
        SObjectField countryField = SalesDivisionAssignment.countryFieldMap.get(
            newObj.getSObjectType()
        );
        return TriggerUtility.isChanged(newObj, oldObj, countryField) &&
            isQualified(newObj);
    }
}