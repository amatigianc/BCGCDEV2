public with sharing class OpportunityAccountStamper extends DomainLogicHandler {
    List<String> qualifiedRecordTypes = new List<String>{
        'New Business',
        'Add-On',
        'Lead',
        'Renewal Growth Add-on',
        'Professional Services'
    };
    private List<Id> accountIds = new List<Id>();
    private List<Opportunity> qualifiedOpps = new List<Opportunity>();
    @TestVisible
    private List<String> fields = new List<String>{
        'X6sense_Account_6QA_End_Date__c',
        'X6sense_Account_6QA_Start_Date__c',
        'X6sense_Account_Buying_Stage__c',
        'X6sense_Account_Intent_Score__c',
        'X6sense_Account_Profile_Fit__c',
        'X6sense_Account_Reach_Score__c',
        'X6Sense_Segment_Name__c',
        'X6sense_Stage_Awareness__c',
        'X6sense_Stage_Consideration__c',
        'X6sense_Stage_Decision__c',
        'X6sense_Stage_Purchase__c',
        'Named_Account__c',
        'Named_Account_Tier__c'
    };

    public override void check(SObject newObj) {
        Opportunity newOpp = (Opportunity) newObj;
        if (isQualified(newOpp)) {
            accountIds.add(newOpp.AccountId);
            qualifiedOpps.add(newOpp);
        }
    }

    public override void processRecords() {
        Map<Id, Account> accounts = new Map<Id, Account>(
            (List<Account>) Database.query(getQueryString())
        );
        for (Opportunity opp : qualifiedOpps) {
            Account account = accounts.get(opp.AccountId);
            setValues(opp, account);
        }
    }

    private Boolean isQualified(Opportunity newOpp) {
        return qualifiedRecordTypes.contains(RecordTypeUtility.getName(newOpp));
    }

    private String getQueryString() {
        return 'SELECT Id, Account_Stage__c, X6QA__c, ' +
            String.join(fields, ', ') +
            ' FROM Account WHERE Id IN :accountIds';
    }

    private void setValues(Opportunity opp, Account account) {
        for (String field : fields) {
            opp.put(field, account.get(field));
            opp.Account_Stage_at_Creation__c = (String) account.get(
                'Account_Stage__c'
            );
            opp.X6sense_6QA__c = account.X6QA__c;
        }
    }
}