public with sharing class OpportunityNameHandler extends DomainLogicHandler {
    private List<Opportunity> opps = new List<Opportunity>();
    private Set<Id> accountIds = new Set<Id>();
    private Map<Id, Account> accountsByIdMap = new Map<Id, Account>();
    private Map<String, String> oppNameMap = new Map<String, String>();

    public override void check(Sobject newObj) {
        opps.add((Opportunity) newObj);
        accountIds.add((Id) newObj.get(Opportunity.AccountId));
    }

    public override void check(SObject newObj, SObject oldObj) {
        if (isQualified(newObj, oldObj)) {
            opps.add((Opportunity) newObj);
            accountIds.add((Id) newObj.get(Opportunity.AccountId));
        }
    }

    public override void processRecords() {
        if (!accountIds.isEmpty()) {
            accountsByIdMap = new Map<Id, Account>(
                [SELECT Id, Name FROM Account WHERE Id IN :accountIds]
            );

            setOppNameMap();
            setOppNames();
            validateNewOppNames();
        }
    }

    private Boolean isQualified(SObject newObj, SObject oldObj) {
        return isChanged(newObj, oldObj);
    }

    private Boolean isChanged(SObject newObj, SObject oldObj) {
        List<SObjectField> fields = new List<SObjectField>{
            Opportunity.AccountId,
            Opportunity.CloseDate,
            Opportunity.RecordTypeId
        };
        return TriggerUtility.isChanged(newObj, oldObj, fields);
    }

    private void validateNewOppNames() {
        Set<String> existingOppNames = getExistingOppNames();

        for (Opportunity opp : opps) {
            if (existingOppNames.contains(opp.Name)) {
                opp.addError(
                    'An Opportunity with the name "' +
                    opp.Name +
                    '" already exists.'
                );
            }
        }
    }

    private void setOppNames() {
        for (Opportunity opp : opps) {
            opp.Name = oppNameMap.get(opp.GUID__c);
        }
    }

    private Set<String> getExistingOppNames() {
        List<Opportunity> existingOpps = [
            SELECT Id, Name
            FROM Opportunity
            WHERE Name IN :oppNameMap.values()
        ];

        Set<String> existingOppNames = new Set<String>();
        for (Opportunity opp : existingOpps) {
            existingOppNames.add(opp.Name);
        }
        return existingOppNames;
    }

    private void setOppNameMap() {
        for (Opportunity opp : opps) {
            oppNameMap.put(opp.GUID__c, getOpportunityName(opp));
        }
    }

    private String getOpportunityName(Opportunity opp) {
        String accountName = accountsByIdMap.get(opp.AccountId).Name;
        String recordTypeName = RecordTypeUtility.getName(opp);
        String closeDate =
            String.valueOf(opp.CloseDate.month()) +
            '/' +
            String.valueOf(opp.CloseDate.day()) +
            '/' +
            String.valueOf(opp.CloseDate.year());

        if (accountName.length() > 80) {
            accountName = accountName.left(80).trim();
        }

        List<String> nameArguments = new List<String>{
            accountName,
            recordTypeName,
            closeDate
        };

        return String.format('{0} - {1} - {2}', nameArguments);
    }
}