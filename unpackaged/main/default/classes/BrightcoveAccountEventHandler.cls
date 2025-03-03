/**
 * Test coverage for this class is found in BrightcoveAccountToBCAccountHandlerTest
 */
public with sharing class BrightcoveAccountEventHandler {
    static BCMap existingBCAccounts;
    static List<SObject> bcAccountObjects;

    public static void process(List<Brightcove_Account_Event__e> events) {
        bcAccountObjects = new List<SObject>();
        setExistingBCAccounts(events);

        for (Brightcove_Account_Event__e event : events) {
            if (
                existingBCAccounts.containsKey(event.Brightcove_Account_Id__c)
            ) {
                addUpdatedBCAccount(event);
            } else {
                addNewBCAccount(event);
            }
        }
        try {
            upsert bcAccountObjects;
        } catch (Exception e) {
            ExceptionHandler.process(e, 'BrightcoveAccountEventHandler');
        }
    }

    static void addUpdatedBCAccount(Brightcove_Account_Event__e event) {
        BCAccount__c bcAccount = (BCAccount__c) existingBCAccounts.get(
            event.Brightcove_Account_Id__c
        );
        bcAccount.Account__c = event.Account_Id__c;
        bcAccount.Name = event.Name__c;
        bcAccountObjects.add(bcAccount);
        if (event.Requires_History__c) {
            bcAccountObjects.add(
                new BCAccount_Edition_History__c(
                    BCAccount__c = bcAccount.Id,
                    Changed_Date__c = Date.today()
                )
            );
        }
    }

    static void addNewBCAccount(Brightcove_Account_Event__e event) {
        Id accountId = event.Account_Id__c;
        String guid = GuidUtility.generateGuid();
        bcAccountObjects.add(
            new BCAccount__c(
                Brightcove_Account__c = (Id) event.Brightcove_Account_Id__c,
                Account__c = accountId,
                GUID__c = guid,
                Name = event.Name__c
            )
        );
        if (event.Requires_History__c) {
            bcAccountObjects.add(
                new BCAccount_Edition_History__c(
                    BCAccount__r = new BCAccount__c(GUID__c = guid),
                    Changed_Date__c = Date.today()
                )
            );
        }
    }

    static void setExistingBCAccounts(
        List<Brightcove_Account_Event__e> events
    ) {
        List<String> brightcoveAccountIds = new List<String>();
        for (Brightcove_Account_Event__e event : events) {
            brightcoveAccountIds.add(event.Brightcove_Account_Id__c);
        }

        existingBCAccounts = new BCMap(
            [
                SELECT
                    Id,
                    Name,
                    GUID__c,
                    Account__c,
                    Brightcove_Account__c,
                    Publisher_Status__c
                FROM BCAccount__c
                WHERE Brightcove_Account__c IN :brightcoveAccountIds
            ],
            'Brightcove_Account__c'
        );
    }
}