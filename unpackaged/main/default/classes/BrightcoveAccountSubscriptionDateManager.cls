public with sharing class BrightcoveAccountSubscriptionDateManager extends DomainLogicHandler {
    public override void check(SObject newObj) {
        Brightcove_Account__c newBcAccount = (Brightcove_Account__c)newObj;
        if(isQualified(newBcAccount)) {
            newBcAccount.Date_of_Subscription_Initial__c = Date.today();
            setSubscriptionDates(newBcAccount);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        Brightcove_Account__c newBcAccount = (Brightcove_Account__c)newObj;
        Brightcove_Account__c oldBcAccount = (Brightcove_Account__c)oldObj;
        if(isQualified(newBcAccount, oldBcAccount)) {
            setSubscriptionDates(newBcAccount);
            if(isQualified(newBcAccount)) {
                newBcAccount.Date_of_Subscription_Initial__c = Date.today();
            }
        }
    }

    Boolean isQualified(Brightcove_Account__c newBcAccount) {
        return newBcAccount.Tier__c == 'Premium';
    }

    Boolean isQualified(Brightcove_Account__C newBcAccount, Brightcove_Account__C oldBcAccount) {
        return TriggerUtility.isChanged(newBcAccount, oldBcAccount, Brightcove_Account__c.Tier__c);
    }

    void setSubscriptionDates(Brightcove_Account__c newBcAccount) {
        newBcAccount.Date_of_Subscription_Latest__c = Date.today();
        newBcAccount.Date_of_Last_Subscription_Change__c = Date.today();
    }
}