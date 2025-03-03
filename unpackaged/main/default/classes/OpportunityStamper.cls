public with sharing class OpportunityStamper extends DomainLogicHandler {
    Map<String, SObjectField> stageFieldMap = new Map<String, SObjectField>{
        '1 - Discovery' => Opportunity.Discovery_Stage_Set_Date__c,
        '2 - Demo' => Opportunity.Demo_Stage_Set_Date__c,
        '3 - Solution Design & Evaluation' => Opportunity.Solution_Design_Stage_Set_Date__c,
        '4 - Negotiation' => Opportunity.Negotiation_Stage_Set_Date__c,
        '0 - Meeting Pending' => Opportunity.Meeting_Pending_Stage_Set_Date__c,
        '0 - Meeting Scheduled' => Opportunity.Meeting_Scheduled_Stage_Set_Date__c,
        '0 - Meeting Occurred' => Opportunity.Meeting_Occurred_Stage_Set_Date__c
    };

    public override void check(SObject newObj) {
        Opportunity newOpp = (Opportunity) newObj;
        stamp(newOpp);
    }

    public override void check(SObject newObj, SObject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;
        if (isQualified(newOpp, oldObj)) {
            stamp(newOpp);
        }
    }

    Boolean isQualified(Opportunity newOpp, SObject oldObj) {
        return isChanged(newOpp, oldObj) && isStageNameQualified(newOpp);
    }

    Boolean isStageNameQualified(Opportunity newOpp) {
        return stageFieldMap.containsKey(newOpp.StageName);
    }

    Boolean isChanged(Opportunity newOpp, SObject oldObj) {
        return TriggerUtility.isChanged(newOpp, oldObj, Opportunity.StageName);
    }

    void stamp(Opportunity newOpp) {
        SObjectField field = stageFieldMap.get(newOpp.StageName);
        newOpp.put(field, Datetime.now());
    }
}