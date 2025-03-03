public with sharing class Account6QAOppHandler extends DomainLogicHandler {
    Map<Id, Account> qualifiedAccounts = new Map<Id, Account>();
    Id oppLeadRecordType = RecordTypeUtility.getId(
        Opportunity.getSObjectType(),
        'Lead'
    );
    Id defaultOwnerId;

    public override void check(SObject newObj, SObject oldObj) {
        Account newAccount = (Account) newObj;
        Account oldAccount = (Account) oldObj;

        if (isQualified(newAccount, oldAccount)) {
            qualifiedAccounts.put(newAccount.Id, newAccount);
        }
    }

    public override void processRecords() {
        BCMap openOpps = getOpenOpps();
        setDefaultOwnerId();

        List<Opportunity> opps = new List<Opportunity>();
        for (Account qualifiedAccount : qualifiedAccounts.values()) {
            if (!openOpps.containsKey(qualifiedAccount.Id)) {
                opps.add(getNewOpp(qualifiedAccount));
            }
        }

        insert opps;
    }

    Opportunity getNewOpp(Account qualifiedAccount) {
        return new Opportunity(
            Name = 'Placeholder',
            RecordTypeId = oppLeadRecordType,
            CloseDate = Date.today().addDays(30),
            AccountId = qualifiedAccount.Id,
            StageName = '0 - Meeting Pending',
            OwnerId = defaultOwnerId,
            Contract_Type__c = 'Standard Term Contract',
            X6QA__c = true,
            Forecast__c = null,
            LeadSource = 'QA',
            Deal_Type__c = qualifiedAccount.Account_Stage__c == 'Customer' ? 'Add-On' : 'New Business'
        );
    }

    BCMap getOpenOpps() {
        List<Opportunity> opps = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE IsClosed = FALSE AND AccountId IN :qualifiedAccounts.keySet()
            AND (
                 (
                    Account.Account_Stage__c != 'Customer' 
                    AND RecordType.Name IN ('New Business', 'Lead')
                 ) OR (
                    Account.Account_Stage__c = 'Customer'
                    AND RecordType.Name IN ('Add-On', 'Lead', 'Renewal') 
                    AND CloseDate < :Date.today().addDays(90) AND CloseDate >= :Date.today()
                 )
            )
        ];
        
        return new BCMap(opps, 'AccountId');
    }

    Boolean isQualified(Account newAccount, Account oldAccount) {
        return TriggerUtility.isChanged(
                newAccount,
                oldAccount,
                Account.X6QA__c
            ) &&
            newAccount.X6QA__c &&
            (
                StageZeroOppNewBusinessQualifier.isQualified(newAccount) 
                || StageZeroOppAddOnQualifier.isQualified(newAccount)
            );
    }

    void setDefaultOwnerId() {
        String defaultOwnerUserName = Label.Default_Lead_Opp_Owner + '%';
        defaultOwnerId = [
            SELECT Id
            FROM User
            WHERE UserName LIKE :defaultOwnerUserName
        ]
        .Id;
    }
}