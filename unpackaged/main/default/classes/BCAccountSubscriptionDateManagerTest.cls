@isTest(isparallel=true)
public with sharing class BCAccountSubscriptionDateManagerTest {
    @isTest
    static void testSetSubscriptionDates() {
        Brightcove_Account__c bcAccount = new Brightcove_Account__c(
            Email_Address__c = 'mhigel@example.com',
            Tier__c = 'Premium',
            Brightcove_Account_Id__c = '123456'
        );
        insert bcAccount;

        bcAccount = [SELECT Id, Date_of_Subscription_Initial__c, Date_of_Subscription_Latest__c, Date_of_Last_Subscription_Change__c FROM Brightcove_Account__c WHERE Id = :bcAccount.Id];
        System.assertEquals(Date.today(), bcAccount.Date_of_Subscription_Initial__c);
        System.assertEquals(Date.today(), bcAccount.Date_of_Subscription_Latest__c);
        System.assertEquals(Date.today(), bcAccount.Date_of_Last_Subscription_Change__c);

        bcAccount.Date_of_Subscription_Latest__c = null;
        bcAccount.Date_of_Last_Subscription_Change__c = null;
        update bcAccount;

        bcAccount = [SELECT Id, Date_of_Subscription_Latest__c, Date_of_Last_Subscription_Change__c FROM Brightcove_Account__c WHERE Id = :bcAccount.Id];
        System.assertEquals(null, bcAccount.Date_of_Subscription_Latest__c);
        System.assertEquals(null, bcAccount.Date_of_Last_Subscription_Change__c);

        bcAccount.Tier__c = 'Basic';
        update bcAccount;

        bcAccount = [SELECT Id, Date_of_Subscription_Latest__c, Date_of_Last_Subscription_Change__c FROM Brightcove_Account__c WHERE Id = :bcAccount.Id];
        System.assertEquals(Date.today(), bcAccount.Date_of_Subscription_Latest__c);
        System.assertEquals(Date.today(), bcAccount.Date_of_Last_Subscription_Change__c);
    }
}