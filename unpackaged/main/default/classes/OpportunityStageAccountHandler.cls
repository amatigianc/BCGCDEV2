public with sharing class OpportunityStageAccountHandler extends DomainLogicHandler {
    List<Id> accountIds = new List<Id>();

    public override void check(Sobject newObj, Sobject oldObj) {
        Opportunity newOpp = (Opportunity) newObj;
        Opportunity oldOpp = (Opportunity) oldObj;

        if (isQualified(newOpp, oldOpp)) {
            accountIds.add(newopp.AccountId);
        }
    }

    public override void processRecords() {
        List<Account> accounts = [
            SELECT Id, Account_Stage__c
            FROM Account
            WHERE Id IN :accountIds AND Account_Stage__c != 'Customer'
        ];

        for (Account account : accounts) {
            account.Account_Stage__c = 'Customer';
        }

        update accounts;
    }

    private Boolean isQualified(Opportunity newOpp, Opportunity oldOpp) {
        return isStageQualified(newOpp) && isStageChanged(newOpp, oldOpp);
    }

    private Boolean isStageChanged(Opportunity newOpp, Opportunity oldOpp) {
        return newOpp.StageName != oldOpp.StageName;
    }

    private Boolean isStageQualified(Opportunity opp) {
        return opp.StageName == 'Closed Won';
    }
}