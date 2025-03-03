public with sharing class OpportunityClientTerminationHandler extends DomainLogicHandler {
    List<Account> accounts = new List<Account>();

    public override void check(SObject newObj, SObject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;
        if (isQualified(newObj, oldObj)) {
            accounts.add(
                new Account(Id = newOpp.AccountId, Account_Stage__c = 'Former')
            );
        }
    }

    public override void processRecords() {
        update accounts;
    }

    Boolean isQualified(SObject newObj, SObject oldObj) {
        return isChanged(newObj, oldObj) &&
            isClientTerminiationApproved((Opportunity) newObj);
    }

    Boolean isClientTerminiationApproved(Opportunity newOpp) {
        return newOpp.Client_Termination_Status__c == 'Approved';
    }

    Boolean isChanged(SObject newObj, SObject oldObj) {
        return TriggerUtility.isChanged(
            newObj,
            oldObj,
            Opportunity.Client_Termination_Status__c
        );
    }
}