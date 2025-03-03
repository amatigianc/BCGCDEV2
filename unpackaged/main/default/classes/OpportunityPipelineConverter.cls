public with sharing class OpportunityPipelineConverter extends DomainLogicHandler {
    List<Opportunity> qualifiedOpps = new List<Opportunity>();
    List<Id> accountIds = new List<Id>();

    public override void check(SObject newObj, SObject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;
        Opportunity oldOpp = (Opportunity) oldObj;
        if (isQualified(newOpp, oldOpp)) {
            newOpp.OwnerId = UserInfo.getUserId();
            qualifiedOpps.add(newOpp);
            accountIds.add(newOpp.AccountId);
        }
    }

    public override void processRecords() {
        if (!accountIds.isEmpty()) {
            Map<Id, Account> accounts = new Map<Id, Account>(
                [
                    SELECT Id, Account_Stage__c
                    FROM Account
                    WHERE Id IN :accountIds
                ]
            );
            for (Opportunity opp : qualifiedOpps) {
                String accountStage = accounts.get(opp.AccountId)
                    .Account_Stage__c;
                switch on accountStage {
                    when 'Customer' {
                        opp.RecordTypeId = RecordTypeUtility.getId(
                            Opportunity.getSObjectType(),
                            'Add-On'
                        );
                    }
                    when else {
                        opp.RecordTypeId = RecordTypeUtility.getId(
                            Opportunity.getSObjectType(),
                            'New Business'
                        );
                    }
                }
                opp.StageName = '1 - Discovery';
                /**
                 * We have to set the Discovery_Stage_Set_Date__c field here
                 * rather than relying on OpportunityStamper because that class
                 * sets the different Stage_Set_Date__c fields during the check
                 * methods, but the updating of the Opp stage for converted Stage Zero
                 * opps happens after, in this processRecords method.
                 */
                opp.Discovery_Stage_Set_Date__c = Datetime.now();
            }
        }
    }

    private Boolean isQualified(Opportunity newOpp, Opportunity oldOpp) {
        return newOpp.Convert_to_Pipeline__c != oldOpp.Convert_to_Pipeline__c &&
            newOpp.Convert_to_Pipeline__c;
    }
}