public with sharing class AccountDisqualifier {
    public static Boolean isReasonQualified(Opportunity opp) {
        List<String> qualifiedReasons = new List<String>{
            'Not a business',
            'Out of business',
            'Never a fit',
            'Competitor',
            'Vendor',
            'Partner'
        };

        return qualifiedReasons.contains(opp.Qualified_Out_Reason__c);
    }

    public static void process(Map<Id, String> accountIdDisqualifications) {
        if (System.isFuture() || System.isBatch()) {
            List<Account> accounts = new List<Account>();
            for (Id accountId : accountIdDisqualifications.keySet()) {
                Account account = new Account(
                    Id = accountId,
                    Keep_Disqualified__c = true
                );

                String disqualification = accountIdDisqualifications.get(
                    accountId
                );
                switch on disqualification {
                    when 'Competitor' {
                        account.RecordTypeId = RecordTypeUtility.getId(
                            Account.getSObjectType(),
                            'Competitor'
                        );
                    }
                    when 'Vendor' {
                        account.RecordTypeId = RecordTypeUtility.getId(
                            Account.getSObjectType(),
                            'Vendor'
                        );
                    }
                    when 'Partner' {
                        account.RecordTypeId = RecordTypeUtility.getId(
                            Account.getSObjectType(),
                            'Partner'
                        );
                    }
                }
                accounts.add(account);
            }

            try {
                update accounts;
            } catch (Exception e) {
                ExceptionHandler.process(e, 'AccountDisqualifier');
            }
            return;
        }

        processAsync(accountIdDisqualifications);
    }

    @future
    public static void processAsync(
        Map<Id, String> accountIdDisqualifications
    ) {
        process(accountIdDisqualifications);
    }
}