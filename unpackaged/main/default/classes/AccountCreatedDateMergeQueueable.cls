public with sharing class AccountCreatedDateMergeQueueable implements Queueable {
    Integer limiter;

    public static void abort() {
        List<AsyncApexJob> jobs = [
            SELECT Id, Status
            FROM AsyncApexJob
            WHERE
                ApexClass.Name = 'AccountCreatedDateMergeQueueable'
                AND Status IN ('Queued', 'In Progress')
            LIMIT 1
        ];
        if (!jobs.isEmpty()) {
            System.abortJob(jobs[0].Id);
        }
    }

    public AccountCreatedDateMergeQueueable(Integer limiter) {
        this.limiter = limiter;
    }

    public AccountCreatedDateMergeQueueable() {
        this.limiter = 1;
    }

    public void execute(QueueableContext ctx) {
        List<String> guids = getGuids();
        if (guids.isEmpty()) {
            return;
        }

        Boolean mergeSuccess = true;

        List<Account> accounts;
        for (String guid : guids) {
            accounts = Database.query(
                MergeProcessor.getSelectStarQuery(Account.getSObjectType()) +
                ' WHERE GUID__c = :guid ORDER BY Id DESC'
            );

            Account primary = accounts[0];
            Account secondary = accounts[1];
            copySecondariesValues(primary, secondary);
            try {
                mergeSuccess = MergeProcessor.processMerge(
                    primary,
                    new List<Account>{ secondary }
                );
            } catch (Exception e) {
                ExceptionHandler.process(e, 'AccountCreatedDateMergeQueueable');
                break;
            }
        }

        if (!mergeSuccess) {
            List<Account> pendingMergeReviews = new List<Account>();
            for (Account account : accounts) {
                pendingMergeReviews.add(
                    new Account(Id = account.Id, Pending_Merge_Review__c = true)
                );
            }
            update pendingMergeReviews;
        }

        if (!Test.isRunningTest()) {
            System.enqueueJob(new AccountCreatedDateMergeQueueable(limiter));
        }
    }

    private void processSingle() {
        String guid = getGuids()[0];
        if (guid == null) {
            return;
        }

        List<Account> accounts = Database.query(
            MergeProcessor.getSelectStarQuery(Account.getSObjectType()) +
            ' WHERE GUID__c = :guid ORDER BY Id DESC'
        );

        Account primary = accounts[0];
        Account secondary = accounts[1];
        copySecondariesValues(primary, secondary);
        try {
            MergeProcessor.processMerge(
                primary,
                new List<Account>{ secondary }
            );
            if (!Test.isRunningTest()) {
                System.enqueueJob(
                    new AccountCreatedDateMergeQueueable(limiter)
                );
            }
        } catch (Exception e) {
            ExceptionHandler.process(e, 'AccountCreatedDateMergeQueueable');
        }
    }

    void copySecondariesValues(Account primary, Account secondary) {
        List<String> fields = MergeProcessor.getQueryFields(
            Account.getSObjectType()
        );
        for (String field : fields) {
            if (primary.get(field) == null) {
                if (secondary.get(field) != null) {
                    primary.put(field, secondary.get(field));
                }
            }
        }
    }

    private List<String> getGuids() {
        List<AggregateResult> results = [
            SELECT GUID__c
            FROM Account
            WHERE Pending_Merge_Review__c = FALSE
            GROUP BY GUID__c
            HAVING COUNT(Id) > 1
            LIMIT :limiter
        ];

        if (results.isEmpty()) {
            return null;
        }

        List<String> guids = new List<String>();
        for (AggregateResult result : results) {
            guids.add((String) result.get('GUID__c'));
        }

        return guids;
    }
}