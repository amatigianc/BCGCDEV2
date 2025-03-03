@isTest(isparallel=true)
public with sharing class BrightcoveAccountToBCAccountHandlerTest {
  @isTest
  static void testProcess() {
    Account account = AccountTestFactory.createCustomer();

    List<Brightcove_Account__c> brightcoveAccounts = new List<Brightcove_Account__c>{
      new Brightcove_Account__c(
        Email_Address__c = 'mhigel@example.com',
        Brightcove_Account_Id__c = '123456',
        Account__c = account.Id
      ),
      new Brightcove_Account__c(
        Email_Address__c = 'mhigel@example.com',
        Brightcove_Account_Id__c = '67890'
      )
    };

    insert brightcoveAccounts;

    Test.getEventBus().deliver();
    Test.startTest();

    List<BCAccount__c> bcAccounts = [
      SELECT Id, Account__c, Brightcove_Account__c
      FROM BCAccount__c
      WHERE Brightcove_Account__c IN :brightcoveAccounts
    ];
    System.assertEquals(
      brightcoveAccounts.size(),
      bcAccounts.size(),
      'No BCAccount record created from Brightcove Account record.'
    );

    Map<Id, Brightcove_Account__c> brightcoveAccountsMap = new Map<Id, Brightcove_Account__c>(
      brightcoveAccounts
    );
    for (BCAccount__c bcAccount : bcAccounts) {
      Brightcove_Account__c brightcoveAccount = brightcoveAccountsMap.get(
        bcAccount.Brightcove_Account__c
      );
      System.assertEquals(
        brightcoveAccount.Account__c,
        bcAccount.Account__c,
        'Account reference incorrectly applied.'
      );
    }

    brightcoveAccounts[0].Publisher_Status__c = 'LOCKED';
    brightcoveAccounts[1].Account__c = account.Id;
    update brightcoveAccounts;

    Test.getEventBus().deliver();
    Test.stopTest();

    bcAccounts = [
      SELECT Id, Account__c, Brightcove_Account__c
      FROM BCAccount__c
      WHERE Brightcove_Account__c IN :brightcoveAccounts
    ];
    System.assertEquals(
      brightcoveAccounts.size(),
      bcAccounts.size(),
      'No BCAccount record created from Brightcove Account record.'
    );

    brightcoveAccountsMap = new Map<Id, Brightcove_Account__c>(
      brightcoveAccounts
    );
    for (BCAccount__c bcAccount : bcAccounts) {
      Brightcove_Account__c brightcoveAccount = brightcoveAccountsMap.get(
        bcAccount.Brightcove_Account__c
      );
      System.assertEquals(
        brightcoveAccount.Account__c,
        bcAccount.Account__c,
        'Account reference incorrectly applied.'
      );
    }

    List<BCAccount_Edition_History__c> histories = [
      SELECT Id, Changed_Date__c
      FROM BCAccount_Edition_History__c
      WHERE BCAccount__r.Brightcove_Account__c = :brightcoveAccounts[0].Id
    ];
    System.assertEquals(
      1,
      histories.size(),
      'BCAccount Edition History record not created when Brightcove Account record was locked.'
    );
    System.assertEquals(
      Date.today(),
      histories[0].Changed_Date__c,
      'Changed Date on BCAccount Edition History record not correctly set.'
    );
  }
}