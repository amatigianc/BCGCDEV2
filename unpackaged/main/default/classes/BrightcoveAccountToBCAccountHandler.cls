public with sharing class BrightcoveAccountToBCAccountHandler extends DomainLogicHandler {
    public List<Brightcove_Account_Event__e> events = new List<Brightcove_Account_Event__e>();
    List<Id> brightcoveAccountIds = new List<Id>();

    public override void check(SObject newObj) {
        events.add(getEvent((Brightcove_Account__c) newObj));
    }

    public override void check(SObject newObj, SObject oldObj) {
        Brightcove_Account__c newBrightcoveAccount = (Brightcove_Account__c) newObj;
        if (isQualified(newBrightcoveAccount, oldObj)) {
            Brightcove_Account_Event__e event = getEvent(newBrightcoveAccount);
            event.Requires_History__c = isNowLocked(
                newBrightcoveAccount,
                oldObj
            );
            events.add(event);
        } else {
            brightcoveAccountIds.add(newBrightcoveAccount.Id);
        }
    }

    public override void processRecords() {
        if (!events.isEmpty()) {
            Eventbus.publish(events);
        }

        /**
         * This is one the dumbest (may actually THE dumbest) thing I've ever had to do.
         * Oracle queries the LastModifiedDate of BCAccount__c records during the Subcription
         * integration, and since BCAccount__c is just a shell-duplication of the actual
         * Brightcove_Account__c records, we have to do a no-change update DML to get the
         * LastModifiedDate of the related BCAccount__c records updated anytime their parent
         * Brightcove_Account__c record is updated.  All of this just because "we" don't want
         * to take 5 minutes to change the name of an object in a query from "BCAccount__c" to
         * "Brightcove_Account__c".  I am now dumber for having done this, regardless of the
         * justification.
         */
        if (!brightcoveAccountIds.isEmpty()) {
            List<BCAccount__c> bcAccounts = [
                SELECT Id
                FROM BCAccount__c
                WHERE Brightcove_Account__c IN :brightcoveAccountIds
            ];
            update bcAccounts;
        }
    }

    Brightcove_Account_Event__e getEvent(
        Brightcove_Account__c newBrightcoveAccount
    ) {
        Brightcove_Account_Event__e event = new Brightcove_Account_Event__e(
            Brightcove_Account_Id__c = newBrightcoveAccount.Id,
            Name__c = newBrightcoveAccount.Name
        );
        if (hasAccount(newBrightcoveAccount)) {
            event.Account_Id__c = newBrightcoveAccount.Account__c;
        }

        return event;
    }

    Boolean hasAccount(Brightcove_Account__c newBrightcoveAccount) {
        return newBrightcoveAccount.Account__c != null;
    }

    Boolean isQualified(
        Brightcove_Account__c newBrightcoveAccount,
        SObject oldObj
    ) {
        return isAccountChanged(newBrightcoveAccount, oldObj) ||
            isNowLocked(newBrightcoveAccount, oldObj);
    }

    Boolean isAccountChanged(
        Brightcove_Account__c newBrightcoveAccount,
        SObject oldObj
    ) {
        List<SObjectField> fields = new List<SObjectField>{
            Brightcove_Account__c.Account__c,
            Brightcove_Account__c.Name
        };
        return TriggerUtility.isChanged(
            newBrightcoveAccount,
            oldObj,
            fields  
        );
    }

    Boolean isNowLocked(
        Brightcove_Account__c newBrightcoveAccount,
        SObject oldObj
    ) {
        return TriggerUtility.isChanged(
                newBrightcoveAccount,
                oldObj,
                Brightcove_Account__c.Publisher_Status__c
            ) && isLocked(newBrightcoveAccount);
    }

    Boolean isLocked(Brightcove_Account__c newBrightcoveAccount) {
        return newBrightcoveAccount.Publisher_Status__c == 'LOCKED';
    }
}