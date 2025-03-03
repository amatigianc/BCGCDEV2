public with sharing class AccountMergerQueueable implements Queueable {
    Boolean needsRequeue = false;
    Boolean hasMultipleCustomerAccounts = false;
    Account primary;
    List<Account> secondaries = new List<Account>();

    public void execute(QueueableContext ctx) {
        String dunsNumber = getDunsNumber();

        if (dunsNumber == null) {
            return;
        }

        processAccounts(dunsNumber);

        Boolean isSuccess = MergeProcessor.processMerge(primary, secondaries);
        if (isSuccess && needsRequeue) {
            System.enqueueJob(new AccountMergerQueueable());
        }
    }

    private void processAccounts(String dunsNumber) {
        String query = MergeProcessor.getSelectStarQuery(
            Account.getSObjectType()
        );
        query += ' WHERE D_U_N_S_Number__c = :dunsNumber AND Pending_Merge_Review__c = FALSE ORDER BY Account_Stage__c DESC LIMIT 3';

        List<Account> accounts = Database.query(query);
        needsRequeue = accounts.size() > 3;

        primary = accounts[0];
        if (accounts[1].Account_Stage__c == 'Customer') {
            setPendingReview(dunsNumber);
            return;
        }

        secondaries.add(accounts[1]);
        if (accounts.size() > 2) {
            secondaries.add(accounts[2]);
        }

        copySecondariesValues();
    }

    private void copySecondariesValues() {
        List<String> fields = MergeProcessor.getQueryFields(
            Account.getSObjectType()
        );
        for (String field : fields) {
            if (primary.get(field) == null) {
                for (Account secondary : secondaries) {
                    if (secondary.get(field) != null) {
                        primary.put(field, secondary.get(field));
                        break;
                    }
                }
            }
        }
    }

    private void setPendingReview(String dunsNumber) {
        List<Account> accounts = [
            SELECT Id, Pending_Merge_Review__c
            FROM Account
            WHERE D_U_N_S_Number__c = :dunsNumber
        ];
        for (Account account : accounts) {
            account.Pending_Merge_Review__c = true;
        }
        update accounts;
    }

    private String getDunsNumber() {
        List<AggregateResult> aggregateResults = [
            SELECT D_U_N_S_Number__c
            FROM Account
            WHERE Pending_Merge_Review__c = FALSE
            GROUP BY D_U_N_S_Number__c
            HAVING COUNT(Id) > 1
        ];

        if (aggregateResults.isEmpty()) {
            return null;
        }

        needsRequeue = aggregateResults.size() > 1;

        return (String) aggregateResults[0].get('D_U_N_S_Number__c');
    }
}