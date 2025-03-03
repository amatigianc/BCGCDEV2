public with sharing class LeadSourceStamper extends DomainLogicHandler {
    public override void check(SObject newObj) {
        if (isQualified(newObj)) {
            setLeadSource(newObj);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            setLeadSource(newObj);
        }
    }

    Boolean isQualified(SObject newObj) {
        return missingLeadSource(newObj) && hasLeadSourceLatest(newObj);
    }

    Boolean isQualified(SObject newObj, SObject oldObj) {
        return isQualified(newObj) && isChanged(newObj, oldObj);
    }

    Boolean missingLeadSource(SObject newObj) {
        return newObj.get(Lead.LeadSource) == null;
    }

    Boolean hasLeadSourceLatest(SObject newObj) {
        return newObj.get(Lead.Lead_Source_Latest__c) != null;
    }

    Boolean isChanged(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(
            newObj,
            oldObj,
            Lead.Lead_Source_Latest__c
        );
    }

    void setLeadSource(SObject newObj) {
        newObj.put(Lead.LeadSource, newObj.get(Lead.Lead_Source_Latest__c));
    }
}