/*
 * Triggers on BEFORE_UPDATE of Opportunity
 *
 * Sets the Qualifying User and Qualifier Role fields on Lead
 * Opps when Stage changes to either "0 - Meeting Occurred" or
 * "0 - Disqualified"
 */

public with sharing class OpportunityQualificationHandler extends DomainLogicHandler {
    List<Opportunity> qualifiedOpps = new List<Opportunity>();
    Map<Id, User> owners;
    Id bdrRoleId;

    public override void check(SObject newObj, SObject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;

        if (isQualified(newOpp, oldObj)) {
            qualifiedOpps.add(newOpp);
        }
    }

    public override void processRecords() {
        if (!qualifiedOpps.isEmpty()) {
            setBdrRoleId();
            for (Opportunity opp : qualifiedOpps) {
                setQualiferFields(opp);
            }
        }
    }

    Boolean isQualified(Opportunity newOpp, SObject oldOpp) {
        return isQualifiedRecordType(newOpp) &&
            isStageChanged(newOpp, oldOpp) &&
            isStageQualified(newOpp);
    }

    Boolean isQualifiedRecordType(SObject newOpp) {
        return RecordTypeUtility.getName(newOpp) == 'Lead';
    }

    Boolean isStageChanged(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(newObj, oldObj, Opportunity.StageName);
    }

    Boolean isStageQualified(Opportunity newOpp) {
        return new List<String>{ '0 - Meeting Occurred', '0 - Disqualified' }
            .contains(newOpp.Stagename);
    }

    void setBdrRoleId() {
        bdrRoleId = [SELECT Id FROM UserRole WHERE Name = 'BDR' LIMIT 1].Id;
    }

    void setQualiferFields(Opportunity opp) {
        opp.Qualifying_User__c = UserInfo.getUserId();
        opp.Qualifier_Role__c = UserInfo.getUserRoleId() == bdrRoleId
            ? 'BDR'
            : 'Sales Rep';
    }
}