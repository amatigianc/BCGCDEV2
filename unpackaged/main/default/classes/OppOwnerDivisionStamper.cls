public with sharing class OppOwnerDivisionStamper extends DomainLogicHandler {
    List<Opportunity> qualifiedOpps = new List<Opportunity>();

    public override void check(SObject newObj) {
        if (isQualified(newObj)) {
            qualifiedOpps.add((Opportunity) newObj);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            qualifiedOpps.add((Opportunity) newObj);
        }
    }

    public override void processRecords() {
        if (!qualifiedOpps.isEmpty()) {
            /**
             * note that the Opp Owner can change via
             * OpportunityOwnerHandler, meaning that OwnerIds
             * collected in this class' check method could
             * differ from those found on Opps in this processRecords
             * method.
             */
            List<Id> userIds = new List<Id>();
            for (Opportunity opp : qualifiedOpps) {
                userIds.add(opp.OwnerId);
            }

            Map<Id, User> users = new Map<Id, User>(
                [
                    SELECT Id, Division, Sub_Division__c
                    FROM User
                    WHERE Id IN :userIds
                ]
            );
            for (Opportunity opp : qualifiedOpps) {
                opp.Owner_Division__c = users.get(opp.OwnerId).Division;
                opp.Owner_Sub_Division__c = users.get(opp.OwnerId)
                    .Sub_Division__c;
            }
        }
    }

    Boolean isQualified(Sobject newObj) {
        return !(Boolean) newObj.get(Opportunity.IsClosed);
    }

    Boolean isQualified(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(newObj, oldObj, Opportunity.OwnerId) &&
            isQualified(newObj);
    }
}